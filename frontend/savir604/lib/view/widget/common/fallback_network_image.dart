import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FallbackNetworkImage extends StatefulWidget {
  final List<String> imageUrls;
  final String? label;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const FallbackNetworkImage({
    super.key,
    required this.imageUrls,
    this.label,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<FallbackNetworkImage> createState() => _FallbackNetworkImageState();
}

class _FallbackNetworkImageState extends State<FallbackNetworkImage> {
  int _currentIndex = 0;

  @override
  void didUpdateWidget(covariant FallbackNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameUrls(oldWidget.imageUrls, widget.imageUrls)) {
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return _buildError();
    }

    final currentUrl = widget.imageUrls[_currentIndex];

    return CachedNetworkImage(
      imageUrl: currentUrl,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      memCacheWidth: widget.width?.isFinite == true
          ? (widget.width! * MediaQuery.of(context).devicePixelRatio).round()
          : null,
      memCacheHeight: widget.height?.isFinite == true
          ? (widget.height! * MediaQuery.of(context).devicePixelRatio).round()
          : null,
      placeholder: (context, _) => widget.placeholder ?? _buildLoading(),
      errorWidget: (context, error, stackTrace) {
        if (_currentIndex < widget.imageUrls.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _currentIndex += 1);
            }
          });
          return widget.placeholder ?? _buildLoading();
        }
        return _buildError();
      },
    );
  }

  Widget _buildLoading() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildError() {
    return widget.errorWidget ??
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF6FBFB),
                  Color(0xFFE8F4F3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: _FallbackPlaceholder(label: widget.label),
          ),
        );
  }

  bool _sameUrls(List<String> first, List<String> second) {
    if (identical(first, second)) return true;
    if (first.length != second.length) return false;
    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }
    return true;
  }
}

class _FallbackPlaceholder extends StatelessWidget {
  final String? label;

  const _FallbackPlaceholder({this.label});

  @override
  Widget build(BuildContext context) {
    final display = (label ?? '').trim();
    final initials = display.isEmpty
        ? 'IMG'
        : display
            .split(RegExp(r'\s+'))
            .where((e) => e.isNotEmpty)
            .take(2)
            .map((e) => e.substring(0, 1).toUpperCase())
            .join();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTiny = constraints.maxHeight < 90 || constraints.maxWidth < 90;
        final avatarSize = isTiny ? 32.0 : 54.0;
        final gap = isTiny ? 6.0 : 10.0;

        return Padding(
          padding: EdgeInsets.all(isTiny ? 6 : 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF151515).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF151515),
                        fontWeight: FontWeight.w800,
                        fontSize: isTiny ? 14 : null,
                      ),
                ),
              ),
              SizedBox(height: gap),
              if (!isTiny)
                Text(
                  display.isEmpty ? 'Image unavailable' : display,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF151515).withValues(alpha: 0.70),
                        fontWeight: FontWeight.w600,
                      ),
                ),
            ],
          ),
        );
      },
    );
  }
}
