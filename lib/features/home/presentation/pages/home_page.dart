import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/constants/app_assets.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/managers/alert_manager.dart';
import '../../../../shared/widgets/image_component.dart';
import '../../../game/domain/models/game_mode.dart';
import '../../../game/domain/models/session_data.dart';
import '../../../game/presentation/bloc/game_bloc.dart';
import '../../../game/presentation/cubit/session_cubit.dart';
import '../../../game/presentation/pages/carton_select_page.dart';
import '../../../game/presentation/pages/game_play_page.dart';
import '../cubit/theme_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      // Evita que el gesto / botón físico atrás cierre la app o salga del home.
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                _Header(),
                const SizedBox(height: 15),
                // ── Tarjeta de partida guardada ──────────────────────────
                BlocBuilder<SessionCubit, SessionState>(
                  builder: (context, sessionState) {
                    if (sessionState.isLoading || !sessionState.hasSession) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: _SessionRecoveryCard(
                        session: sessionState.session!,
                        onResume: () =>
                            _resumeSession(context, sessionState.session!),
                        onDismiss: () => _confirmDismiss(context),
                      ),
                    );
                  },
                ),
                // ────────────────────────────────────────────────────────
                const SizedBox(height: 15),
                Text(
                  '¿Cómo querés jugar?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      _GameModeCard(
                        mode: GameMode.markOnly,
                        imagePath: AppAssets.gameModeMarkCarton,
                        color: AppColors.gameModeMarkOnly,
                        onTap: () =>
                            _goToCartonSelect(context, GameMode.markOnly),
                      ),
                      const SizedBox(height: 16),
                      _GameModeCard(
                        mode: GameMode.bolilleroOnly,
                        imagePath: AppAssets.gameModeBolillero,
                        color: AppColors.gameModeBolillero,
                        onTap: () => context.push(RouteNames.bolillero),
                      ),
                      const SizedBox(height: 16),
                      _GameModeCard(
                        mode: GameMode.combined,
                        imagePath: AppAssets.gameModeCombined,
                        color: AppColors.gameModeCombined,
                        onTap: () =>
                            _goToCartonSelect(context, GameMode.combined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goToCartonSelect(BuildContext context, GameMode mode) {
    context.push(
      RouteNames.cartonSelect,
      extra: CartonSelectArgs(mode: mode),
    );
  }

  void _resumeSession(BuildContext context, SessionData session) {
    final cartones = session.cartones.map((c) => c.toLotaCardModel()).toList();
    final cardColors = {
      for (int i = 0; i < session.cartones.length; i++)
        cartones[i].id: session.cartones[i].color,
    };

    context.read<GameBloc>().add(GameResumed(
          mode: session.mode,
          cartones: cartones,
          drawnNumbers: session.drawnNumbers,
        ));

    // No se limpia la sesión aquí: si la app se cierra inesperadamente
    // otra vez durante la partida, debe seguir apareciendo la tarjeta.
    // La sesión se elimina sólo cuando el usuario confirma "Salir igual"
    // o descarta explícitamente la tarjeta.

    if (session.mode == GameMode.bolilleroOnly) {
      context.push(RouteNames.bolillero);
    } else {
      context.push(
        RouteNames.gamePlay,
        extra: GamePlayArgs(
          mode: session.mode,
          cartones: cartones,
          cardColors: cardColors,
        ),
      );
    }
  }

  void _confirmDismiss(BuildContext context) {
    AlertManager.showConfirmSheet(
      title: 'Descartar partida',
      description:
          'Se borrará la partida guardada y no podrás retomar desde donde estabas.',
      options: [
        SheetOption(
          label: 'Descartar',
          isDestructive: true,
          onTap: () => context.read<SessionCubit>().clear(),
        ),
        SheetOption(
          label: 'Cancelar',
          style: SheetOptionStyle.outlined,
          onTap: () {},
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const ImageComponent(
              imagePath: AppAssets.lotaLogo,
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lota Pue - Bingo 90',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HeaderActionsBar(),
      ],
    );
  }
}

/// Acciones del encabezado (Acerca, tema, etc.). Agregar nuevos controles aquí.
class _HeaderActionsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          _ThemeToggle(),
          _AboutAppAction(),
        ],
      ),
    );
  }
}

/// Misma familia visual que [_ThemeToggle]: cápsula + control compacto.
class _AboutAppAction extends StatelessWidget {
  const _AboutAppAction();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: 'Acerca de la app',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(RouteNames.about),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Información',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentMode = context.watch<ThemeCubit>().state;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeButton(
            icon: Icons.brightness_auto_rounded,
            tooltip: 'Automático',
            selected: currentMode == ThemeMode.system,
            onTap: () => context.read<ThemeCubit>().setSystem(),
          ),
          _ThemeButton(
            icon: Icons.light_mode_rounded,
            tooltip: 'Claro',
            selected: currentMode == ThemeMode.light,
            onTap: () => context.read<ThemeCubit>().setLight(),
          ),
          _ThemeButton(
            icon: Icons.dark_mode_rounded,
            tooltip: 'Oscuro',
            selected: currentMode == ThemeMode.dark,
            onTap: () => context.read<ThemeCubit>().setDark(),
          ),
        ],
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tarjeta de sesión guardada ─────────────────────────────────────────────

class _SessionRecoveryCard extends StatelessWidget {
  const _SessionRecoveryCard({
    required this.session,
    required this.onResume,
    required this.onDismiss,
  });

  final SessionData session;
  final VoidCallback onResume;
  final VoidCallback onDismiss;

  static const _accent = AppColors.statusWarning;

  String get _detail {
    final drawn = session.drawnNumbers.length;
    return switch (session.mode) {
      GameMode.bolilleroOnly =>
        '$drawn número${drawn == 1 ? '' : 's'} sorteado${drawn == 1 ? '' : 's'}',
      GameMode.markOnly =>
        '${session.cartones.length} cartón${session.cartones.length == 1 ? '' : 'es'}',
      GameMode.combined =>
        '$drawn número${drawn == 1 ? '' : 's'} sorteado${drawn == 1 ? '' : 's'} · ${session.cartones.length} cartón${session.cartones.length == 1 ? '' : 'es'}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? _accent.withValues(alpha: 0.12)
        : _accent.withValues(alpha: 0.07);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onResume,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _accent.withValues(alpha: isDark ? 0.4 : 0.3),
            ),
          ),
          child: Row(
            children: [
              // ── Franja de color izquierda ────────────────────────────
              Container(
                width: 4,
                height: 72,
                margin: const EdgeInsets.only(left: 0),
                decoration: const BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // ── Icono ────────────────────────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: _accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // ── Textos ───────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Partida sin terminar',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.slate700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.mode.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: _accent,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _detail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Botón continuar + descartar ──────────────────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Continuar',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: _accent,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    tooltip: 'Descartar',
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(8),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tarjetas de modo de juego ──────────────────────────────────────────────

class _GameModeCard extends StatelessWidget {
  const _GameModeCard({
    required this.mode,
    required this.imagePath,
    required this.color,
    required this.onTap,
  });

  final GameMode mode;
  final String imagePath;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      borderRadius: BorderRadius.circular(20),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8),
                child: ImageComponent(
                  imagePath: imagePath,
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
