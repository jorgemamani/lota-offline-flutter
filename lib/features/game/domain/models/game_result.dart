import 'package:equatable/equatable.dart';

/// Tipo de premio obtenido en la partida.
///
/// Ordenados de menor a mayor: si se logran varios en un mismo marcado,
/// el SnackBar que queda visible es el de mayor importancia (lota).
enum PrizeType {
  /// Primera fila con al menos 4 números marcados.
  cuaterno,

  /// Primera fila completamente marcada (5 números).
  linea,

  /// Primer sub-cartón con sus 15 números marcados (filas 0-2, 3-5 o 6-8).
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
