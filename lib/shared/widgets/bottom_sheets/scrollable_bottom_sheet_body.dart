import 'package:flutter/material.dart';

/// Envuelve el contenido de un modal bottom sheet para que sea desplazable
/// cuando el texto crece (p. ej. tamaño de fuente del sistema en Android)
/// o el contenido no cabe en pantalla.
class ScrollableBottomSheetBody extends StatelessWidget {
  const ScrollableBottomSheetBody({
    super.key,
    required this.child,
    this.maxHeightFraction = 0.92,
  });

  final Widget child;

  /// Tope si el padre no impone altura máxima (p. ej. sheet sin scroll control).
  final double maxHeightFraction;

  @override
  Widget build(BuildContext context) {
    final mediaHeight = MediaQuery.sizeOf(context).height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight < double.infinity
            ? constraints.maxHeight
            : mediaHeight * maxHeightFraction;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
