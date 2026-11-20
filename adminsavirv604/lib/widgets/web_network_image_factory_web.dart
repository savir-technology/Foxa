import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

Widget buildAdaptiveNetworkImage({
  required String imageUrl,
  required double? width,
  required double? height,
  required BoxFit fit,
  required Widget fallback,
}) {
  return _HtmlNetworkImage(
    imageUrl: imageUrl,
    width: width,
    height: height,
    fit: fit,
    fallback: fallback,
  );
}

class _HtmlNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget fallback;

  const _HtmlNetworkImage({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.fit,
    required this.fallback,
  });

  @override
  State<_HtmlNetworkImage> createState() => _HtmlNetworkImageState();
}

class _HtmlNetworkImageState extends State<_HtmlNetworkImage> {
  late final String _viewType;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'network-image-${widget.imageUrl.hashCode}-${DateTime.now().microsecondsSinceEpoch}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final image = html.ImageElement()
        ..src = widget.imageUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _toObjectFit(widget.fit)
        ..style.border = '0'
        ..style.padding = '0'
        ..style.margin = '0';

      unawaited(
        image.onError.first.then((_) {
          if (mounted) {
            setState(() => _failed = true);
          }
        }).catchError((_) {}),
      );

      return image;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallback;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: _viewType),
    );
  }

  String _toObjectFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.contain:
        return 'contain';
      case BoxFit.cover:
        return 'cover';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.fitWidth:
        return 'scale-down';
      case BoxFit.fitHeight:
        return 'scale-down';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
    }
  }
}
