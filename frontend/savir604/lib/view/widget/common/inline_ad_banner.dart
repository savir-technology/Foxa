import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tks/core/functions/commerce_access_guard.dart';
import 'package:tks/data/datasource/model/admodel.dart';
import 'package:tks/data/datasource/remote/ads/ads_data.dart';
import 'package:tks/linkapi/linkapi.dart';
import 'package:video_player/video_player.dart';

class InlineAdBanner extends StatefulWidget {
  final String placement;
  final double height;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? margin;
  final List<AdModel>? ads;
  final bool enableAutoRotate;
  final bool showIndicators;
  final bool overlayIndicators;
  final bool showFrame;
  final bool blendWithBackground;
  final Color? backgroundBlendColor;
  final bool fallbackToGeneralAds;
  final int initialIndex;

  const InlineAdBanner({
    super.key,
    required this.placement,
    this.height = 148,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.margin,
    this.ads,
    this.enableAutoRotate = true,
    this.showIndicators = true,
    this.overlayIndicators = false,
    this.showFrame = true,
    this.blendWithBackground = false,
    this.backgroundBlendColor,
    this.fallbackToGeneralAds = false,
    this.initialIndex = 0,
  });

  @override
  State<InlineAdBanner> createState() => _InlineAdBannerState();
}

class _InlineAdBannerState extends State<InlineAdBanner> {
  final AdsData _adsData = AdsData();
  final PageController _pageController = PageController();
  final List<VideoPlayerController?> _videoControllers = [];

  Timer? _rotationTimer;
  bool _loading = true;
  bool _disposed = false;
  int _currentIndex = 0;
  List<AdModel> _ads = const <AdModel>[];

  @override
  void initState() {
    super.initState();
    if (!AppLink.bannersEnabled) {
      _loading = false;
      return;
    }
    _loadAds();
  }

