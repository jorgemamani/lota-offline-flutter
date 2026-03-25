import '../../../../shared/constants/lota_card_colors.dart';
import 'game_mode.dart';
import 'lota_card_model.dart';

/// Datos de una sesión de juego en curso guardada localmente.
///
/// Se persiste en SharedPreferences cuando el usuario marca un número
/// o el bolillero sortea uno, para que pueda retomar la partida si
/// la app se cierra inesperadamente.
class SessionData {
  const SessionData({
    required this.mode,
    required this.cartones,
    required this.drawnNumbers,
    required this.savedAt,
  });

  final GameMode mode;

  /// Cartones con su estado de marcado y color.
  final List<SessionCarton> cartones;

  /// Números sorteados por el bolillero en orden cronológico.
  final List<int> drawnNumbers;

  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'cartones': cartones.map((c) => c.toJson()).toList(),
        'drawnNumbers': drawnNumbers,
        'savedAt': savedAt.millisecondsSinceEpoch,
      };

  factory SessionData.fromJson(Map<String, dynamic> json) => SessionData(
        mode: GameMode.values.firstWhere((m) => m.name == json['mode']),
        cartones: (json['cartones'] as List)
            .map((c) => SessionCarton.fromJson(c as Map<String, dynamic>))
            .toList(),
        drawnNumbers:
            (json['drawnNumbers'] as List).map((v) => v as int).toList(),
        savedAt:
            DateTime.fromMillisecondsSinceEpoch(json['savedAt'] as int),
      );
}

/// Datos de un cartón individual dentro de una [SessionData].
class SessionCarton {
  const SessionCarton({
    required this.grid,
    required this.cardState,
    required this.colorIndex,
  });

  /// Grilla 9×9 de números (0 = celda vacía).
  final List<List<int>> grid;

  /// Estado de marcado 9×9 (true = marcado).
  final List<List<bool>> cardState;

  /// Índice en [LotaCardColors.all] para restaurar el color visual.
  final int colorIndex;

  /// Convierte a [LotaCardModel] con el estado de marcado preservado.
  ///
  /// Usa el hash del contenido como ID estable (igual que [FavoriteCarton]).
  LotaCardModel toLotaCardModel() => LotaCardModel(
        id: _contentId,
        card: grid,
        cardState: cardState,
      );

  /// Color de acento asociado a este cartón.
  LotaCardColor get color {
    const all = LotaCardColors.all;
    return all[colorIndex.clamp(0, all.length - 1)];
  }

  String get _contentId => grid.map((row) => row.join(',')).join('|');

  Map<String, dynamic> toJson() => {
        'grid': grid,
        'cardState': cardState,
        'colorIndex': colorIndex,
      };

  factory SessionCarton.fromJson(Map<String, dynamic> json) => SessionCarton(
        grid: (json['grid'] as List)
            .map((row) => (row as List).map((v) => v as int).toList())
            .toList(),
        cardState: (json['cardState'] as List)
            .map((row) => (row as List).map((v) => v as bool).toList())
            .toList(),
        colorIndex: json['colorIndex'] as int,
      );
}
