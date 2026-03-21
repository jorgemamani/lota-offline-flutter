import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/game_mode.dart';
import '../../domain/models/game_result.dart';
import '../../domain/models/lota_card_model.dart';

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

    emit(s.copyWith(
      drawnNumbers: drawn,
      availableNumbers: remaining,
      lastDrawnNumber: number,
    ));

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

    emit(s.copyWith(
      drawnNumbers: drawn,
      availableNumbers: remaining,
      lastDrawnNumber: event.number,
    ));

    _checkAutoFinish(emit);
  }

  void _onNumberToggled(
    NumberToggled event,
    Emitter<GameState> emit,
  ) {
    final s = _requireInProgress();
    if (s == null) return;

    final newCartones = s.cartones.map((c) {
      if (c.id != event.cartonId) return c;
      final pos = c.positionOf(event.number);
      if (pos == null) return c;
      return c.copyWithToggled(pos.$1, pos.$2);
    }).toList();

    emit(s.copyWith(cartones: newCartones));
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

  bool _hasLinea(GameInProgress state, String cartonId) {
    final carton = state.cartones.firstWhere(
      (c) => c.id == cartonId,
      orElse: () => throw StateError('Cartón $cartonId no encontrado'),
    );
    return carton.hasAnyLinea;
  }

  bool _hasLota(GameInProgress state, String cartonId) {
    final carton = state.cartones.firstWhere(
      (c) => c.id == cartonId,
      orElse: () => throw StateError('Cartón $cartonId no encontrado'),
    );
    return carton.hasLota;
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
