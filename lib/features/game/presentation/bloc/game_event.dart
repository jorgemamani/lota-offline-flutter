part of 'game_bloc.dart';

sealed class GameEvent {
  const GameEvent();
}

/// Inicia una partida con los cartones seleccionados y el modo de juego.
final class GameStarted extends GameEvent {
  const GameStarted({
    required this.mode,
    required this.cartones,
  });

  final GameMode mode;
  final List<LotaCardModel> cartones;
}

/// Saca un número aleatorio del bolillero (sólo de los disponibles).
final class RandomNumberDrawn extends GameEvent {
  const RandomNumberDrawn();
}

/// Introduce un número manualmente (para modo markOnly con cantador externo).
final class ManualNumberDrawn extends GameEvent {
  const ManualNumberDrawn(this.number);

  final int number;
}

/// El jugador marca o desmarca un número en un cartón específico.
final class NumberToggled extends GameEvent {
  const NumberToggled({
    required this.cartonId,
    required this.number,
  });

  final String cartonId;
  final int number;
}

/// Reclama el premio de línea para un cartón.
final class LinePrizeClaimed extends GameEvent {
  const LinePrizeClaimed(this.cartonId);
  final String cartonId;
}

/// Reclama el premio de lota (cartón completo) para un cartón.
final class LotaPrizeClaimed extends GameEvent {
  const LotaPrizeClaimed(this.cartonId);
  final String cartonId;
}

/// Reinicia la partida completamente (vuelve a [GameIdle]).
final class GameReset extends GameEvent {
  const GameReset();
}
