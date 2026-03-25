part of 'game_bloc.dart';

sealed class GameState {
  const GameState();
}

/// Estado inicial: sin partida activa.
final class GameIdle extends GameState {
  const GameIdle();
}

/// Partida en curso.
///
/// El estado de marcado de cada cartón está embebido en los propios
/// [LotaCardModel] dentro de [cartones]. No hay mapa separado de marcados.
final class GameInProgress extends GameState {
  const GameInProgress({
    required this.mode,
    required this.cartones,
    required this.drawnNumbers,
    required this.availableNumbers,
    this.lastDrawnNumber,
    this.results = const [],
    this.newlyAchievedPrizes = const [],
    this.drawingBlocked = false,
  });

  final GameMode mode;

  /// Cartones en juego (con su estado de marcado embebido).
  final List<LotaCardModel> cartones;

  /// Números salidos del bolillero en orden cronológico.
  final List<int> drawnNumbers;

  /// Números todavía no sorteados.
  final List<int> availableNumbers;

  /// Último número salido.
  final int? lastDrawnNumber;

  /// Premios acumulados durante toda la partida.
  final List<GameResult> results;

  /// Premios recién detectados en el último marcado.
  ///
  /// Se resetea a [] en cada evento que no sea [NumberToggled].
  /// El [BlocListener] en la UI lo usa para mostrar SnackBars.
  final List<GameResult> newlyAchievedPrizes;

  /// true mientras el botón "Sacar número" está bloqueado por un premio.
  ///
  /// Solo aplica en [GameMode.combined]. Se activa al detectar un premio y
  /// se desactiva automáticamente al desaparecer la notificación superior.
  final bool drawingBlocked;

  /// Ronda actual = cantidad de bolillas sacadas.
  int get round => drawnNumbers.length;

  /// true si se agotaron todos los números disponibles.
  bool get isFinished => availableNumbers.isEmpty;

  /// Números sorteados como conjunto (para resaltado en el widget).
  Set<int> get drawnSet => drawnNumbers.toSet();

  GameInProgress copyWith({
    List<LotaCardModel>? cartones,
    List<int>? drawnNumbers,
    List<int>? availableNumbers,
    int? lastDrawnNumber,
    List<GameResult>? results,
    List<GameResult>? newlyAchievedPrizes,
    bool? drawingBlocked,
  }) =>
      GameInProgress(
        mode: mode,
        cartones: cartones ?? this.cartones,
        drawnNumbers: drawnNumbers ?? this.drawnNumbers,
        availableNumbers: availableNumbers ?? this.availableNumbers,
        lastDrawnNumber: lastDrawnNumber ?? this.lastDrawnNumber,
        results: results ?? this.results,
        // Se resetea a [] si no se pasa explícitamente.
        newlyAchievedPrizes: newlyAchievedPrizes ?? const [],
        drawingBlocked: drawingBlocked ?? this.drawingBlocked,
      );
}

/// Partida terminada (se cantó Lota o se agotaron los números).
final class GameOver extends GameState {
  const GameOver({
    required this.mode,
    required this.cartones,
    required this.drawnNumbers,
    required this.results,
  });

  final GameMode mode;
  final List<LotaCardModel> cartones;
  final List<int> drawnNumbers;
  final List<GameResult> results;

  int get totalRounds => drawnNumbers.length;
}
