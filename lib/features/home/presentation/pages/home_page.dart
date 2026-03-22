import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/constants/app_assets.dart';
import '../../../../shared/widgets/image_component.dart';
import '../../../game/domain/models/game_mode.dart';
import '../../../game/presentation/pages/carton_select_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              _Header(),
              const SizedBox(height: 40),
              Expanded(
                child: ListView(
                  children: [
                    _GameModeCard(
                      mode: GameMode.markOnly,
                      icon: Icons.edit_note_rounded,
                      color: const Color(0xFF2563EB),
                      onTap: () =>
                          _goToCartonSelect(context, GameMode.markOnly),
                    ),
                    const SizedBox(height: 16),
                    _GameModeCard(
                      mode: GameMode.bolilleroOnly,
                      icon: Icons.casino_rounded,
                      color: const Color(0xFF7C3AED),
                      onTap: () => context.push(RouteNames.bolillero),
                    ),
                    const SizedBox(height: 16),
                    _GameModeCard(
                      mode: GameMode.combined,
                      icon: Icons.join_full_rounded,
                      color: const Color(0xFF059669),
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
    );
  }

  void _goToCartonSelect(BuildContext context, GameMode mode) {
    context.push(
      RouteNames.cartonSelect,
      extra: CartonSelectArgs(mode: mode),
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
              imagePath: AppAssets.lotaIcon,
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              'LOTA',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '¿Cómo querés jugar?',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _GameModeCard extends StatelessWidget {
  const _GameModeCard({
    required this.mode,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final GameMode mode;
  final IconData icon;
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
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
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
