import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/constants/carton_display_scale.dart';
import '../cubit/carton_display_scale_cubit.dart';

/// Bottom sheet para ajustar el tamaño de los números en los cartones.
///
/// El estado vive en [CartonDisplayScaleCubit] y se persiste entre sesiones.
class CartonDisplayScaleSheet {
  CartonDisplayScaleSheet._();

  static const _maxStep = CartonDisplayScale.stepCount - 1;

  static Future<void> show(BuildContext context) {
    final theme = Theme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: BlocBuilder<CartonDisplayScaleCubit, int>(
              builder: (context, step) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tamaño de los números',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Se aplica a todos los cartones en la lista y durante el '
                      'juego. La preferencia se guarda automáticamente.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      label: 'Tamaño de los números del cartón',
                      child: Slider(
                        value: step.toDouble(),
                        min: 0,
                        max: _maxStep.toDouble(),
                        divisions: _maxStep,
                        label: CartonDisplayScale.label(step),
                        onChanged: (v) {
                          context
                              .read<CartonDisplayScaleCubit>()
                              .setStep(v.round());
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.text_fields_rounded,
                            size: 18,
                            color: theme.colorScheme.outline,
                          ),
                          const Spacer(),
                          Text(
                            CartonDisplayScale.label(step),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.text_fields_rounded,
                            size: 26,
                            color: theme.colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
