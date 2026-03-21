import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, __) =>
          context.read<GameBloc>().add(const GameReset()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bolillero'),
          actions: [
            BlocBuilder<GameBloc, GameState>(
              builder: (context, state) {
                if (state is! GameInProgress) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: Text(
                      'Ronda ${state.round}',
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
              _showGameOverDialog(context, state);
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
                    if (state is GameInProgress) {
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

  void _showGameOverDialog(BuildContext context, GameOver state) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('¡Todos los números!'),
        content: Text(
          'Se sortearon los 90 números en ${state.totalRounds} rondas.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<GameBloc>().add(const GameReset());
            },
            child: const Text('Nueva partida'),
          ),
        ],
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Reiniciar bolillero'),
            content: const Text('¿Seguro que querés reiniciar el sorteo?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Reiniciar'),
              ),
            ],
          ),
        ).then((confirmed) {
          if (confirmed == true && context.mounted) {
            context.read<GameBloc>().add(const GameReset());
            context.read<GameBloc>().add(const GameStarted(
                  mode: GameMode.bolilleroOnly,
                  cartones: <LotaCardModel>[],
                ));
          }
        });
      },
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Reiniciar sorteo'),
    );
  }
}
