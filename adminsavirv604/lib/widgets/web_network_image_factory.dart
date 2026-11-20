import 'package:flutter/material.dart';

Widget buildAdaptiveNetworkImage({
  required String imageUrl,
  required double? width,
  required double? height,
  required BoxFit fit,
  required Widget fallback,
}) {
  return Image.network(
    imageUrl,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => fallback,
    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
      if (wasSynchronouslyLoaded || frame != null) {
        return child;
      }

      return SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    },
  );
}
