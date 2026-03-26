import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/constants/app_assets.dart';
import '../../../../shared/widgets/image_component.dart';
import '../../../game/presentation/bloc/game_bloc.dart';

/// Widget reutilizable que muestra el bolillero.
///
/// Se usa en [BolilleroPage] (standalone) y en el sheet de [GamePlayPage]
/// (modo combined). En combined, [showReiniciarSorteo] va en `false`.
///
/// [extraActionButtons]: acciones extra entre «Reiniciar sorteo» y «Sacar número»
/// (mismo ancho, lista vertical) para futuras funciones.
///
/// «Reiniciar sorteo» solo se muestra si [showReiniciarSorteo] y ya hay al menos
/// un número sorteado (no tiene sentido reiniciar con el bolillero vacío).
class BolilleroWidget extends StatelessWidget {
  const BolilleroWidget({
    super.key,
    this.showReiniciarSorteo = true,
    this.onReiniciarPressed,
    this.extraActionButtons = const [],
  });

  /// Si es `false` (p. ej. juego combinado), no se muestra «Reiniciar sorteo».
  final bool showReiniciarSorteo;

  /// Debe abrir el sheet de confirmación y ejecutar el reinicio al confirmar.
  /// Ignorado si [showReiniciarSorteo] es `false`.
  final VoidCallback? onReiniciarPressed;

  /// Acciones extra en la columna derecha, entre reiniciar y «Sacar número».
  final List<Widget> extraActionButtons;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        if (state is! GameInProgress && state is! GameOver) {
          return const SizedBox.shrink();
        }

        final drawn = state is GameInProgress
            ? state.drawnNumbers
            : (state as GameOver).drawnNumbers;
        final last = switch (state) {
          GameInProgress() => state.lastDrawnNumber,
          GameOver() =>
            state.drawnNumbers.isEmpty ? null : state.drawnNumbers.last,
          _ => null,
        };
        final canDraw = state is GameInProgress &&
            state.availableNumbers.isNotEmpty &&
            !state.drawingBlocked;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawnHistory(drawn: drawn),
            const SizedBox(height: 16),
            _BolilleroMainRow(
              lastNumber: last,
              canDraw: canDraw,
              showReiniciarSorteo: showReiniciarSorteo,
              onReiniciarPressed: onReiniciarPressed,
              hasDrawnNumbers: drawn.isNotEmpty,
              extraActionButtons: extraActionButtons,
            ),
            const SizedBox(height: 20),
            _DrawnGrid(drawn: drawn),
          ],
        );
      },
    );
  }
}

/// Fila superior: mitad izquierda número grande, mitad derecha acciones verticales.
class _BolilleroMainRow extends StatelessWidget {
  const _BolilleroMainRow({
    required this.lastNumber,
    required this.canDraw,
    required this.showReiniciarSorteo,
    required this.onReiniciarPressed,
    required this.hasDrawnNumbers,
    required this.extraActionButtons,
  });

  final int? lastNumber;
  final bool canDraw;
  final bool showReiniciarSorteo;
  final VoidCallback? onReiniciarPressed;
  final bool hasDrawnNumbers;
  final List<Widget> extraActionButtons;

  /// Altura finita obligatoria: dentro de [SingleChildScrollView] el padre da
  /// `maxHeight: infinity` y un [Row] con [CrossAxisAlignment.stretch] rompe el layout.
  static double _rowHeight({
    required bool showReiniciar,
    required int extraCount,
  }) {
    const circle = 120.0;
    const btn = 52.0;
    const gap = 10.0;
    // Columna derecha, todo junto: [reiniciar?] + [extras…] + sacar (sin Spacer).
    var stack = btn;
    if (showReiniciar) stack += gap + btn;
    stack += extraCount * (gap + btn);
    return math.max(circle, stack) + 12;
  }

