import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/core/functions/commerce_access_guard.dart';
import 'package:tks/data/datasource/model/aleppo_home_model.dart';
import 'package:tks/linkapi/linkapi.dart';
import 'package:video_player/video_player.dart';

class StoryViewerPage extends StatefulWidget {
  const StoryViewerPage({super.key, required this.story});

  final AleppoHomeStoryModel story;

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage> {
  VideoPlayerController? _videoController;
  bool _loadingVideo = false;
  bool _videoFailed = false;

  bool get _canPlayVideo {
    final story = widget.story;
    return story.mediaType.trim().toLowerCase() == 'video' &&
        story.videoUrl.trim().isNotEmpty;
  }

  void _openStoryTarget() {
    final story = widget.story;
    if (!story.hasInternalTarget) {
      return;
    }

    final targetId = story.resolvedTargetId;
    final targetType = story.normalizedTargetType;

    if (targetType == 'restaurant') {
      unawaited(
        CommerceAccessGuard.openRestaurant(
          restaurantId: targetId.toString(),
          arguments: {'restaurant_id': targetId.toString()},
          parameters: {'restaurant_id': targetId.toString()},
        ),
      );
      return;
    }

    if (targetType == 'product') {
      unawaited(
        CommerceAccessGuard.openProduct(
          itemId: targetId.toString(),
          arguments: {'item_id': targetId.toString()},
          parameters: {'item_id': targetId.toString()},
        ),
      );
    }
  }

  String _ctaLabel(bool isArabic) {
    final story = widget.story;
    final explicit = isArabic ? story.ctaLabelAr.trim() : story.ctaLabelEn.trim();
    if (explicit.isNotEmpty) {
      return explicit;
    }

    if (story.normalizedTargetType == 'product') {
      return isArabic ? 'الانتقال إلى المنتج' : 'Open product';
    }

    return isArabic ? 'الانتقال إلى المطعم' : 'Open restaurant';
  }

  IconData _ctaIcon() {
    return widget.story.normalizedTargetType == 'product'
        ? Icons.shopping_bag_outlined
        : Icons.storefront_outlined;
  }

  @override
  void initState() {
    super.initState();
    if (_canPlayVideo) {
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _loadingVideo = true;
      _videoFailed = false;
    });

    final url = AppLink.normalizeUrl(widget.story.videoUrl);
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingVideo = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingVideo = false;
        _videoFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final isArabic = Get.locale?.languageCode == 'ar';
    final title = isArabic ? story.titleAr.trim() : story.titleEn.trim();
    final fallbackTitle = title.isNotEmpty ? title : (isArabic ? 'القصة' : 'Story');
    final imageUrl = story.imageUrl.trim();
    final showVideo = _canPlayVideo && !_videoFailed;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showVideo &&
                _videoController != null &&
                _videoController!.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else if (imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: AppLink.normalizeUrl(imageUrl),
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: const Color(0xFF111111)),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFF111111),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white54,
                    size: 42,
                  ),
                ),
              )
            else
              Container(
                color: const Color(0xFF111111),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white54,
                  size: 42,
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.62),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _CircleButton(
                          icon: Icons.close_rounded,
                          onTap: Get.back,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fallbackTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (story.hasInternalTarget) ...[
                      FilledButton.icon(
                        onPressed: _openStoryTarget,
                        icon: Icon(_ctaIcon()),
                        label: Text(_ctaLabel(isArabic)),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_loadingVideo)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
