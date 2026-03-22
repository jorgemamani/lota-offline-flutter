// ignore_for_file: must_be_immutable, no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerComponent extends StatelessWidget {
  Widget? child;
  List<Widget>? children;
  Color? baseColor;
  Color? highlightColor;
  Gradient? gradient;
  CrossAxisAlignment? crossAxisAlignment;
  MainAxisAlignment? mainAxisAlignment;

  ShimmerComponent({
    super.key,
    this.child,
    this.baseColor,
    this.highlightColor,
    this.gradient,
  });

  ShimmerComponent.list({
    super.key,
    this.children,
    this.baseColor,
    this.highlightColor,
    this.gradient,
    this.crossAxisAlignment,
    this.mainAxisAlignment,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color _baseColor = baseColor ?? colorScheme.surfaceContainerHighest;
    Color _highlightColor = highlightColor ?? colorScheme.surfaceContainerLow;
    return Shimmer(
      gradient: gradient ??
          LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              _baseColor,
              _baseColor,
              _highlightColor,
              _baseColor,
              _baseColor,
            ],
            stops: const <double>[0.0, 0.35, 0.5, 0.65, 1.0],
          ),
      direction: ShimmerDirection.ltr,
      period: const Duration(milliseconds: 750),
      child: children != null
          ? SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (details) {},
                onVerticalDragUpdate: (details) {},
                onVerticalDragEnd: (details) {},
                child: AbsorbPointer(
                  child: Column(
                    crossAxisAlignment:
                        crossAxisAlignment ?? CrossAxisAlignment.start,
                    mainAxisAlignment:
                        mainAxisAlignment ?? MainAxisAlignment.start,
                    children: children!,
                  ),
                ),
              ),
            )
          : child ?? const SizedBox.shrink(),
    );
  }
}

class ShimmerFormComponent extends StatelessWidget {
  final double? height;
  final double? width;
  final double radius;
  final BoxConstraints? constraints;
  const ShimmerFormComponent({
    super.key,
    this.height,
    this.width,
    this.radius = 0,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      constraints: constraints,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
