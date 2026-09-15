import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth = 180,
    this.memCacheHeight = 180,
    this.maxWidthDiskCache = 300,
    this.maxHeightDiskCache = 300,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFF8F9FA),
        child: errorWidget ?? const Icon(Icons.celebration, color: Color(0xFFFF8C00)),
      );
    }

    final bool isSvg = imageUrl.toLowerCase().contains('.svg');
    if (isSvg) {
      return SvgPicture.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        placeholderBuilder: placeholder != null ? (ctx) => placeholder! : null,
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: maxWidthDiskCache,
      maxHeightDiskCache: maxHeightDiskCache,
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 150),
      placeholder: placeholder != null
          ? (ctx, url) => placeholder!
          : (context, url) => Container(color: const Color(0xFFF3F4F6)),
      errorWidget: errorWidget != null
          ? (ctx, url, err) => errorWidget!
          : (context, url, error) => const Icon(Icons.celebration, color: Color(0xFFFF8C00)),
    );
  }
}
