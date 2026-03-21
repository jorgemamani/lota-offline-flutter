import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/constants/lota_card_colors.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../bolillero/presentation/widgets/bolillero_widget.dart';
import '../../domain/models/game_mode.dart';
import '../../domain/models/game_result.dart';
import '../../domain/models/lota_card_model.dart';
import '../bloc/game_bloc.dart';
import '../widgets/lota_card_widget.dart';

class GamePlayArgs {
  const GamePlayArgs({
    required this.mode,
    required this.cartones,
    this.cardColors = const {},
  });

  final GameMode mode;
  final List<LotaCardModel> cartones;

  /// Color de acento por ID de cartón — preserva los colores de la selección.
  final Map<String, LotaCardColor> cardColors;
}

class GamePlayPage extends StatelessWidget {
  const GamePlayPage({super.key, required this.args});

  final GamePlayArgs args;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) context.read<GameBloc>().add(const GameReset());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(args.mode.label),
          actions: [
            // Botón bolillero en modal (sólo modo combined)
            if (args.mode == GameMode.combined)
              BlocBuilder<GameBloc, GameState>(
                builder: (context, state) {
                  if (state is! GameInProgress) return const SizedBox.shrink();
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.casino_rounded),
                        tooltip: 'Bolillero',
                        onPressed: () => _showBolilleroModal(context),
                      ),
                      if (state.lastDrawnNumber != null)
                        Positioned(
                          top: 8,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${state.lastDrawnNumber}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            // Ronda actual
            BlocBuilder<GameBloc, GameState>(
              builder: (context, state) {
                if (state is! GameInProgress) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Text(
                      'R${state.round}',
                      style:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocListener<GameBloc, GameState>(
          listener: (context, state) {
            if (state is GameOver) _showGameOverDialog(context, state);
          },
          child: BlocBuilder<GameBloc, GameState>(
            builder: (context, state) {
              if (state is GameIdle) {
                return const LoadingIndicator();
              }
              if (state is GameOver) {
                return _GameOverBody(state: state);
              }
              if (state is GameInProgress) {
                return _GameBody(
                  state: state,
                  mode: args.mode,
                  cardColors: args.cardColors,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  void _showBolilleroModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<GameBloc>(),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Bolillero',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                const BolilleroWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, GameOver state) {
    final winners = state.results.where((r) => r.prize == PrizeType.lota);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Text('🎉 ', style: TextStyle(fontSize: 28)),
            Text('¡Partida finalizada!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Números sorteados: ${state.totalRounds}'),
            if (winners.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Premio Lota:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...winners.map(
                  (r) => Text('• ${r.cartonId} (ronda ${r.roundNumber})')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(RouteNames.home);
            },
            child: const Text('Volver al inicio'),
          ),
        ],
      ),
    );
  }
}

// ── Vistas internas ────────────────────────────────────────────────────────────

class _GameBody extends StatelessWidget {
  const _GameBody({
    required this.state,
    required this.mode,
    required this.cardColors,
  });

  final GameInProgress state;
  final GameMode mode;
  final Map<String, LotaCardColor> cardColors;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.cartones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final carton = state.cartones[index];
        final cardColor = cardColors[carton.id];
        final accentColor =
            cardColor?.primary ?? Theme.of(context).colorScheme.primary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cartón ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                  ),
                  Text(
                    '${carton.markedCount} / ${carton.totalNumbers}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            LotaCardWidget(
              model: carton,
              drawnNumbers: state.drawnSet,
              accentColor: cardColor,
              onCellTap: (number) => context.read<GameBloc>().add(
                    NumberToggled(cartonId: carton.id, number: number),
                  ),
            ),
            const SizedBox(height: 8),
            _PrizeButtons(cartonId: carton.id, state: state),
          ],
        );
      },
    );
  }
}

class _PrizeButtons extends StatelessWidget {
  const _PrizeButtons({required this.cartonId, required this.state});

  final String cartonId;
  final GameInProgress state;

  bool get _lineaClaimed => state.results
      .any((r) => r.cartonId == cartonId && r.prize == PrizeType.linea);

  bool get _lotaClaimed => state.results
      .any((r) => r.cartonId == cartonId && r.prize == PrizeType.lota);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!_lineaClaimed)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.read<GameBloc>().add(LinePrizeClaimed(cartonId)),
              icon: const Icon(Icons.horizontal_rule_rounded, size: 18),
              label: const Text('Línea'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          )
        else
          Expanded(
            child: Chip(
              label: const Text('✓ Línea'),
              backgroundColor: Colors.green.shade50,
              side: BorderSide(color: Colors.green.shade200),
              labelStyle: const TextStyle(color: Colors.green),
            ),
          ),
        const SizedBox(width: 8),
        if (!_lotaClaimed)
          Expanded(
            child: FilledButton.icon(
              onPressed: () =>
                  context.read<GameBloc>().add(LotaPrizeClaimed(cartonId)),
              icon: const Icon(Icons.star_rounded, size: 18),
              label: const Text('¡Lota!'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.amber.shade700,
              ),
            ),
          )
        else
          Expanded(
            child: Chip(
              label: const Text('✓ Lota'),
              backgroundColor: Colors.amber.shade50,
              side: BorderSide(color: Colors.amber.shade300),
              labelStyle: TextStyle(color: Colors.amber.shade800),
            ),
          ),
      ],
    );
  }
}

class _GameOverBody extends StatelessWidget {
  const _GameOverBody({required this.state});

  final GameOver state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              '¡Partida terminada!',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.totalRounds} números sorteados',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go(RouteNames.home),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
