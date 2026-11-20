// lib/controler/video/video_controller.dart
import 'package:get/get.dart';
import 'package:tks/core/functions/app_video_urls.dart';
import 'package:tks/data/datasource/model/video_model.dart';
import 'package:tks/data/datasource/remote/video/video_remote.dart';
import 'package:video_player/video_player.dart';
import 'package:tks/core/class/crud.dart';

class VideoController extends GetxController {
  final Crud crud;
  late final VideoRemote remote;

  VideoController(this.crud) {
    remote = VideoRemote(crud);
  }

  var videos = <VideoModel>[].obs;
  var isLoading = false.obs;
  var currentIndex = 0.obs;
  final failedVideoIds = <int>{}.obs;

  // store controllers per video
  final Map<int, VideoPlayerController> _playerMap = {};
  final Map<int, String> _resolvedVideoUrls = {};

  VideoPlayerController? getController(int videoId) => _playerMap[videoId];

  String? getResolvedVideoUrl(int videoId) => _resolvedVideoUrls[videoId];

  @override
  void onInit() {
    super.onInit();
    fetchVideos();
  }

  @override
  void onClose() {
    for (var c in _playerMap.values) {
      try {
        c.dispose();
      } catch (_) {}
    }
    super.onClose();
  }

  Future<void> fetchVideos() async {
    isLoading.value = true;
    try {
      var list = await remote.fetchVideos();
      videos.assignAll(list);
    } catch (e) {
      print("fetchVideos error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> initVideoPlayer(VideoModel video) async {
    if (_playerMap.containsKey(video.videoId)) return;
    final candidates = AppVideoUrls.candidates(video.videoUrl);

    if (candidates.isEmpty) {
      failedVideoIds.add(video.videoId);
      return;
    }

    _resolvedVideoUrls[video.videoId] = candidates.first;

    for (final candidate in candidates) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(candidate));
      _playerMap[video.videoId] = controller;
      try {
        await controller.initialize();
        await controller.setLooping(true);
        failedVideoIds.remove(video.videoId);
        _resolvedVideoUrls[video.videoId] = candidate;
        return;
      } catch (e) {
        try {
          await controller.dispose();
        } catch (_) {}
        _playerMap.remove(video.videoId);
        print("initVideoPlayer candidate failed for $candidate: $e");
      }
    }

    failedVideoIds.add(video.videoId);
    print("initVideoPlayer error for ${video.videoUrl}: all candidates failed");
  }

  void play(int videoId) {
    var c = _playerMap[videoId];
    if (c == null) return;
    c.play();
  }

  void pause(int videoId) {
    var c = _playerMap[videoId];
    if (c == null) return;
    c.pause();
  }

  void pauseAll() {
    for (final controller in _playerMap.values) {
      try {
        controller.pause();
      } catch (_) {}
    }
  }

  void setCurrentIndex(int index) {
    currentIndex.value = index;
    pauseAll();
    if (index >= 0 && index < videos.length) {
      final current = videos[index];
      play(current.videoId);
    }
  }

  Future<void> toggleLike(VideoModel video, int userId) async {
    try {
      var res = await remote.addLike(videoId: video.videoId, userId: userId);
      if (res['status'] == 'success') {
        // action maybe 'liked' or 'unliked'
        if (res['action'] == 'liked') {
          video.videoLikes += 1;
        } else {
          video.videoLikes = (video.videoLikes - 1).clamp(0, 99999999);
        }
        videos.refresh();
      } else {
        final msg = res['message'] ?? 'فشل إجراء الإعجاب';
        Get.snackbar('خطأ', msg);
      }
    } catch (e) {
      print("toggleLike error $e");
    }
  }

  Future<void> markView(VideoModel video, int? userId) async {
    try {
      await remote.increaseView(videoId: video.videoId, userId: userId);
      video.videoViews += 1;
      videos.refresh();
    } catch (e) {
      print("markView error $e");
    }
  }
}
