import 'package:admin_tks/widgets/web_network_image_factory.dart'
    if (dart.library.html) 'package:admin_tks/widgets/web_network_image_factory_web.dart'
    as web_image;
import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.image,
    this.errorReplacement,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;
  final Widget? errorReplacement;

  @override
  Widget build(BuildContext context) {
    final image = web_image.buildAdaptiveNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fallback: errorReplacement ?? _fallback(context),
    );

    if (borderRadius == null) {
      return image;
    }

    return ClipRRect(
      borderRadius: borderRadius!,
      child: image,
    );
  }

  Widget _fallback(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      height: height,
      color: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
      alignment: Alignment.center,
      child: Icon(
        placeholderIcon,
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ??
            Colors.grey,
      ),
    );
  }
}
