/// Cartón completo de Lota Argentina (Bingo 90).
///
/// Contiene 3 sub-cartones de 3 filas × 9 columnas cada uno.
/// Internamente se representa como una grilla de 9 × 9.
///
///   Sub-cartón 0 → filas 0-2
///   Sub-cartón 1 → filas 3-5
///   Sub-cartón 2 → filas 6-8
///
/// Celda con valor 0 = celda vacía.
/// Cada fila de sub-cartón tiene exactamente 5 números y 4 celdas vacías.
/// Total de números por cartón completo: 45 (15 por sub-cartón).
///
/// Columna k:
///   k=0 → 1-9   k=1 → 10-19  ...  k=8 → 80-90
class LotaCardModel {
  const LotaCardModel({
    required this.id,
    required this.card,
    required this.cardState,
  });

  /// Identificador único del cartón.
  final String id;

  /// Grilla 9×9: card[fila][columna]. Valor 0 = celda vacía.
  final List<List<int>> card;

  /// Estado de marcado 9×9: cardState[fila][columna]. true = marcado.
  final List<List<bool>> cardState;

  /// Crea un cartón nuevo con la grilla dada y todo sin marcar.
  factory LotaCardModel.fromGrid({
    required String id,
    required List<List<int>> grid,
  }) {
    return LotaCardModel(
      id: id,
      card: grid,
      cardState: List.generate(9, (_) => List.filled(9, false)),
    );
  }

  // ── Mutación inmutable ─────────────────────────────────────────────

  /// Devuelve una copia con la celda [row][col] alternada (marca/desmarca).
  /// Si la celda está vacía (0), retorna el mismo modelo sin cambios.
  LotaCardModel copyWithToggled(int row, int col) {
    if (card[row][col] == 0) return this;
    final newState = List.generate(
      9,
      (r) => List<bool>.from(cardState[r]),
    );
    newState[row][col] = !newState[row][col];
    return LotaCardModel(id: id, card: card, cardState: newState);
  }

  // ── Consultas de celda ─────────────────────────────────────────────

  bool isMarked(int row, int col) => cardState[row][col];

  /// Devuelve la posición (fila, col) de un número, o null si no existe.
  (int, int)? positionOf(int number) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (card[r][c] == number) return (r, c);
      }
    }
    return null;
  }

  // ── Conteos ────────────────────────────────────────────────────────

  /// Todos los números presentes en el cartón completo (los 45).
  List<int> get allNumbers =>
      card.expand((row) => row).where((n) => n != 0).toList();

  /// Conjunto de números marcados.
  Set<int> get markedNumbersSet {
    final result = <int>{};
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (card[r][c] != 0 && cardState[r][c]) result.add(card[r][c]);
      }
    }
    return result;
  }

  int get markedCount => markedNumbersSet.length;
  int get totalNumbers => allNumbers.length;

  // ── Premios ────────────────────────────────────────────────────────

  /// true si alguna fila del cartón completo tiene todos sus números marcados.
  bool get hasAnyLinea {
    for (int r = 0; r < 9; r++) {
      if (_isRowComplete(r)) return true;
    }
    return false;
  }

  /// true si alguna fila del sub-cartón [index] (0, 1 o 2) está completa.
  bool hasLineaInSubCarton(int index) {
    final start = index * 3;
    for (int r = start; r < start + 3; r++) {
      if (_isRowComplete(r)) return true;
    }
    return false;
  }

  /// true si todos los números del sub-cartón [index] están marcados.
  bool hasCartonLleno(int index) {
    final start = index * 3;
    for (int r = start; r < start + 3; r++) {
      for (int c = 0; c < 9; c++) {
        if (card[r][c] != 0 && !cardState[r][c]) return false;
      }
    }
    return true;
  }

  /// true si todos los números del cartón están marcados (cartón lleno).
  bool get hasLota => markedCount == totalNumbers;

  bool _isRowComplete(int row) {
    bool hasNumbers = false;
    for (int c = 0; c < 9; c++) {
      if (card[row][c] != 0) {
        hasNumbers = true;
        if (!cardState[row][c]) return false;
      }
    }
    return hasNumbers;
  }
}
