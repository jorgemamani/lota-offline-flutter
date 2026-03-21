import 'package:flutter/material.dart';

import '../../domain/models/lota_card_model.dart';

/// Renderiza un cartón completo de Lota Argentina (3 sub-cartones).
///
/// Cada sub-cartón es una grilla de 3 filas × 9 columnas.
/// Las celdas vacías (valor 0) se muestran con un color de fondo diferente.
///
/// [onCellTap] recibe el número de la celda pulsada. Si es null, el cartón
/// es de sólo lectura (útil para la pantalla de selección).
///
/// [drawnNumbers] resalta los números sorteados por el bolillero que aún
/// no fueron marcados por el jugador.
class LotaCardWidget extends StatelessWidget {
  const LotaCardWidget({
    super.key,
    required this.model,
    this.drawnNumbers = const {},
    this.onCellTap,
    this.compact = false,
  });

  final LotaCardModel model;

  /// Números sorteados por el bolillero (para resaltarlos).
  final Set<int> drawnNumbers;

  /// Callback al tocar una celda no vacía. null → sólo lectura.
  final void Function(int number)? onCellTap;

  /// Modo compacto: celdas más pequeñas, sin callback.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int sub = 0; sub < 3; sub++) ...[
          if (sub > 0)
            Divider(
              height: compact ? 10 : 14,
              thickness: 1.5,
              color: colors.outlineVariant,
            ),
          _SubCartonCard(
            model: model,
            subIndex: sub,
            drawnNumbers: drawnNumbers,
            onCellTap: onCellTap,
            compact: compact,
            colors: colors,
          ),
        ],
      ],
    );
  }
}

/// Renderiza uno de los 3 sub-cartones (filas [sub*3 .. sub*3+2]).
class _SubCartonCard extends StatelessWidget {
  const _SubCartonCard({
    required this.model,
    required this.subIndex,
    required this.drawnNumbers,
    required this.onCellTap,
    required this.compact,
    required this.colors,
  });

  final LotaCardModel model;
  final int subIndex;
  final Set<int> drawnNumbers;
  final void Function(int number)? onCellTap;
  final bool compact;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final startRow = subIndex * 3;

    return Container(
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(compact ? 6 : 10),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colors.onPrimary, width: compact ? 4 : 6),
          borderRadius: BorderRadius.circular(compact ? 4 : 8),
        ),
        child: Table(
          border: TableBorder.all(
            color: colors.primary,
            width: compact ? 1 : 1.5,
          ),
          children: [
            for (int row = startRow; row < startRow + 3; row++)
              TableRow(
                children: [
                  for (int col = 0; col < 9; col++)
                    TableCell(
                      child: _Cell(
                        value: model.card[row][col],
                        isMarked: model.isMarked(row, col),
                        isDrawn: model.card[row][col] != 0 &&
                            drawnNumbers.contains(model.card[row][col]),
                        compact: compact,
                        colors: colors,
                        onTap: model.card[row][col] != 0 && onCellTap != null
                            ? () => onCellTap!(model.card[row][col])
                            : null,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.value,
    required this.isMarked,
    required this.isDrawn,
    required this.compact,
    required this.colors,
    this.onTap,
  });

  final int value;
  final bool isMarked;
  final bool isDrawn;
  final bool compact;
  final ColorScheme colors;
  final VoidCallback? onTap;

  bool get isEmpty => value == 0;

  @override
  Widget build(BuildContext context) {
    final cellHeight = compact ? 28.0 : 38.0;
    final fontSize = compact ? 9.0 : 13.0;

    final Color bg;
    final Color fg;

    if (isEmpty) {
      bg = colors.primaryContainer.withOpacity(0.35);
      fg = Colors.transparent;
    } else if (isMarked) {
      bg = colors.primary;
      fg = colors.onPrimary;
    } else if (isDrawn) {
      bg = colors.primaryContainer;
      fg = colors.onPrimaryContainer;
    } else {
      bg = Colors.white;
      fg = colors.onSurface;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: cellHeight,
        color: bg,
        child: Center(
          child: isEmpty
              ? null
              : Text(
                  '$value',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight:
                        isMarked ? FontWeight.bold : FontWeight.w500,
                    color: fg,
                    height: 1,
                  ),
                ),
        ),
      ),
    );
  }
}