  @override
  Widget build(BuildContext context) {
    final showReiniciar =
        showReiniciarSorteo && onReiniciarPressed != null && hasDrawnNumbers;
    final h = _rowHeight(
      showReiniciar: showReiniciar,
      extraCount: extraActionButtons.length,
    );

    return SizedBox(
      height: h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: _LastNumberDisplay(number: lastNumber),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _ActionsColumn(
                canDraw: canDraw,
                showReiniciar: showReiniciar,
                onReiniciarPressed: onReiniciarPressed,
                extraActionButtons: extraActionButtons,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Orden: reiniciar arriba, [extraActionButtons] en el medio, «Sacar número» abajo.
/// Todo el bloque va junto (mismo espaciado fijo) y centrado en la mitad derecha.
class _ActionsColumn extends StatelessWidget {
  const _ActionsColumn({
    required this.canDraw,
    required this.showReiniciar,
    required this.onReiniciarPressed,
    required this.extraActionButtons,
  });

  final bool canDraw;
  final bool showReiniciar;
  final VoidCallback? onReiniciarPressed;
  final List<Widget> extraActionButtons;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (showReiniciar && onReiniciarPressed != null) {
      children.add(
        OutlinedButton.icon(
          onPressed: onReiniciarPressed,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reiniciar sorteo'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),
      );
    }

    for (final extra in extraActionButtons) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 10));
      }
      children.add(extra);
    }

    if (children.isNotEmpty) {
      children.add(const SizedBox(height: 10));
    }
    children.add(
      FilledButton.icon(
        onPressed: canDraw
            ? () => context.read<GameBloc>().add(const RandomNumberDrawn())
            : null,
        icon: const Icon(Icons.shuffle_rounded),
        label: const Text('Sacar número'),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
        ),
      ),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

// ── Historial horizontal ───────────────────────────────────────────────────────

class _DrawnHistory extends StatefulWidget {
  const _DrawnHistory({required this.drawn});

  final List<int> drawn;

  @override
  State<_DrawnHistory> createState() => _DrawnHistoryState();
}

class _DrawnHistoryState extends State<_DrawnHistory> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(_DrawnHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.drawn.length != oldWidget.drawn.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (widget.drawn.isEmpty) {
      return SizedBox(
        height: 78,
        child: Center(
          child: Text(
            'Todavía no salió ningún número',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    final reversed = widget.drawn.reversed.toList();

    return SizedBox(
      height: 78,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: reversed.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final number = reversed[index];
          final round = widget.drawn.length - index;
          final isLatest = index == 0;

          return _HistoryItem(
            number: number,
            round: round,
            isLatest: isLatest,
            colors: colors,
          );
        },
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.number,
    required this.round,
    required this.isLatest,
    required this.colors,
  });

  final int number;
  final int round;
  final bool isLatest;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'R$round',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: isLatest ? colors.primary : colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isLatest ? 46 : 36,
          height: isLatest ? 46 : 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLatest ? colors.primary : colors.surfaceContainerHighest,
            boxShadow: isLatest
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: isLatest ? 17 : 14,
                fontWeight: FontWeight.w900,
                color: isLatest ? colors.onPrimary : colors.onSurfaceVariant,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Número actual ──────────────────────────────────────────────────────────────

class _LastNumberDisplay extends StatelessWidget {
  const _LastNumberDisplay({required this.number});

  final int? number;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: number != null
            ? Text(
                '$number',
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w900,
                  color: colors.onPrimaryContainer,
                  height: 1,
                ),
              )
            : ImageComponent(
                imagePath: AppAssets.gameModeBolillero,
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                color: colors.onPrimaryContainer,
              ),
      ),
    );
  }
}

// ── Cuadrícula 90 números ──────────────────────────────────────────────────────

/// Cuadrícula 10×9 que muestra los 90 números posibles.
/// Los sorteados se resaltan.
class _DrawnGrid extends StatelessWidget {
  const _DrawnGrid({required this.drawn});

  final List<int> drawn;

  @override
  Widget build(BuildContext context) {
    final drawnSet = drawn.toSet();
    final colors = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: 90,
      itemBuilder: (context, index) {
        final number = index + 1;
        final isDrawn = drawnSet.contains(number);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isDrawn ? colors.primary : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isDrawn ? FontWeight.w900 : FontWeight.w700,
                color: isDrawn ? colors.onPrimary : colors.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}
