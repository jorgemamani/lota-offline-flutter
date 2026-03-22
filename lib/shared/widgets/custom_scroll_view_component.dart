import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';

class CustomScrollViewComponent extends StatefulWidget {
  final ScrollController? controller;
  final List<Widget> topChildren;
  final List<Widget> bottomChildren;

  /// Slivers personalizados
  /// Start slivers (por arrriba del SliverToBoxAdapter (topChildren))
  /// Medium slivers (por debajo del SliverToBoxAdapter (topChildren))
  /// End slivers (por debajo del SliverFillRemaining (bottomChildren))
  final List<Widget> startSlivers;
  final List<Widget> mediumSlivers;
  final List<Widget> endSlivers;

  // Opcional: agregar padding por defecto al top
  final bool addDefaultPaddingTop;

  // Parámetros para el Column Top
  final MainAxisAlignment topMainAxisAlignment;
  final CrossAxisAlignment topCrossAxisAlignment;
  final MainAxisSize topMainAxisSize;
  final VerticalDirection topVerticalDirection;

  // Parámetros para el Column Bottom
  final MainAxisAlignment bottomMainAxisAlignment;
  final CrossAxisAlignment bottomCrossAxisAlignment;
  final MainAxisSize bottomMainAxisSize;
  final VerticalDirection bottomVerticalDirection;

  // Opcional: padding para cada sección
  final EdgeInsetsGeometry? topPadding;
  final EdgeInsetsGeometry? bottomPadding;

  // Opcional: espaciado entre widgets bottom
  final double bottomSpacingStart;
  final double bottomSpacingEnd;

  const CustomScrollViewComponent({
    super.key,
    this.controller,
    this.topChildren = const [],
    this.bottomChildren = const [],
    // Slivers personalizados
    this.startSlivers = const [],
    this.mediumSlivers = const [],
    this.endSlivers = const [],
    // Opcional: agregar padding por defecto al top
    this.addDefaultPaddingTop = false,
    // Valores por defecto para Column Top
    this.topMainAxisAlignment = MainAxisAlignment.start,
    this.topCrossAxisAlignment = CrossAxisAlignment.center,
    this.topMainAxisSize = MainAxisSize.max,
    this.topVerticalDirection = VerticalDirection.down,
    // Valores por defecto para Column Bottom
    this.bottomMainAxisAlignment = MainAxisAlignment.end, // No default
    this.bottomCrossAxisAlignment = CrossAxisAlignment.center,
    this.bottomMainAxisSize = MainAxisSize.min, // No default
    this.bottomVerticalDirection = VerticalDirection.down,
    // Opcionales
    this.topPadding,
    this.bottomPadding,
    this.bottomSpacingStart = 25,
    this.bottomSpacingEnd = 25,
  });

  @override
  State<CustomScrollViewComponent> createState() =>
      _CustomScrollViewComponentState();
}

class _CustomScrollViewComponentState extends State<CustomScrollViewComponent> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: widget.controller,
      slivers: [
        // Start slivers (antes del SliverToBoxAdapter)
        ...widget.startSlivers,
        SliverToBoxAdapter(
          child: Padding(
            padding: widget.topPadding ?? EdgeInsets.zero,
            child: Column(
              mainAxisAlignment: widget.topMainAxisAlignment,
              crossAxisAlignment: widget.topCrossAxisAlignment,
              mainAxisSize: widget.topMainAxisSize,
              verticalDirection: widget.topVerticalDirection,
              children: [
                if (widget.addDefaultPaddingTop) ...[
                  AppSizes.defaultTopPadding,
                ],
                ...widget.topChildren,
              ],
            ),
          ),
        ),
        // Medium slivers (después del SliverToBoxAdapter)
        ...widget.mediumSlivers,
        if (widget.bottomChildren.isNotEmpty) ...[
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: widget.bottomPadding ?? EdgeInsets.zero,
              child: Column(
                mainAxisAlignment: widget.bottomMainAxisAlignment,
                crossAxisAlignment: widget.bottomCrossAxisAlignment,
                mainAxisSize: widget.bottomMainAxisSize,
                verticalDirection: widget.bottomVerticalDirection,
                children: [
                  Expanded(
                    child: SizedBox(height: widget.bottomSpacingStart),
                  ),
                  ...widget.bottomChildren,
                  SizedBox(height: widget.bottomSpacingEnd),
                ],
              ),
            ),
          ),
        ],
        // End slivers (después del SliverFillRemaining)
        ...widget.endSlivers,
      ],
    );
  }
}
