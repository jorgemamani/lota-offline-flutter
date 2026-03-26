import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/managers/alert_manager.dart';
import '../../../game/domain/models/game_mode.dart';
import '../../../game/domain/models/lota_card_model.dart';
import '../../../game/domain/models/session_data.dart';
import '../../../game/presentation/bloc/game_bloc.dart';
import '../../../game/presentation/cubit/session_cubit.dart';
import '../widgets/bolillero_widget.dart';

/// Pantalla standalone del bolillero (modo [GameMode.bolilleroOnly]).
///
/// Si el [GameBloc] ya está en [GameInProgress] (resumida desde sesión guardada)
/// no se despacha un nuevo [GameStarted].
class BolilleroPage extends StatefulWidget {
  const BolilleroPage({super.key});

  @override
  State<BolilleroPage> createState() => _BolilleroPageState();
}

class _BolilleroPageState extends State<BolilleroPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Si el bloc ya fue restaurado por GameResumed desde el Home, no reiniciar.
      if (context.read<GameBloc>().state is! GameInProgress) {
        context.read<GameBloc>().add(const GameStarted(
              mode: GameMode.bolilleroOnly,
              cartones: <LotaCardModel>[],
            ));
      }
    });
  }

  void _clearSession() => context.read<SessionCubit>().clear();

  /// Reinicio explícito desde el botón (sheet confirmado).
  ///
  /// Siempre borra la sesión en disco y la tarjeta del home — también cuando
  /// todavía no hay números sorteados en pantalla (el usuario elige reiniciar
  /// en lugar de volver atrás, donde conservamos la sesión si no sorteó).
  void _onConfirmReiniciarSorteo(BuildContext context) {
    _clearSession();
    context.read<GameBloc>().add(const GameReset());
    context.read<GameBloc>().add(const GameStarted(
          mode: GameMode.bolilleroOnly,
          cartones: <LotaCardModel>[],
        ));
  }

  void _handlePop(BuildContext context) {
    final state = context.read<GameBloc>().state;
    final hasNumbers =
        (state is GameInProgress && state.drawnNumbers.isNotEmpty) ||
            state is GameOver;

    if (!hasNumbers) {
      // No borrar la sesión en disco: si había tarjeta de recuperación y el
      // usuario entró al bolillero pero no sorteó nada, debe seguir apareciendo.
      context.read<GameBloc>().add(const GameReset());
      Navigator.of(context).pop();
      return;
    }

    AlertManager.showConfirmSheet(
      title: 'Hay números sorteados',
      description: 'Si salís se perderá el progreso del bolillero.',
      options: [
        SheetOption(
          label: 'Salir igual',
          isDestructive: true,
          onTap: () {
            _clearSession();
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

            // Guardar sesión en cada sorteo.
            if (state is GameInProgress && state.drawnNumbers.isNotEmpty) {
              context.read<SessionCubit>().save(
                    SessionData(
                      mode: GameMode.bolilleroOnly,
                      cartones: const [],
                      drawnNumbers: state.drawnNumbers,
                      savedAt: DateTime.now(),
                    ),
                  );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                BolilleroWidget(
                  onReiniciarPressed: () => AlertManager.showConfirmSheet(
                    title: 'Reiniciar bolillero',
                    description: '¿Seguro que querés reiniciar el sorteo?',
                    options: [
                      SheetOption(
                        label: 'Reiniciar',
                        onTap: () => _onConfirmReiniciarSorteo(context),
                      ),
                      SheetOption(
                        label: 'Cancelar',
                        style: SheetOptionStyle.outlined,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
