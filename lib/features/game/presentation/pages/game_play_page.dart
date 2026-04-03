import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/constants/app_assets.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/constants/carton_display_scale.dart';
import '../../../../shared/constants/lota_card_colors.dart';
import '../../../../shared/managers/alert_manager.dart';
import '../../../../shared/widgets/image_component.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../domain/models/favorite_carton.dart';
import '../../domain/models/session_data.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/session_cubit.dart';
import '../../../bolillero/presentation/widgets/bolillero_widget.dart';
import '../../domain/models/game_mode.dart';
import '../../domain/models/game_result.dart';
import '../../domain/models/lota_card_model.dart';
import '../bloc/game_bloc.dart';
import '../cubit/carton_display_scale_cubit.dart';
import '../widgets/carton_display_scale_sheet.dart';
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

class GamePlayPage extends StatefulWidget {
  const GamePlayPage({super.key, required this.args});

  final GamePlayArgs args;

  @override
  State<GamePlayPage> createState() => _GamePlayPageState();
}

class _GamePlayPageState extends State<GamePlayPage>
    with SingleTickerProviderStateMixin {
  GamePlayArgs get args => widget.args;

  late final AnimationController _pulseCtrl;
  bool _showBolilleroHint = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    if (args.mode == GameMode.combined) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Arranca el pulso inmediatamente para llamar la atención al botón.
        setState(() => _showBolilleroHint = true);
        _pulseCtrl.repeat(reverse: true);

        // Abre el sheet suavemente después de medio segundo.
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _showBolilleroModal(context);
        });
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _stopBolilleroHint() {
    if (_showBolilleroHint) {
      setState(() => _showBolilleroHint = false);
      _pulseCtrl.stop();
    }
  }

  // ── Sesión ───────────────────────────────────────────────────────

  void _clearSession() => context.read<SessionCubit>().clear();

  void _saveSession(GameInProgress state) {
    final shouldSave = args.mode == GameMode.combined
        ? state.drawnNumbers.isNotEmpty
        : state.cartones.any((c) => c.markedCount > 0);

    if (!shouldSave) return;

    final sessionCartones = state.cartones.map((carton) {
      final color = args.cardColors[carton.id];
      final colorIndex = color == null
          ? 0
          : LotaCardColors.all.indexWhere((c) => c.primary == color.primary);
      return SessionCarton(
        grid: carton.card,
        cardState: carton.cardState,
        colorIndex: colorIndex < 0 ? 0 : colorIndex,
      );
    }).toList();

    context.read<SessionCubit>().save(SessionData(
          mode: args.mode,
          cartones: sessionCartones,
          drawnNumbers: state.drawnNumbers,
          savedAt: DateTime.now(),
        ));
  }

  // ── Navegación con confirmación ───────────────────────────────────

  void _handlePop(BuildContext context) {
    final gameState = context.read<GameBloc>().state;
    final favState = context.read<FavoritesCubit>().state;

    final hasUnsaved = args.cartones.any(
      (c) => !favState.isFavorite(FavoriteCarton.idFromGrid(c.card)),
    );

    const unsavedMsg = 'Los cartones se generan al azar cada vez. '
        'Si salís sin guardarlos no los vas a encontrar de nuevo.';

    if (args.mode == GameMode.combined) {
      final drawnCount = switch (gameState) {
        GameInProgress() => gameState.drawnNumbers.length,
        GameOver() => gameState.drawnNumbers.length,
        _ => 0,
      };
      final hasDrawn = drawnCount > 0;
      final n = drawnCount;
      final drawnMsg =
          'Hay $n número${n == 1 ? '' : 's'} sorteado${n == 1 ? '' : 's'}. '
          'Si salís se perderá el progreso.';

      if (!hasDrawn && !hasUnsaved) {
        _popFree(context);
        return;
      }
      if (hasDrawn && hasUnsaved) {
        _showExitConfirm(
          context,
          title: 'Partida en curso · Cartones sin guardar',
          description: '$drawnMsg\n\n$unsavedMsg',
        );
      } else if (hasDrawn) {
        _showExitConfirm(
          context,
          title: 'Partida en curso',
          description: drawnMsg,
        );
      } else {
        _showExitConfirm(
          context,
          title: 'Cartones sin guardar',
          description: unsavedMsg,
        );
      }
    } else {
      // markOnly
      final hasMarks = gameState is GameInProgress &&
          gameState.cartones.any((c) => c.markedCount > 0);
      const marksMsg =
          'Si salís perderás las marcas realizadas en los cartones.';

      if (!hasMarks && !hasUnsaved) {
        _popFree(context);
        return;
      }
      if (hasMarks && hasUnsaved) {
        _showExitConfirm(
          context,
          title: 'Tenés números marcados · Cartones sin guardar',
          description: '$marksMsg\n\n$unsavedMsg',
        );
      } else if (hasMarks) {
        _showExitConfirm(
          context,
          title: 'Tenés números marcados',
          description: marksMsg,
        );
      } else {
        _showExitConfirm(
          context,
          title: 'Cartones sin guardar',
          description: unsavedMsg,
        );
      }
    }
  }

  void _popFree(BuildContext context) {
    _clearSession();
    context.read<GameBloc>().add(const GameReset());
    Navigator.of(context).pop();
  }

  /// Cartones con la misma grilla que en el estado actual pero sin marcas.
  List<LotaCardModel> _freshCartonesUnmarked(GameState state) {
    final list = switch (state) {
      GameInProgress() => state.cartones,
      GameOver() => state.cartones,
      _ => args.cartones,
    };
    return list
        .map(
          (c) => LotaCardModel.fromGrid(
            id: c.id,
            grid: c.card,
          ),
        )
        .toList();
  }

  bool _hasAnyMarks(GameState state) => switch (state) {
        GameInProgress() => state.cartones.any((c) => c.markedCount > 0),
        GameOver() => state.cartones.any((c) => c.markedCount > 0),
        _ => false,
      };

  void _switchToCombinedMode(BuildContext context) {
    final bloc = context.read<GameBloc>();
    final fresh = _freshCartonesUnmarked(bloc.state);
    _clearSession();
    bloc.add(const GameReset());
    bloc.add(GameStarted(
      mode: GameMode.combined,
      cartones: fresh,
    ));
    if (!context.mounted) return;
    context.pushReplacement(
      RouteNames.gamePlay,
      extra: GamePlayArgs(
        mode: GameMode.combined,
        cartones: fresh,
        cardColors: args.cardColors,
      ),
    );
  }

  void _onMarkOnlyCantarPressed(BuildContext context) {
    final bloc = context.read<GameBloc>();
    final state = bloc.state;
    if (!_hasAnyMarks(state)) {
      AlertManager.showConfirmSheet(
        title: '¿Querés ser el cantador?',
        description:
            'Vas a pasar al modo ${GameMode.combined.label}: mismos cartones, '
            'bolillero integrado y los números se marcan solos cuando los '
            'sorteás.\n\n'
            'No se pierde nada porque todavía no marcaste números.',
        options: [
          SheetOption(
            label: 'Cambiar de modo',
            onTap: () => _switchToCombinedMode(context),
          ),
          SheetOption(
            label: 'Cancelar',
            style: SheetOptionStyle.outlined,
            onTap: () {},
          ),
        ],
      );
      return;
    }

    AlertManager.showConfirmSheet(
      title: 'Cambiar a ${GameMode.combined.label}',
      description:
          'Para usar el bolillero con marcado automático hay que dejar los '
          'cartones sin marcas. Podés reiniciar y cambiar de modo, o seguir '
          'marcando a mano.',
      options: [
        SheetOption(
          label: 'Reiniciar y cambiar',
          onTap: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AlertManager.showConfirmSheet(
                title: 'Reiniciar y pasar a ${GameMode.combined.label}',
                description:
                    'Se borrarán todas las marcas de todos los cartones y '
                    'se abrirá el bolillero en el nuevo modo.',
                options: [
                  SheetOption(
                    label: 'Reiniciar y cambiar',
                    isDestructive: true,
                    onTap: () => _switchToCombinedMode(context),
                  ),
                  SheetOption(
                    label: 'Cancelar',
                    style: SheetOptionStyle.outlined,
                    onTap: () {},
                  ),
                ],
              );
            });
          },
        ),
        SheetOption(
          label: 'Cancelar',
          style: SheetOptionStyle.outlined,
          onTap: () {},
        ),
      ],
    );
  }

  void _showExitConfirm(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    AlertManager.showConfirmSheet(
      title: title,
      description: description,
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
          title: Text(
            args.mode.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.text_fields_rounded),
              tooltip: 'Tamaño de los números',
              onPressed: () => CartonDisplayScaleSheet.show(context),
            ),
            // Marcar cartones: acceso al modo combinado (cantador + bolillero).
            if (args.mode == GameMode.markOnly)
              BlocBuilder<GameBloc, GameState>(
                builder: (context, state) {
                  if (state is GameIdle) return const SizedBox.shrink();
                  return IconButton(
                    icon: ImageComponent(
                      imagePath: AppAssets.gameModeBolillero,
                      width: 30,
                      height: 30,
                      fit: BoxFit.contain,
                      color: IconTheme.of(context).color ??
                          Theme.of(context).colorScheme.onSurface,
                    ),
                    tooltip: 'Quiero cantar',
                    onPressed: () => _onMarkOnlyCantarPressed(context),
                  );
                },
              ),
            // Botón bolillero en modal (sólo modo combined, en curso o finalizado)
            if (args.mode == GameMode.combined)
              BlocBuilder<GameBloc, GameState>(
                builder: (context, state) {
                  if (state is GameIdle) return const SizedBox.shrink();
                  final lastNum = switch (state) {
                    GameInProgress() => state.lastDrawnNumber,
                    GameOver() => state.drawnNumbers.isEmpty
                        ? null
                        : state.drawnNumbers.last,
                    _ => null,
                  };
                  final button = Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: ImageComponent(
                          imagePath: AppAssets.gameModeBolillero,
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                          color: IconTheme.of(context).color ??
                              Theme.of(context).colorScheme.onSurface,
                        ),
                        tooltip: 'Bolillero',
                        onPressed: () {
                          _stopBolilleroHint();
                          _showBolilleroModal(context);
                        },
                      ),
                      if (lastNum != null)
                        Positioned(
                          top: 8,
                          right: 6,
                          child: GestureDetector(
                            onTap: () {
                              _stopBolilleroHint();
                              _showBolilleroModal(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$lastNum',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );

                  if (!_showBolilleroHint) return button;

                  return AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: _pulseCtrl.value * 0.22),
                      ),
                      child: child,
                    ),
                    child: button,
                  );
                },
              ),
            // Botón limpiar marcas / reiniciar
            BlocBuilder<GameBloc, GameState>(
              builder: (context, state) {
                if (state is GameIdle) return const SizedBox.shrink();
                final isCombined = args.mode == GameMode.combined;
                return IconButton(
                  icon: const Icon(Icons.restart_alt_rounded),
                  tooltip: isCombined ? 'Reiniciar juego' : 'Limpiar marcas',
                  onPressed: () => AlertManager.showConfirmSheet(
                    title: isCombined ? 'Reiniciar juego' : 'Limpiar marcas',
                    description: isCombined
                        ? 'Se borrarán las marcas y el bolillero comenzará de cero.'
                        : 'Se borrarán todas las marcas del cartón.',
                    options: [
                      SheetOption(
                        label: isCombined ? 'Reiniciar' : 'Limpiar',
                        onTap: () {
                          final bloc = context.read<GameBloc>();
                          // Misma grilla que el juego en curso, sin marcas — no usar
                          // [args.cartones]: al continuar partida queda congelada la
                          // instantánea del push y el bloc puede haber cambiado.
                          final fresh = _freshCartonesUnmarked(bloc.state);
                          _clearSession();
                          bloc.add(const GameReset());
                          bloc.add(GameStarted(
                                mode: args.mode,
                                cartones: fresh,
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
                );
              },
            ),
            // Ronda = bolillas sacadas; sólo aplica al modo combinado.
            if (args.mode == GameMode.combined)
              BlocBuilder<GameBloc, GameState>(
                builder: (context, state) {
                  final round = switch (state) {
                    GameInProgress() => state.round,
                    GameOver() => state.totalRounds,
                    _ => null,
                  };
                  if (round == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Center(
                      child: Text(
                        'R$round',
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
            // Guardar sesión en cada progreso.
            if (state is GameInProgress) _saveSession(state);

            // Premios detectados automáticamente al marcar.
            if (state is GameInProgress &&
                state.newlyAchievedPrizes.isNotEmpty) {
              final cartones = state.cartones;
              for (final result in state.newlyAchievedPrizes) {
                final idx = cartones.indexWhere((c) => c.id == result.cartonId);
                final suffix = cartones.length > 1 && idx >= 0
                    ? ' — Cartón ${idx + 1}'
                    : '';
                switch (result.prize) {
                  case PrizeType.cuaterno:
                    AlertManager.showTopSnackBarSuccess(
                      message: '¡Cuaterno!$suffix',
                      duration: const Duration(seconds: 4),
                    );
                  case PrizeType.linea:
                    AlertManager.showTopSnackBarSuccess(
                      message: '¡Línea!$suffix',
                      duration: const Duration(seconds: 4),
                    );
                  case PrizeType.lota:
                    AlertManager.showTopSnackBarSuccess(
                      message: '¡Cartón lleno!$suffix',
                      duration: const Duration(seconds: 4),
                    );
                }
              }
            }

            if (state is! GameOver) return;
            final hasLota = state.results.any((r) => r.prize == PrizeType.lota);
            if (hasLota) {
              AlertManager.showSnackBarSuccess(
                message: '¡Cartón lleno! Partida finalizada.',
              );
            } else {
              AlertManager.showSnackBar(
                message: 'Se sortearon los 90 números.',
              );
            }
          },
          child: BlocBuilder<GameBloc, GameState>(
            builder: (context, state) {
              if (state is GameIdle) return const LoadingIndicator();
              if (state is GameInProgress) {
                return _GameBody(
                  state: state,
                  cardColors: args.cardColors,
                );
              }
              if (state is GameOver) {
                // Tablero congelado: muestra el estado final sin permitir acciones.
                final frozen = GameInProgress(
                  mode: state.mode,
                  cartones: state.cartones,
                  drawnNumbers: state.drawnNumbers,
                  availableNumbers: const [],
                  lastDrawnNumber: state.drawnNumbers.isEmpty
                      ? null
                      : state.drawnNumbers.last,
                  results: state.results,
                );
                return _GameBody(
                  state: frozen,
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
                const BolilleroWidget(showReiniciarSorteo: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Vistas internas ────────────────────────────────────────────────────────────

class _GameBody extends StatelessWidget {
  const _GameBody({
    required this.state,
    required this.cardColors,
  });

  final GameInProgress state;
  final Map<String, LotaCardColor> cardColors;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartonDisplayScaleCubit, int>(
      builder: (context, step) {
        final displayScale = CartonDisplayScale.multiplierForStep(step);
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
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                      ),
                      Text(
                        '${carton.markedCount} / ${carton.totalNumbers}',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                LotaCardWidget(
                  model: carton,
                  drawnNumbers: state.drawnSet,
                  accentColor: cardColor,
                  displayScale: displayScale,
                  onCellTap: (number) => context.read<GameBloc>().add(
                        NumberToggled(cartonId: carton.id, number: number),
                      ),
                ),
                const SizedBox(height: 6),
                _CartonActions(carton: carton, cardColor: cardColor),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Acciones por cartón ──────────────────────────────────────────────────────

/// Barra de acciones debajo de cada cartón.
///
/// Diseñada para escalar: cada acción nueva (QR, compartir, etc.)
/// se agrega como un [TextButton.icon] más en el [Row].
class _CartonActions extends StatelessWidget {
  const _CartonActions({required this.carton, required this.cardColor});

  final LotaCardModel carton;
  final LotaCardColor? cardColor;

  @override
  Widget build(BuildContext context) {
    final contentId = FavoriteCarton.idFromGrid(carton.card);
    final colorIndex = cardColor == null
        ? 0
        : LotaCardColors.all.indexWhere((c) => c.primary == cardColor!.primary);

    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, favState) {
        final isFav = favState.isFavorite(contentId);
        final favoriteColor =
            isFav ? AppColors.favorite : Theme.of(context).colorScheme.outline;

        return Row(
          children: [
            // ── Favorito ────────────────────────────────────────────────────
            TextButton.icon(
              onPressed: () {
                if (isFav) {
                  AlertManager.showSnackBar(
                    message:
                        'Para quitar de favoritos, andá a la sección Favoritos.',
                  );
                } else {
                  context.read<FavoritesCubit>().toggle(
                        grid: carton.card,
                        colorIndex: colorIndex < 0 ? 0 : colorIndex,
                      );
                  AlertManager.showSnackBarSuccess(
                    message: 'Cartón guardado en favoritos.',
                  );
                }
              },
              icon: Icon(
                isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 20,
                color: favoriteColor,
              ),
              label: Text(isFav ? 'En favoritos' : 'Guardar'),
              style: TextButton.styleFrom(
                foregroundColor: favoriteColor,
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                textStyle: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            // ── Espacio para más acciones (QR, compartir, etc.) ─────────────
          ],
        );
      },
    );
  }
}
