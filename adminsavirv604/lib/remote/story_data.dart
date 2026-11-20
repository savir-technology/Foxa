import 'dart:convert';
import 'dart:typed_data';

import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/core/services/dashboard_session_service.dart';
import 'package:http/http.dart' as http;

class StoryData {
  static const String _baseUrl =
      '${DashboardApiConfig.dashBaseUrl}/stories';
  static const String _getUrl = '$_baseUrl/get/get_stories.php';
  static const String _addUrl = '$_baseUrl/add/add_story.php';
  static const String _updateUrl = '$_baseUrl/update/update_story.php';
  static const String _deleteUrl = '$_baseUrl/remove/delete_story.php';

  Future<List<Map<String, dynamic>>> getStories({int? vendorId}) async {
    try {
      final url = vendorId != null && vendorId > 0
          ? '$_getUrl?vendor_id=$vendorId'
          : _getUrl;
      final response = await DashboardApiClient.getUrl(url);
      if (response.statusCode != 200) {
        return [];
      }

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> rows = decoded is Map && decoded['data'] is List
          ? decoded['data'] as List<dynamic>
          : decoded is List
              ? decoded
              : const <dynamic>[];

      return rows
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getVendors() async {
    try {
      final response = await DashboardApiClient.getUrl(
        'https://savir-technology.online/roaqv2/dash/master/vendors/get_vendors.php',
      );
      if (response.statusCode != 200) {
        return [];
      }

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> rows = decoded is Map && decoded['data'] is List
          ? decoded['data'] as List<dynamic>
          : decoded is List
              ? decoded
              : const <dynamic>[];

      return rows
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> addStory({
    required String vendorId,
    required String titleAr,
    required String titleEn,
    required String mediaType,
    required String targetType,
    required int targetId,
    required String ctaLabelAr,
    required String ctaLabelEn,
    required String sortOrder,
    required bool isActive,
    String? startsAt,
    String? endsAt,
    Uint8List? mediaBytes,
    String? mediaName,
  }) async {
    return _sendMultipart(
      _addUrl,
      fields: {
        'vendor_id': vendorId,
        'title_ar': titleAr,
        'title_en': titleEn,
        'media_type': mediaType,
        'target_type': targetType,
        'target_id': targetId.toString(),
        'cta_label_ar': ctaLabelAr,
        'cta_label_en': ctaLabelEn,
        'sort_order': sortOrder,
        'is_active': isActive ? '1' : '0',
        if (startsAt != null && startsAt.trim().isNotEmpty) 'starts_at': startsAt,
        if (endsAt != null && endsAt.trim().isNotEmpty) 'ends_at': endsAt,
      },
      mediaBytes: mediaBytes,
      mediaName: mediaName,
      mediaType: mediaType,
    );
  }

  Future<Map<String, dynamic>?> updateStory({
    required String storyId,
    required String vendorId,
    required String titleAr,
    required String titleEn,
    required String mediaType,
    required String targetType,
    required int targetId,
    required String ctaLabelAr,
    required String ctaLabelEn,
    required String sortOrder,
    required bool isActive,
    String? startsAt,
    String? endsAt,
    Uint8List? mediaBytes,
    String? mediaName,
  }) async {
    return _sendMultipart(
      _updateUrl,
      fields: {
        'id': storyId,
        'vendor_id': vendorId,
        'title_ar': titleAr,
        'title_en': titleEn,
        'media_type': mediaType,
        'target_type': targetType,
        'target_id': targetId.toString(),
        'cta_label_ar': ctaLabelAr,
        'cta_label_en': ctaLabelEn,
        'sort_order': sortOrder,
        'is_active': isActive ? '1' : '0',
        if (startsAt != null && startsAt.trim().isNotEmpty) 'starts_at': startsAt,
        if (endsAt != null && endsAt.trim().isNotEmpty) 'ends_at': endsAt,
      },
      mediaBytes: mediaBytes,
      mediaName: mediaName,
      mediaType: mediaType,
    );
  }

  Future<bool> deleteStory(String storyId) async {
    try {
      final response = await DashboardApiClient.postUrl(
        _deleteUrl,
        body: {'id': storyId},
      );
      if (response.statusCode != 200) {
        return false;
      }

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      return decoded is Map && decoded['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> _sendMultipart(
    String url, {
    required Map<String, String> fields,
    required Uint8List? mediaBytes,
    required String? mediaName,
    required String mediaType,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields.addAll(fields);

      final session = await DashboardSessionService.instance.loadSession();
      final token = session?.token ?? '';
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (mediaBytes != null && mediaBytes.isNotEmpty) {
        final fieldName = mediaType.trim().toLowerCase() == 'video'
            ? 'video'
            : 'image';
        request.files.add(
          http.MultipartFile.fromBytes(
            fieldName,
            mediaBytes,
            filename: mediaName ?? 'story-media',
          ),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200 || decoded is! Map<String, dynamic>) {
        return null;
      }

      if (decoded['status'] != 'success') {
        return null;
      }

      return decoded;
    } catch (_) {
      return null;
    }
  }
}
