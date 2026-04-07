import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Envuelve el contenido de un modal bottom sheet para que sea desplazable
/// cuando el texto crece (p. ej. tamaño de fuente del sistema en Android)
/// o el contenido no cabe en pantalla.
///
/// [fixedHeader] queda fijo arriba (p. ej. la línea tipo “drag handle”);
/// solo [child] hace scroll debajo. El sheet mantiene altura ajustada al
/// contenido cuando cabe, sin relleno vacío debajo.
class ScrollableBottomSheetBody extends StatefulWidget {
  const ScrollableBottomSheetBody({
    super.key,
    required this.child,
    this.fixedHeader,
    this.maxHeightFraction = 0.92,
  });

  final Widget child;

  /// Widget que no se mueve al hacer scroll (típicamente el handle).
  final Widget? fixedHeader;

  /// Tope si el padre no impone altura máxima (p. ej. sheet sin scroll control).
  final double maxHeightFraction;

  @override
  State<ScrollableBottomSheetBody> createState() =>
      _ScrollableBottomSheetBodyState();
}

class _ScrollableBottomSheetBodyState extends State<ScrollableBottomSheetBody> {
  final GlobalKey _headerKey = GlobalKey();

  /// Primera estimación hasta medir el header real tras el primer layout.
  double _headerHeight = 52;

  static const ScrollPhysics _scrollPhysics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  @override
  void initState() {
    super.initState();
    if (widget.fixedHeader != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
    }
  }

  @override
  void didUpdateWidget(ScrollableBottomSheetBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fixedHeader != oldWidget.fixedHeader) {
      _headerHeight = 52;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
    }
  }

  void _measureHeader() {
    if (!mounted) return;
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final h = box.size.height;
    if ((h - _headerHeight).abs() > 0.5) {
      setState(() => _headerHeight = h);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaHeight = MediaQuery.sizeOf(context).height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight < double.infinity
            ? constraints.maxHeight
            : mediaHeight * widget.maxHeightFraction;

        if (widget.fixedHeader == null) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: _scrollPhysics,
              child: widget.child,
            ),
          );
        }

        final scrollMax =
            math.max(1.0, math.max(0.0, maxH - _headerHeight));

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NotificationListener<SizeChangedLayoutNotification>(
                onNotification: (_) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _measureHeader());
                  return false;
                },
                child: SizeChangedLayoutNotifier(
                  child: KeyedSubtree(
                    key: _headerKey,
                    child: widget.fixedHeader!,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: scrollMax),
                child: ListView(
                  shrinkWrap: true,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: _scrollPhysics,
                  children: [widget.child],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