  @override
  void dispose() {
    _disposed = true;
    _rotationTimer?.cancel();
    _pageController.dispose();
    for (final controller in _videoControllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAds() async {
    final incomingAds = widget.ads;
    var ads = incomingAds ??
        await _adsData.fetchAds(
          placement: widget.placement,
          // Marketing images can be replaced from the Master panel while the
          // app is still open. Do not keep the previous banner list here.
          forceRefresh: true,
        );

    if (ads.isEmpty && widget.fallbackToGeneralAds) {
      ads = await _adsData.fetchAds();
    }

    if (!mounted || _disposed) return;

    final activeAds =
        ads.where((ad) => ad.isActive && ad.mediaUrl.isNotEmpty).toList();
    await _prepareVideoControllers(activeAds);

    if (!mounted || _disposed) return;
    setState(() {
      _ads = activeAds;
      _loading = false;
      _currentIndex =
          activeAds.isEmpty ? 0 : widget.initialIndex % activeAds.length;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _ads.isEmpty || !_pageController.hasClients) return;
      _pageController.jumpToPage(_currentIndex);
    });
    _syncVisibleMedia();
    _scheduleRotation();
  }

  Future<void> _prepareVideoControllers(List<AdModel> ads) async {
    for (final controller in _videoControllers) {
      if (controller != null) {
        await controller.dispose();
      }
    }
    _videoControllers.clear();

    for (final ad in ads) {
      if (!ad.isVideo) {
        _videoControllers.add(null);
        continue;
      }

      try {
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(ad.mediaUrl),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(0);
        if (!mounted || _disposed) {
          await controller.dispose();
          return;
        }
        _videoControllers.add(controller);
      } catch (_) {
        _videoControllers.add(null);
      }
    }
  }

  void _scheduleRotation() {
    _rotationTimer?.cancel();
    if (!widget.enableAutoRotate || _ads.length <= 1) return;

    final seconds = _ads[_currentIndex].displaySeconds.clamp(4, 20).toInt();
    _rotationTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted || !_pageController.hasClients || _ads.length <= 1) return;
      final nextIndex = (_currentIndex + 1) % _ads.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _syncVisibleMedia() {
    for (var i = 0; i < _videoControllers.length; i++) {
      final controller = _videoControllers[i];
      if (controller == null) continue;
      if (i == _currentIndex) {
        controller.play();
      } else {
        controller.pause();
      }
    }
  }

  void _handleTap(AdModel ad) {
    final targetType = ad.normalizedTargetType;

    if (targetType == 'restaurant') {
      final restaurantId = ad.targetIdValue;
      if (restaurantId > 0) {
        unawaited(
          CommerceAccessGuard.openRestaurant(
            restaurantId: restaurantId.toString(),
            parameters: {'restaurant_id': restaurantId.toString()},
          ),
        );
      }
      return;
    }

    if (targetType == 'product' || targetType == 'item') {
      final itemId = ad.targetIdValue;
      if (itemId > 0) {
        unawaited(
          CommerceAccessGuard.openProduct(
            itemId: itemId.toString(),
            parameters: {'item_id': itemId.toString()},
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppLink.bannersEnabled) {
      return const SizedBox.shrink();
    }

    if (_loading || _ads.isEmpty) {
      return const SizedBox.shrink();
    }

    final viewport = Container(
      height: widget.height,
      decoration: widget.showFrame
          ? BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF151515)
                  : const Color(0xFFF6F4EF),
              borderRadius: widget.borderRadius,
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              allowImplicitScrolling: true,
              itemCount: _ads.length,
              onPageChanged: (index) {
                if (!mounted) return;
                setState(() => _currentIndex = index);
                _syncVisibleMedia();
                _scheduleRotation();
              },
              itemBuilder: (context, index) {
                final ad = _ads[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: ad.hasInternalTarget ? () => _handleTap(ad) : null,
                    child: _AdMediaView(
                      ad: ad,
                      controller: _videoControllers[index],
                    ),
                  ),
                );
              },
            ),
            if (widget.blendWithBackground)
              Align(
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: Container(
                    height: widget.height * 0.36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (widget.backgroundBlendColor ??
                                  Theme.of(context).scaffoldBackgroundColor)
                              .withValues(alpha: 0),
                          (widget.backgroundBlendColor ??
                                  Theme.of(context).scaffoldBackgroundColor)
                              .withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.showIndicators &&
                widget.overlayIndicators &&
                _ads.length > 1)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AdIndicators(
                    length: _ads.length,
                    currentIndex: _currentIndex,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: Column(
        children: [
          viewport,
          if (widget.showIndicators &&
              !widget.overlayIndicators &&
              _ads.length > 1) ...[
            const SizedBox(height: 10),
            _AdIndicators(length: _ads.length, currentIndex: _currentIndex),
          ],
        ],
      ),
    );
  }
}

class _AdIndicators extends StatelessWidget {
  const _AdIndicators({required this.length, required this.currentIndex});

  final int length;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(length, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 8,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFFF6500)
                : Colors.white.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _AdMediaView extends StatelessWidget {
  final AdModel ad;
  final VideoPlayerController? controller;

  const _AdMediaView({
    required this.ad,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (ad.isVideo) {
      final videoController = controller;
      if (videoController == null || !videoController.value.isInitialized) {
        return _FallbackAdSurface(title: ad.title);
      }

      final size = videoController.value.size;
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width <= 0 ? 16 : size.width,
            height: size.height <= 0 ? 9 : size.height,
            child: VideoPlayer(videoController),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: ad.mediaUrl,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, __) => _FallbackAdSurface(title: ad.title),
      errorWidget: (_, __, ___) => _FallbackAdSurface(title: ad.title),
    );
  }
}

class _FallbackAdSurface extends StatelessWidget {
  final String title;

  const _FallbackAdSurface({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFE9E9E2),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title.trim().isEmpty ? 'Advertisement' : title,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
