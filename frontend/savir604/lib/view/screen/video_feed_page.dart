import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/video/comments_controller.dart';
import 'package:tks/core/class/crud.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/view/screen/comment_page.dart';
import 'package:tks/view/widget/video_item_widget.dart';

import '../../controler/video/video_controller.dart';

class VideoFeedPage extends StatefulWidget {
  final int initialIndex;

  const VideoFeedPage({super.key, this.initialIndex = 0});

  @override
  State<VideoFeedPage> createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<VideoFeedPage> {
  late final VideoController controller;
  late final PageController pageController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(VideoController(Crud()));
    pageController = PageController(initialPage: widget.initialIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.setCurrentIndex(widget.initialIndex);
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        if (controller.videos.isEmpty) {
          return Center(
            child: Text(
              'no_videos_available'.tr,
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }
        return Stack(
          children: [
            PageView.builder(
              controller: pageController,
              scrollDirection: Axis.vertical,
              itemCount: controller.videos.length,
              onPageChanged: controller.setCurrentIndex,
              itemBuilder: (context, index) {
                final video = controller.videos[index];
                return VideoItemWidget(
                  video: video,
                  controller: controller,
                  isActive: controller.currentIndex.value == index,
                  onOpenComments: () {
                    final int currentUserId =
                        Get.find<MyServices>().sharedPreferences.getInt('id') ??
                            0;
                    Get.bottomSheet(
                      CommentsPage(videoId: video.videoId, userId: currentUserId),
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                    ).whenComplete(() {
                      try {
                        Get.delete<CommentsController>(
                          tag: 'comments_${video.videoId}',
                        );
                      } catch (_) {}
                    });
                  },
                );
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 150,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xAA000000), Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
