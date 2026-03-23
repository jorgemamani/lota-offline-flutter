import 'lota_card_model.dart';

/// Cartón guardado como favorito por el usuario.
///
/// El ID es un hash derivado del contenido de la grilla para que sea
/// estable entre sesiones (a diferencia del id efímero de [LotaCardModel]
/// que se genera con un contador por sesión).
class FavoriteCarton {
  const FavoriteCarton({
    required this.id,
    required this.grid,
    required this.colorIndex,
  });

  /// ID estable: hash del contenido de la grilla. Ver [idFromGrid].
  final String id;

  /// Grilla 9×9 de números (0 = celda vacía).
  final List<List<int>> grid;

  /// Índice en [LotaCardColors.all] que identifica el color del cartón.
  final int colorIndex;

  // ── Identidad basada en contenido ────────────────────────────────────────

  /// Genera un ID estable a partir del contenido de la grilla.
  ///
  /// Permite identificar el mismo cartón entre sesiones independientemente
  /// del id efímero asignado por [CartonManager].
  static String idFromGrid(List<List<int>> grid) =>
      grid.map((row) => row.join(',')).join('|');

  // ── Conversión ───────────────────────────────────────────────────────────

  LotaCardModel toLotaCardModel() => LotaCardModel.fromGrid(
        id: id,
        grid: List.generate(9, (r) => List<int>.from(grid[r])),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'grid': grid,
        'colorIndex': colorIndex,
      };

  factory FavoriteCarton.fromJson(Map<String, dynamic> json) => FavoriteCarton(
        id: json['id'] as String,
        grid: (json['grid'] as List)
            .map((row) => (row as List).map((v) => v as int).toList())
            .toList(),
        colorIndex: json['colorIndex'] as int,
      );
}
