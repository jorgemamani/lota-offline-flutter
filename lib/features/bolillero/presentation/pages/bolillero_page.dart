import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/managers/alert_manager.dart';
import '../../../game/domain/models/game_mode.dart';
import '../../../game/domain/models/lota_card_model.dart';
import '../../../game/presentation/bloc/game_bloc.dart';
import '../widgets/bolillero_widget.dart';

/// Pantalla standalone del bolillero (modo [GameMode.bolilleroOnly]).
/// Inicia una partida sin cartones al montar.
class BolilleroPage extends StatefulWidget {
  const BolilleroPage({super.key});

  @override
  State<BolilleroPage> createState() => _BolilleroPageState();
}

class _BolilleroPageState extends State<BolilleroPage> {
  @override
  void initState() {
    super.initState();
    // Inicia el GameBloc en modo bolilleroOnly sin cartones
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameBloc>().add(const GameStarted(
            mode: GameMode.bolilleroOnly,
            cartones: <LotaCardModel>[],
          ));
    });
  }

  void _handlePop(BuildContext context) {
    final state = context.read<GameBloc>().state;
    final hasNumbers = (state is GameInProgress &&
            state.drawnNumbers.isNotEmpty) ||
        state is GameOver;

    if (!hasNumbers) {
      context.read<GameBloc>().add(const GameReset());
      Navigator.of(context).pop();
      return;
    }

    AlertManager.showConfirmSheet(
      title: 'Hay números sorteados',
      description:
          'Si salís se perderá el progreso del bolillero.',
      options: [
        SheetOption(
          label: 'Salir igual',
          isDestructive: true,
          onTap: () {
            context.read<GameBloc>().add(const GameReset());
            Navigator.of(context).pop();
          },
        ),
        SheetOption(
          label: 'Quedarme',
          style: SheetOptionStyle.outlined,
          onTap: () {},
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handlePop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bolillero'),
          actions: [
            BlocBuilder<GameBloc, GameState>(
              builder: (context, state) {
                final round = switch (state) {
                  GameInProgress() => state.round,
                  GameOver() => state.totalRounds,
                  _ => null,
                };
                if (round == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: Text(
                      'Ronda $round',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
            if (state is GameOver) {
              AlertManager.showSnackBar(
                message: 'Se sortearon los 90 números.',
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const BolilleroWidget(),
                const SizedBox(height: 16),
                BlocBuilder<GameBloc, GameState>(
                  builder: (context, state) {
                    if (state is GameInProgress || state is GameOver) {
                      return _ResetButton();
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => AlertManager.showConfirmSheet(
        title: 'Reiniciar bolillero',
        description: '¿Seguro que querés reiniciar el sorteo?',
        options: [
          SheetOption(
            label: 'Reiniciar',
            onTap: () {
              context.read<GameBloc>().add(const GameReset());
              context.read<GameBloc>().add(const GameStarted(
                    mode: GameMode.bolilleroOnly,
                    cartones: <LotaCardModel>[],
                  ));
            },
          ),
          SheetOption(
            label: 'Cancelar',
            style: SheetOptionStyle.outlined,
            onTap: () {},
          ),
        ],
      ),
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Reiniciar sorteo'),
    );
  }
}
