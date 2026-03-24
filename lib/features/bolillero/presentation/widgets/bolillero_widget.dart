import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../game/presentation/bloc/game_bloc.dart';

/// Widget reutilizable que muestra el bolillero.
/// Se usa tanto en [BolilleroPage] (standalone) como en el modal
/// dentro de [GamePlayPage] (modo combined).
class BolilleroWidget extends StatelessWidget {
  const BolilleroWidget({super.key});

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
        final last = state is GameInProgress ? state.lastDrawnNumber : null;
        final canDraw =
            state is GameInProgress && state.availableNumbers.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawnHistory(drawn: drawn),
            const SizedBox(height: 20),
            _LastNumberDisplay(number: last),
            const SizedBox(height: 16),
            _DrawButton(canDraw: canDraw),
            const SizedBox(height: 20),
            _DrawnGrid(drawn: drawn),
          ],
        );
      },
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

    // Invertimos para mostrar el más nuevo a la izquierda
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
          // La ronda es widget.drawn.length - index (el más nuevo = drawn.length)
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

    return Center(
      child: Container(
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
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: colors.onPrimaryContainer,
                    height: 1,
                  ),
                )
              : Icon(Icons.casino_rounded,
                  size: 48, color: colors.onPrimaryContainer),
        ),
      ),
    );
  }
}

// ── Botón sortear ──────────────────────────────────────────────────────────────

class _DrawButton extends StatelessWidget {
  const _DrawButton({required this.canDraw});

  final bool canDraw;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: canDraw
            ? () => context.read<GameBloc>().add(const RandomNumberDrawn())
            : null,
        icon: const Icon(Icons.shuffle_rounded),
        label: const Text('Sacar número'),
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
                fontSize: 11,
                fontWeight: isDrawn ? FontWeight.bold : FontWeight.normal,
                color: isDrawn ? colors.onPrimary : colors.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}
