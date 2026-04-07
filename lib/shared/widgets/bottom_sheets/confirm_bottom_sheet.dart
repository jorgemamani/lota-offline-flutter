import 'package:flutter/material.dart';

import 'scrollable_bottom_sheet_body.dart';

// ── Modelos ───────────────────────────────────────────────────────────────────

/// Estilo visual del botón de una [SheetOption].
enum SheetOptionStyle {
  /// Botón relleno (FilledButton). Ideal para acciones primarias.
  filled,

  /// Botón con borde (OutlinedButton). Ideal para cancelar o acciones secundarias.
  outlined,
}

/// Opción de acción dentro de un [ConfirmBottomSheet].
///
/// Cada opción define su label, la función a ejecutar y su apariencia.
/// El sheet se cierra automáticamente al pulsar cualquier opción.
///
/// ```dart
/// SheetOption(
///   label: 'Eliminar',
///   onTap: () => cubit.deleteItem(),
///   isDestructive: true,
/// )
/// ```
class SheetOption {
  const SheetOption({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.style = SheetOptionStyle.filled,
  });

  /// Texto que se muestra en el botón.
  final String label;

  /// Callback invocado al pulsar la opción.
  /// El sheet se cierra antes de ejecutarlo.
  final VoidCallback onTap;

  /// Si es `true`, el botón se pinta con los colores de error del tema.
  /// Sobreescribe [style] y siempre usa FilledButton.
  final bool isDestructive;

  /// Estilo visual del botón. Ignorado si [isDestructive] es `true`.
  final SheetOptionStyle style;
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// Bottom sheet de confirmación.
///
/// Presenta título, descripción y entre 2 y 3 opciones de acción.
/// Cada opción cierra el sheet y ejecuta su callback.
///
/// Uso:
/// ```dart
/// AlertManager.showConfirmSheet(
///   title: '¿Eliminar favorito?',
///   description: 'Esta acción no se puede deshacer.',
///   options: [
///     SheetOption(
///       label: 'Eliminar',
///       onTap: () => cubit.removeFavorite(id),
///       isDestructive: true,
///     ),
///     SheetOption(
///       label: 'Cancelar',
///       onTap: () {},
///       style: SheetOptionStyle.outlined,
///     ),
///   ],
/// );
/// ```
class ConfirmBottomSheet extends StatelessWidget {
  const ConfirmBottomSheet({
    super.key,
    required this.title,
    required this.description,
    required this.options,
  });

  final String title;
  final String description;
  final List<SheetOption> options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: ScrollableBottomSheetBody(
        fixedHeader: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DragHandle(),
            SizedBox(height: 20),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ...options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _OptionButton(option: option),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets privados ──────────────────────────────────────────────────────────

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.option});

  final SheetOption option;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    void onPressed() {
      Navigator.of(context).pop();
      option.onTap();
    }

    if (option.isDestructive) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
        ),
        child: Text(option.label),
      );
    }

    if (option.style == SheetOptionStyle.outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
        ),
        child: Text(option.label),
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
      ),
      child: Text(option.label),
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
