import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/functions_utils.dart';
import 'image_component/image_element_stub.dart'
    if (dart.library.html) 'image_component/image_element_web.dart';
import 'shimmer_component.dart';

class ImageComponent extends StatefulWidget {
  final double? height;
  final double? width;
  final String imagePath;
  final String? errorImagePath;
  final Widget? errorWidget;
  final BoxFit fit;
  final bool showShimmer;
  /// Tinte para assets locales (raster o SVG). Útil para iconos monocromáticos.
  final Color? color;

  const ImageComponent({
    super.key,
    this.height,
    this.width,
    required this.imagePath,
    this.errorImagePath,
    this.errorWidget,
    this.fit = BoxFit.contain,
    this.showShimmer = false,
    this.color,
  });

  @override
  State<ImageComponent> createState() => _ImageComponentState();
}

class _ImageComponentState extends State<ImageComponent> {
  bool get isLocalImage =>
      widget.imagePath.toLowerCase().trim().startsWith('assets/');

  bool isSvg({
    required String? imagePath,
  }) {
    return isNotNullAndNotEmpty(text: imagePath) &&
            imagePath!.toLowerCase().trim().endsWith('.svg') ||
        imagePath!.toLowerCase().trim().endsWith('.svgz');
  }

  @override
  Widget build(BuildContext context) {
    if (isLocalImage) {
      return _buildLocalImage();
    } else {
      return _buildNetworkImage();
    }
  }

  Widget _buildLocalImage() {
    if (isSvg(imagePath: widget.imagePath)) {
      return SvgPicture.asset(
        widget.imagePath,
        height: widget.height,
        width: widget.width,
        fit: widget.fit,
        colorFilter: widget.color != null
            ? ColorFilter.mode(widget.color!, BlendMode.srcIn)
            : null,
        placeholderBuilder: (context) => _buildShimmer(),
      );
    } else {
      return Image.asset(
        widget.imagePath,
        height: widget.height,
        width: widget.width,
        fit: widget.fit,
        color: widget.color,
        colorBlendMode:
            widget.color != null ? BlendMode.srcIn : null,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }
  }

  Widget _buildNetworkImage() {
    if (kIsWeb) {
      if (widget.showShimmer) {
        return _buildShimmer();
      }
      // Usa la ruta actual como identificador único para el view nativo web.
      final routeName =
          ModalRoute.of(context)?.settings.name ?? widget.imagePath.hashCode.toString();
      final webWidget = buildWebNativeImage(
        imageUrl: widget.imagePath,
        routeName: routeName,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorWidget: _buildErrorWidget(),
      );
      if (webWidget != null) return webWidget;
    }

    Widget network = CachedNetworkImage(
      imageUrl: widget.imagePath,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (context, url) => _buildShimmer(),
      errorWidget: (context, url, error) =>
          widget.showShimmer ? _buildShimmer() : _buildErrorWidget(),
    );
    if (widget.color != null) {
      network = ColorFiltered(
        colorFilter: ColorFilter.mode(widget.color!, BlendMode.srcIn),
        child: network,
      );
    }
    return network;
  }

  Widget _buildShimmer() {
    return ShimmerComponent(
      child: ShimmerFormComponent(
        height: widget.height,
        width: widget.width,
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }
    if (isNotNullAndNotEmpty(text: widget.errorImagePath)) {
      if (isSvg(imagePath: widget.errorImagePath)) {
        return SvgPicture.asset(
          widget.errorImagePath!,
          height: widget.height,
          width: widget.width,
          fit: widget.fit,
        );
      } else {
        return Image.asset(
          widget.errorImagePath!,
          height: widget.height,
          width: widget.width,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) => _defaultErrorIcon(),
        );
      }
    }
    return _defaultErrorIcon();
  }

  Widget _defaultErrorIcon() {
    return Icon(
      Icons.image_not_supported_outlined,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      size: widget.height,
    );
  }
}
