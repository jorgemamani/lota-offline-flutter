import 'package:flutter/material.dart';

import '../../../../shared/constants/lota_card_colors.dart';
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
    this.accentColor,
    this.displayScale = 1.0,
  });

  final LotaCardModel model;

  /// Números sorteados por el bolillero (para resaltarlos).
  final Set<int> drawnNumbers;

  /// Callback al tocar una celda no vacía. null → sólo lectura.
  final void Function(int number)? onCellTap;

  /// Modo compacto: celdas más pequeñas, sin callback.
  final bool compact;

  /// Color de acento del cartón. Si es null usa el primary del tema.
  final LotaCardColor? accentColor;

  /// Escala visual (celdas y números). Usar [CartonDisplayScale.multiplierForStep].
  final double displayScale;

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).colorScheme;
    final cardColor = accentColor ??
        LotaCardColor(
          primary: themeColors.primary,
          onPrimary: themeColors.onPrimary,
        );
    final s = displayScale.clamp(0.85, 2.0);
    // Marcos y separadores crecen menos que las celdas para pantallas angostas.
    final frameS = s.clamp(1.0, 1.2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int sub = 0; sub < 3; sub++) ...[
          if (sub > 0)
            Divider(
              height: (compact ? 10 : 14) * frameS,
              thickness: 1.5,
              color: themeColors.outlineVariant,
            ),
          _SubCartonCard(
            model: model,
            subIndex: sub,
            drawnNumbers: drawnNumbers,
            onCellTap: onCellTap,
            compact: compact,
            themeColors: themeColors,
            cardColor: cardColor,
            displayScale: s,
            frameScale: frameS,
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
    required this.themeColors,
    required this.cardColor,
    required this.displayScale,
    required this.frameScale,
  });

  final LotaCardModel model;
  final int subIndex;
  final Set<int> drawnNumbers;
  final void Function(int number)? onCellTap;
  final bool compact;
  final ColorScheme themeColors;
  final LotaCardColor cardColor;
  final double displayScale;
  final double frameScale;

  @override
  Widget build(BuildContext context) {
    final startRow = subIndex * 3;
    final fs = frameScale;

    return Container(
      decoration: BoxDecoration(
        color: cardColor.primary,
        borderRadius: BorderRadius.circular((compact ? 6 : 10) * fs),
      ),
      padding: EdgeInsets.all(2 * fs),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: cardColor.onPrimary,
            width: (compact ? 4.0 : 6.0) * fs,
          ),
          borderRadius: BorderRadius.circular((compact ? 4 : 8) * fs),
        ),
        child: Table(
          border: TableBorder.all(
            color: cardColor.primary,
            width: (compact ? 1.0 : 1.5) * fs,
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
                        themeColors: themeColors,
                        cardColor: cardColor,
                        displayScale: displayScale,
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
    required this.themeColors,
    required this.cardColor,
    required this.displayScale,
    this.onTap,
  });

  final int value;
  final bool isMarked;
  final bool isDrawn;
  final bool compact;
  final ColorScheme themeColors;
  final LotaCardColor cardColor;
  final double displayScale;
  final VoidCallback? onTap;

  bool get isEmpty => value == 0;

  @override
  Widget build(BuildContext context) {
    final s = displayScale;
    final cellHeight = (compact ? 28.0 : 38.0) * s;
    final fontSize = (compact ? 12.0 : 18.0) * s;

    final Color bg;
    final Color fg;

    if (isEmpty) {
      bg = cardColor.primary.withValues(alpha: 0.70);
      fg = Colors.transparent;
    } else if (isMarked) {
      bg = cardColor.primary;
      fg = cardColor.onPrimary;
    } else if (isDrawn) {
      bg = cardColor.primary.withValues(alpha: 0.35);
      fg = Colors.black87;
    } else {
      bg = Colors.white;
      fg = Colors.black87;
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
                    fontWeight: isMarked ? FontWeight.w900 : FontWeight.w600,
                    color: fg,
                    height: 1,
                  ),
                ),
        ),
      ),
    );
  }
}
