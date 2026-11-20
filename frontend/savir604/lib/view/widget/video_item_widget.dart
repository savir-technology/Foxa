import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/core/functions/commerce_access_guard.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/model/video_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../controler/video/video_controller.dart';

class VideoItemWidget extends StatefulWidget {
  final VideoModel video;
  final VideoController controller;
  final VoidCallback onOpenComments;
  final bool isActive;

  const VideoItemWidget({
    super.key,
    required this.video,
    required this.controller,
    required this.onOpenComments,
    required this.isActive,
  });

  @override
  State<VideoItemWidget> createState() => _VideoItemWidgetState();
}

class _VideoItemWidgetState extends State<VideoItemWidget>
    with WidgetsBindingObserver {
  VideoPlayerController? _vc;
  bool _videoFailed = false;
  bool _showPauseIcon = false;
  late final int currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    currentUserId = Get.find<MyServices>().sharedPreferences.getInt('id') ?? 0;
    _init();
  }

  @override
  void didUpdateWidget(covariant VideoItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _vc?.play();
      } else {
        _vc?.pause();
      }
    }
  }

  Future<void> _init() async {
    try {
      await widget.controller.initVideoPlayer(widget.video);
      _vc = widget.controller.getController(widget.video.videoId);

      if (_vc != null && _vc!.value.isInitialized) {
        if (!mounted) return;
        setState(() {
          _videoFailed = false;
        });
        if (widget.isActive) {
          _vc!.play();
          widget.controller.markView(widget.video, currentUserId);
        }
      } else {
        if (!mounted) return;
        setState(() {
          _videoFailed =
              widget.controller.failedVideoIds.contains(widget.video.videoId);
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _videoFailed = true;
      });
    }
  }

  void _togglePlayback() {
    if (_vc == null || _videoFailed) return;
    if (_vc!.value.isPlaying) {
      _vc!.pause();
      setState(() {
        _showPauseIcon = true;
      });
    } else {
      _vc!.play();
      setState(() {
        _showPauseIcon = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_vc == null || _videoFailed) return;
    if (state == AppLifecycleState.paused) {
      _vc!.pause();
    } else if (state == AppLifecycleState.resumed && widget.isActive) {
      _vc!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.locale?.languageCode == 'ar';
    final title = (widget.video.videoTitle?.trim().isNotEmpty == true)
        ? widget.video.videoTitle!.trim()
        : (widget.video.productNameAr?.trim().isNotEmpty == true)
            ? widget.video.productNameAr!.trim()
            : 'savir_collection'.tr;
    final subtitle = (widget.video.videoDesc?.trim().isNotEmpty == true)
        ? widget.video.videoDesc!.trim()
        : 'video_fallback_subtitle'.tr;
    final targetLabel = _targetButtonLabel(isArabic);
    final targetIcon = _targetButtonIcon();

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: _togglePlayback,
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(child: _buildMedia()),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0x88000000),
                        Colors.transparent,
                        Color(0xB3000000),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.38, 1.0],
                    ),
                  ),
                ),
              ],
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
                    _TopCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: Get.back,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'live_virtual_try_on'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '@${(widget.video.uploaderName ?? 'Everyglare').replaceAll(' ', '').toLowerCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.76),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _TopCircleButton(
                      icon: Icons.favorite_border_rounded,
                      onTap: () => widget.controller
                          .toggleLike(widget.video, currentUserId),
                    ),
                    const SizedBox(width: 8),
                    _TopCircleButton(
                      icon: Icons.home_outlined,
                      onTap: () => Get.offAllNamed(AppRoutes.homepage),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _VideoDetailsCard(
                        video: widget.video,
                        title: title,
                        subtitle: subtitle,
                        hasTarget: widget.video.hasInternalTarget,
                        targetLabel: targetLabel,
                        targetIcon: targetIcon,
                        onOpenTarget: _openVideoTarget,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _VideoActionsRail(
                      video: widget.video,
                      controller: widget.controller,
                      onOpenComments: widget.onOpenComments,
                      currentUserId: currentUserId,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _CommentPromptBar(onTap: widget.onOpenComments),
              ],
            ),
          ),
        ),
        IgnorePointer(
          ignoring: !_showPauseIcon,
          child: AnimatedOpacity(
            opacity: _showPauseIcon ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: Center(
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openVideoTarget() {
    final targetType = widget.video.normalizedTargetType;
    final targetId = widget.video.resolvedTargetId;
    if (targetType == null || targetId <= 0) {
      return;
    }

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

  String _targetButtonLabel(bool isArabic) {
    final targetType = widget.video.normalizedTargetType;
    if (targetType == 'product') {
      return isArabic ? 'عرض المنتج' : 'Open product';
    }

    return isArabic ? 'عرض المطعم' : 'Open restaurant';
  }

  IconData _targetButtonIcon() {
    return widget.video.normalizedTargetType == 'product'
        ? Icons.shopping_bag_outlined
        : Icons.storefront_outlined;
  }

  Widget _buildMedia() {
    if (_videoFailed) {
      final fallbackUrl =
          widget.controller.getResolvedVideoUrl(widget.video.videoId) ??
              widget.video.videoUrl;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.video_file_outlined,
              size: 64,
              color: Colors.white70,
            ),
            const SizedBox(height: 12),
            Text(
              'video_inline_not_supported'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (kIsWeb)
              FilledButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(fallbackUrl);
                  await launchUrl(uri, webOnlyWindowName: '_blank');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.open_in_new),
                label: Text('open_video'.tr),
              )
            else
              Text(
                fallbackUrl,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      );
    }

    if (_vc != null && _vc!.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _vc!.value.size.width,
          height: _vc!.value.size.height,
          child: VideoPlayer(_vc!),
        ),
      );
    }

    if (widget.video.videoThumbnail != null &&
        widget.video.videoThumbnail!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.video.videoThumbnail!,
        fit: BoxFit.cover,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: Colors.white),
        const SizedBox(height: 12),
        Text(
          'loading_video'.tr,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF121212), size: 20),
      ),
    );
  }
}

