import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/game_mode.dart';
import '../../domain/models/game_result.dart';
import '../../domain/models/lota_card_model.dart';
import '../../domain/services/carton_prize_detector.dart';

part 'game_event.dart';
part 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc() : super(const GameIdle()) {
    on<GameStarted>(_onStarted);
    on<RandomNumberDrawn>(_onRandomNumberDrawn);
    on<ManualNumberDrawn>(_onManualNumberDrawn);
    on<NumberToggled>(_onNumberToggled);
    on<LinePrizeClaimed>(_onLinePrizeClaimed);
    on<LotaPrizeClaimed>(_onLotaPrizeClaimed);
    on<DrawUnblocked>(_onDrawUnblocked);
    on<GameReset>(_onReset);
  }

  final _random = Random();

  // ── Handlers ───────────────────────────────────────────────────────

  void _onStarted(GameStarted event, Emitter<GameState> emit) {
    final available = List<int>.generate(90, (i) => i + 1)..shuffle(_random);

    dev.log('GameBloc: partida iniciada — modo: ${event.mode.name}, '
        'cartones: ${event.cartones.length}');

    emit(GameInProgress(
      mode: event.mode,
      cartones: event.cartones,
      drawnNumbers: const [],
      availableNumbers: available,
    ));
  }

  void _onRandomNumberDrawn(
    RandomNumberDrawn event,
    Emitter<GameState> emit,
  ) {
    final s = _requireInProgress();
    if (s == null || s.availableNumbers.isEmpty) return;

    final number = s.availableNumbers.first;
    final remaining = s.availableNumbers.sublist(1);
    final drawn = [...s.drawnNumbers, number];

    dev.log('GameBloc: número sorteado → $number (ronda ${drawn.length})');

    _emitDrawn(s, emit, number: number, drawn: drawn, remaining: remaining);
    _checkAutoFinish(emit);
  }

  void _onManualNumberDrawn(
    ManualNumberDrawn event,
    Emitter<GameState> emit,
  ) {
    final s = _requireInProgress();
    if (s == null) return;

    if (!s.availableNumbers.contains(event.number)) {
      dev.log('GameBloc: número ${event.number} ya fue sorteado o inválido');
      return;
    }

    final remaining = [...s.availableNumbers]..remove(event.number);
    final drawn = [...s.drawnNumbers, event.number];

    dev.log('GameBloc: número manual → ${event.number}');

    _emitDrawn(s, emit,
        number: event.number, drawn: drawn, remaining: remaining);
    _checkAutoFinish(emit);
  }

  /// Emite el estado tras sacar [number] del bolillero.
  ///
  /// En modo [GameMode.combined] también auto-marca el número en todos los
  /// cartones y corre la detección de premios.
  void _emitDrawn(
    GameInProgress s,
    Emitter<GameState> emit, {
    required int number,
    required List<int> drawn,
    required List<int> remaining,
  }) {
    if (s.mode != GameMode.combined) {
      emit(s.copyWith(
        drawnNumbers: drawn,
        availableNumbers: remaining,
        lastDrawnNumber: number,
      ));
      return;
    }

    final marked = _autoMarkAndDetect(s, number, newRound: drawn.length);
    final hasPrize = marked.toNotify.isNotEmpty;

    emit(s.copyWith(
      drawnNumbers: drawn,
      availableNumbers: remaining,
      lastDrawnNumber: number,
      cartones: marked.cartones,
      results: [...s.results, ...marked.newResults],
      newlyAchievedPrizes: marked.toNotify,
      drawingBlocked: hasPrize,
    ));

    // Desbloquea el botón una vez que el SnackBar superior desaparece.
    // Duración: 4 s de visualización + ~560 ms de animaciones entrada/salida.
    if (hasPrize) {
      Future.delayed(const Duration(milliseconds: 4600), () {
        add(const DrawUnblocked());
      });
    }
  }

  void _onNumberToggled(
    NumberToggled event,
    Emitter<GameState> emit,
  ) {
    final s = _requireInProgress();
    if (s == null) return;

    // En modo combinado el bolillero marca automáticamente.
    // El toque manual se ignora para evitar inconsistencias.
    if (s.mode == GameMode.combined) return;

    LotaCardModel? cartonBefore;
    LotaCardModel? cartonAfter;

    final newCartones = s.cartones.map((c) {
      if (c.id != event.cartonId) return c;
      final pos = c.positionOf(event.number);
      if (pos == null) return c;
      cartonBefore = c;
      final toggled = c.copyWithToggled(pos.$1, pos.$2);
      cartonAfter = toggled;
      return toggled;
    }).toList();

    if (cartonBefore == null || cartonAfter == null) {
      emit(s.copyWith(cartones: newCartones));
      return;
    }

    // Premios GANADOS en este toque (antes → después).
    // Si el usuario desmarcó y vuelve a marcar, gained vuelve a incluir el premio.
    final gained = CartonPrizeDetector.detectAll(cartonAfter!)
        .difference(CartonPrizeDetector.detectAll(cartonBefore!));

    if (gained.isEmpty) {
      emit(s.copyWith(cartones: newCartones));
      return;
    }

    // Premios que actualmente tienen los OTROS cartones (estado real, no historial).
    // Garantiza un único SnackBar por tipo aunque haya varios cartones.
    final otherCurrentPrizes = s.cartones
        .where((c) => c.id != event.cartonId)
        .expand((c) => CartonPrizeDetector.detectAll(c))
        .toSet();

    final toNotify = gained
        .where((prize) => !otherCurrentPrizes.contains(prize))
        .map((prize) => GameResult(
              cartonId: event.cartonId,
              prize: prize,
              roundNumber: s.round,
            ))
        .toList();

    // Historial: solo agrega si no estaba ya registrado (evita duplicados en results).
    final alreadyInHistory = s.results
        .where((r) => r.cartonId == event.cartonId)
        .map((r) => r.prize)
        .toSet();
    final newHistorical = gained
        .difference(alreadyInHistory)
        .map((prize) => GameResult(
              cartonId: event.cartonId,
              prize: prize,
              roundNumber: s.round,
            ))
        .toList();

    dev.log(
      'GameBloc: premios ganados en cartón ${event.cartonId} → '
      '${gained.map((p) => p.name).join(', ')}',
    );

    emit(s.copyWith(
      cartones: newCartones,
      results: [...s.results, ...newHistorical],
      newlyAchievedPrizes: toNotify,
    ));
  }

  void _onLinePrizeClaimed(
    LinePrizeClaimed event,
    Emitter<GameState> emit,
  ) {
    final s = _requireInProgress();
    if (s == null) return;

    if (!_hasLinea(s, event.cartonId)) {
      dev.log('GameBloc: línea rechazada para cartón ${event.cartonId}');
      return;
    }

    final alreadyClaimed = s.results.any(
      (r) => r.cartonId == event.cartonId && r.prize == PrizeType.linea,
    );
    if (alreadyClaimed) return;

    final result = GameResult(
      cartonId: event.cartonId,
      prize: PrizeType.linea,
      roundNumber: s.round,
    );

    dev.log('GameBloc: ¡LÍNEA! cartón ${event.cartonId} en ronda ${s.round}');
    emit(s.copyWith(results: [...s.results, result]));
  }

  void _onLotaPrizeClaimed(
    LotaPrizeClaimed event,
    Emitter<GameState> emit,
  ) {
    final s = _requireInProgress();
    if (s == null) return;

    if (!_hasLota(s, event.cartonId)) {
      dev.log('GameBloc: lota rechazada para cartón ${event.cartonId}');
      return;
    }

    final result = GameResult(
      cartonId: event.cartonId,
      prize: PrizeType.lota,
      roundNumber: s.round,
    );

    dev.log('GameBloc: ¡LOTA! cartón ${event.cartonId} en ronda ${s.round}');

    emit(GameOver(
      mode: s.mode,
      cartones: s.cartones,
      drawnNumbers: s.drawnNumbers,
      results: [...s.results, result],
    ));
  }

  void _onDrawUnblocked(DrawUnblocked event, Emitter<GameState> emit) {
    final s = _requireInProgress();
    if (s == null || !s.drawingBlocked) return;
    emit(s.copyWith(drawingBlocked: false));
  }

  void _onReset(GameReset event, Emitter<GameState> emit) {
    dev.log('GameBloc: partida reiniciada');
    emit(const GameIdle());
  }

  // ── Helpers privados ───────────────────────────────────────────────

  GameInProgress? _requireInProgress() {
    final s = state;
    if (s is GameInProgress) return s;
    dev.log('GameBloc: evento ignorado — estado actual: ${s.runtimeType}');
    return null;
  }

  LotaCardModel? _findCarton(GameInProgress state, String cartonId) =>
      state.cartones.where((c) => c.id == cartonId).firstOrNull;

  bool _hasLinea(GameInProgress state, String cartonId) {
    final carton = _findCarton(state, cartonId);
    return carton != null && CartonPrizeDetector.hasLinea(carton);
  }

  bool _hasLota(GameInProgress state, String cartonId) {
    final carton = _findCarton(state, cartonId);
    return carton != null && CartonPrizeDetector.hasLota(carton);
  }

  /// Marca [number] en todos los cartones y detecta premios nuevos.
  ///
  /// - [newRound]: ronda resultante tras el sorteo (drawn.length).
  /// - Devuelve los cartones actualizados, los [GameResult] a guardar
  ///   en `results` y los que deben mostrarse en SnackBar ([toNotify]).
  ({
    List<LotaCardModel> cartones,
    List<GameResult> newResults,
    List<GameResult> toNotify,
  }) _autoMarkAndDetect(
    GameInProgress s,
    int number, {
    required int newRound,
  }) {
    // Premios que ya tiene ACTUALMENTE cualquier cartón antes de este sorteo.
    // Garantiza SnackBar único por tipo (primer cartón que lo logra).
    final currentGlobalPrizes = s.cartones
        .expand((c) => CartonPrizeDetector.detectAll(c))
        .toSet();

    // Evita notificar el mismo tipo dos veces si dos cartones lo logran
    // en la misma bolilla.
    final notifiedThisDraw = <PrizeType>{};

    final updatedCartones = <LotaCardModel>[];
    final allNewResults = <GameResult>[];
    final toNotify = <GameResult>[];

    for (final carton in s.cartones) {
      final pos = carton.positionOf(number);
      if (pos == null) {
        updatedCartones.add(carton);
        continue;
      }

      final updated = carton.copyWithToggled(pos.$1, pos.$2);
      updatedCartones.add(updated);

      // Premios ganados en este sorteo para este cartón (transición).
      final gained = CartonPrizeDetector.detectAll(updated)
          .difference(CartonPrizeDetector.detectAll(carton));
      if (gained.isEmpty) continue;

      // Historial: solo agrega si no estaba ya registrado.
      final alreadyInHistory = s.results
          .where((r) => r.cartonId == carton.id)
          .map((r) => r.prize)
          .toSet();

      for (final prize in gained) {
        final result =
            GameResult(cartonId: carton.id, prize: prize, roundNumber: newRound);

        if (!alreadyInHistory.contains(prize)) {
          allNewResults.add(result);
        }

        if (!currentGlobalPrizes.contains(prize) &&
            !notifiedThisDraw.contains(prize)) {
          toNotify.add(result);
          notifiedThisDraw.add(prize);
        }
      }

      dev.log(
        'GameBloc: auto-marcado cartón ${carton.id} número $number → '
        'premios: ${gained.map((p) => p.name).join(', ')}',
      );
    }

    return (
      cartones: updatedCartones,
      newResults: allNewResults,
      toNotify: toNotify,
    );
  }

  void _checkAutoFinish(Emitter<GameState> emit) {
    final s = state;
    if (s is GameInProgress && s.availableNumbers.isEmpty) {
      dev.log('GameBloc: se agotaron todos los números — partida terminada');
      emit(GameOver(
        mode: s.mode,
        cartones: s.cartones,
        drawnNumbers: s.drawnNumbers,
        results: s.results,
      ));
    }
  }
}
