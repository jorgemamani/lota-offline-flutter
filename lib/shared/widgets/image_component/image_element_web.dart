import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:universal_html/html.dart' as html;

final Set<String> _registeredViews = {};

Widget? buildWebNativeImage({
  required String imageUrl,
  required String routeName,
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
  Widget? errorWidget,
}) {
  if (imageUrl.isEmpty) {
    return SizedBox(
      width: width,
      height: height,
      child: errorWidget ?? const SizedBox.shrink(),
    );
  }

  return _WebNativeImage(
    imageUrl: imageUrl,
    routeName: routeName,
    width: width,
    height: height,
    fit: fit,
    errorWidget: errorWidget,
  );
}

class _WebNativeImage extends StatefulWidget {
  final String imageUrl;
  final String routeName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;

  const _WebNativeImage({
    required this.imageUrl,
    required this.routeName,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorWidget,
  });

  @override
  State<_WebNativeImage> createState() => _WebNativeImageState();
}

class _WebNativeImageState extends State<_WebNativeImage> {
  bool _hasError = false;
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'web-img-${widget.routeName}${widget.imageUrl.hashCode}';

    if (!_registeredViews.contains(_viewId)) {
      _registeredViews.add(_viewId);

      final imgElement = html.ImageElement()
        ..src = widget.imageUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _boxFitToCss(widget.fit)
        ..style.pointerEvents = 'none';

      imgElement.onError.listen((_) {
        if (mounted) setState(() => _hasError = true);
      });

      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int id) => imgElement,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.errorWidget ?? const SizedBox.shrink(),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(
        viewType: _viewId,
        hitTestBehavior: PlatformViewHitTestBehavior.transparent,
      ),
    );
  }
}

String _boxFitToCss(BoxFit fit) {
  switch (fit) {
    case BoxFit.cover:
      return 'cover';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
    case BoxFit.contain:
    case BoxFit.fitWidth:
    case BoxFit.fitHeight:
      return 'contain';
  }
}