class _VideoDetailsCard extends StatelessWidget {
  final VideoModel video;
  final String title;
  final String subtitle;
  final bool hasTarget;
  final String targetLabel;
  final IconData targetIcon;
  final VoidCallback onOpenTarget;

  const _VideoDetailsCard({
    required this.video,
    required this.title,
    required this.subtitle,
    required this.hasTarget,
    required this.targetLabel,
    required this.targetIcon,
    required this.onOpenTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.uploaderName?.trim().isNotEmpty == true
                          ? video.uploaderName!
                          : 'Savir Studio',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              height: 1.4,
              fontSize: 13,
            ),
          ),
          if (hasTarget) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpenTarget,
                icon: Icon(targetIcon, size: 18),
                label: Text(targetLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF121212),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VideoActionsRail extends StatelessWidget {
  final VideoModel video;
  final VideoController controller;
  final VoidCallback onOpenComments;
  final int currentUserId;

  const _VideoActionsRail({
    required this.video,
    required this.controller,
    required this.onOpenComments,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current =
          controller.videos.firstWhere((e) => e.videoId == video.videoId);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RailAction(
            icon: Icons.favorite_rounded,
            count: _compactCount(current.videoLikes),
            onTap: () => controller.toggleLike(current, currentUserId),
          ),
          const SizedBox(height: 12),
          _RailAction(
            icon: Icons.chat_bubble_outline_rounded,
            count: _compactCount(current.videoViews),
            onTap: onOpenComments,
          ),
        ],
      );
    });
  }
}

class _RailAction extends StatelessWidget {
  final IconData icon;
  final String count;
  final VoidCallback onTap;

  const _RailAction({
    required this.icon,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF121212), size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentPromptBar extends StatelessWidget {
  final VoidCallback onTap;

  const _CommentPromptBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'leave_your_comment'.tr,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.alternate_email_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

String _compactCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
  }
  return '$value';
}
