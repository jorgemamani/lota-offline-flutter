import 'package:flutter/material.dart';

import 'scrollable_bottom_sheet_body.dart';

/// Bottom sheet informativo.
///
/// Muestra un ícono opcional, un título y un mensaje descriptivo.
/// Solo tiene un botón de cierre ("Entendido").
///
/// No retorna ningún valor — su única responsabilidad es informar.
///
/// Uso directo:
/// ```dart
/// AlertManager.showInfoSheet(
///   title: 'Información',
///   message: 'Tu cartón fue guardado correctamente.',
///   icon: Icons.check_circle_outline,
/// );
/// ```
class InfoBottomSheet extends StatelessWidget {
  const InfoBottomSheet({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.closeLabel = 'Entendido',
  });

  final String title;
  final String message;
  final IconData? icon;

  /// Label del botón de cierre. Default: "Entendido".
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: ScrollableBottomSheetBody(
        fixedHeader: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DragHandle(),
            SizedBox(height: icon != null ? 20 : 16),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 44, color: theme.colorScheme.primary),
            if (icon != null) const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(closeLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
