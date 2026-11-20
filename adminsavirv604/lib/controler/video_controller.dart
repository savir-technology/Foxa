import 'dart:convert' as convert;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class VideoController extends GetxController {
  PlatformFile? selectedVideoFile;
  Uint8List? selectedVideoBytes;

  var isLoading = false.obs;
  var uploadProgress = 0.0.obs;
  var videos = <Map<String, dynamic>>[].obs;
  var lastUploadedVideoUrl = RxnString();
  var lastUploadedVideoTitle = RxnString();
  final TextEditingController targetIdController = TextEditingController();
  final RxString targetType = 'restaurant'.obs;

  final String baseUrl = "https://savir-technology.online/roaqv2/videos";

  String? get selectedVideoName => selectedVideoFile?.name;

  String _normalizeTargetType(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'product' ? 'product' : 'restaurant';
  }

  void resetTargetSelection() {
    targetType.value = 'restaurant';
    targetIdController.clear();
  }

  Future<void> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    selectedVideoFile = result.files.single;
    selectedVideoBytes = selectedVideoFile!.bytes;
    update();
  }

  Future<void> openVideoUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      Get.snackbar("خطأ", "لا يوجد رابط فيديو متاح");
      return;
    }

    final uri = Uri.parse(url.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
      return;
    }

    Get.snackbar("خطأ", "تعذر فتح الفيديو");
  }

  Future<void> uploadVideo(
    String title,
    String desc, {
    required String targetType,
    required int targetId,
  }) async {
    if (selectedVideoFile == null) {
      Get.snackbar("خطأ", "اختر فيديو أولا");
      return;
    }

    isLoading.value = true;
    uploadProgress.value = 0.0;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/add_video.php'),
      );
      request.fields['video_title'] = title;
      request.fields['video_desc'] = desc;
      request.fields['target_type'] = _normalizeTargetType(targetType);
      request.fields['target_id'] = targetId.toString();
      if (_normalizeTargetType(targetType) == 'product') {
        request.fields['video_product_id'] = targetId.toString();
      }
      request.files.add(await _buildMultipartFile(selectedVideoFile!));

      uploadProgress.value = 0.4;
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      isLoading.value = false;
      uploadProgress.value = 0.0;

      if (response.statusCode == 200) {
        final body = response.body;
        final dynamic decoded =
            body.isNotEmpty ? convert.jsonDecode(body) : null;
        final uploadedUrl =
            decoded is Map<String, dynamic> ? decoded['url']?.toString() : null;

        lastUploadedVideoUrl.value = uploadedUrl;
        lastUploadedVideoTitle.value = title;
        Get.snackbar("تم", "تم رفع الفيديو بنجاح");
        _clearSelectedVideo();
        resetTargetSelection();
        fetchVideos();
        update();
      } else {
        Get.snackbar("خطأ", "فشل رفع الفيديو");
      }
    } catch (e) {
      isLoading.value = false;
      uploadProgress.value = 0.0;
      Get.snackbar("خطأ", "حدث خطأ أثناء رفع الفيديو");
      debugPrint("uploadVideo error: $e");
    }
  }

  Future<void> fetchVideos() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_videos.php"));
      if (response.statusCode == 200) {
        final dynamic decoded = response.body.isNotEmpty
            ? convert.jsonDecode(response.body)
            : null;

        if (decoded is List) {
          videos.value = decoded
              .whereType<Map>()
              .map((entry) => entry.cast<String, dynamic>())
              .toList();
        } else if (decoded is Map && decoded['data'] is List) {
          videos.value = (decoded['data'] as List)
              .whereType<Map>()
              .map((entry) => entry.cast<String, dynamic>())
              .toList();
        } else {
          videos.value = [];
        }
      }
    } catch (e) {
      debugPrint("fetchVideos error: $e");
    }
  }

  Future<void> deleteVideo(int id) async {
    final response = await http.post(
      Uri.parse("$baseUrl/delete_video.php"),
      body: {
        "video_id": id.toString(),
      },
    );

    if (response.statusCode == 200) {
      Get.snackbar("تم", "تم حذف الفيديو");
      fetchVideos();
    } else {
      Get.snackbar("خطأ", "فشل حذف الفيديو");
    }
  }

  Future<void> updateVideo(
    int id,
    String title,
    String desc, {
    required String targetType,
    required int targetId,
  }) async {
    isLoading.value = true;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/update_video.php'),
      );

      request.fields['video_id'] = id.toString();
      request.fields['video_title'] = title;
      request.fields['video_desc'] = desc;
      request.fields['target_type'] = _normalizeTargetType(targetType);
      request.fields['target_id'] = targetId.toString();
      if (_normalizeTargetType(targetType) == 'product') {
        request.fields['video_product_id'] = targetId.toString();
      }

      if (selectedVideoFile != null) {
        request.files.add(await _buildMultipartFile(selectedVideoFile!));
      }

      final response = await request.send();
      isLoading.value = false;

      if (response.statusCode == 200) {
        _clearSelectedVideo();
        resetTargetSelection();
        Get.snackbar("تم", "تم تحديث الفيديو بنجاح");
        fetchVideos();
        update();
      } else {
        Get.snackbar("خطأ", "فشل تحديث الفيديو");
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("خطأ", "حدث خطأ أثناء التحديث");
      debugPrint("updateVideo error: $e");
    }
  }

  Future<http.MultipartFile> _buildMultipartFile(PlatformFile file) async {
    if (file.bytes != null) {
      return http.MultipartFile.fromBytes(
        'video_file',
        file.bytes!,
        filename: file.name,
      );
    }

    if (file.path != null) {
      return http.MultipartFile.fromPath(
        'video_file',
        file.path!,
        filename: file.name,
      );
    }

    throw Exception('No file data available for upload');
  }

  void _clearSelectedVideo() {
    selectedVideoFile = null;
    selectedVideoBytes = null;
  }

  @override
  void onClose() {
    targetIdController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    fetchVideos();
    super.onInit();
  }
}
