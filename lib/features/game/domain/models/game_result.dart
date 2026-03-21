import 'package:equatable/equatable.dart';

/// Tipo de premio obtenido en la partida.
enum PrizeType {
  /// Primera fila completa marcada.
  linea,

  /// Cartón completo (los 15 números marcados).
  lota,
}

/// Resultado obtenido por un cartón durante la partida.
class GameResult extends Equatable {
  const GameResult({
    required this.cartonId,
    required this.prize,
    required this.roundNumber,
  });

  final String cartonId;
  final PrizeType prize;

  /// Número de la ronda (cantidad de bolillas sacadas) en que se logró.
  final int roundNumber;

  @override
  List<Object?> get props => [cartonId, prize, roundNumber];
}
