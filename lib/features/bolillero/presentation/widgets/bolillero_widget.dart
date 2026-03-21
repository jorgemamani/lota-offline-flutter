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
        final canDraw = state is GameInProgress && state.availableNumbers.isNotEmpty;

        return Column(
          children: [
            _LastNumberDisplay(number: last),
            const SizedBox(height: 16),
            _DrawButton(canDraw: canDraw),
            const SizedBox(height: 16),
            _DrawnGrid(drawn: drawn),
          ],
        );
      },
    );
  }
}

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
            color: colors.primary.withOpacity(0.25),
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
            : Icon(Icons.casino_rounded, size: 48, color: colors.onPrimaryContainer),
      ),
    );
  }
}

class _DrawButton extends StatelessWidget {
  const _DrawButton({required this.canDraw});

  final bool canDraw;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: canDraw
          ? () => context.read<GameBloc>().add(const RandomNumberDrawn())
          : null,
      icon: const Icon(Icons.shuffle_rounded),
      label: const Text('Sacar número'),
    );
  }
}

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
