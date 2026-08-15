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

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
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
      placeholder: placeholder != null ? (ctx, url) => placeholder! : (context, url) => Container(color: Colors.grey[200]),
      errorWidget: errorWidget != null ? (ctx, url, err) => errorWidget! : (context, url, error) => const Icon(Icons.celebration, color: Color(0xFFFF8C00)),
    );
  }
}
