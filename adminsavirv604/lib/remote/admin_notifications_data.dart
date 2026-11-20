import 'dart:convert';

import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/model/admin_notification_model.dart';
import 'package:http/http.dart' as http;

class AdminNotificationsData {
  final String baseUrl =
      'https://savir-technology.online/roaqv2/dash/notifications/';

  dynamic _decode(http.Response response) {
    return json.decode(utf8.decode(response.bodyBytes));
  }

  Future<AdminNotificationResponse?> getAll() async {
    try {
      final res = await DashboardApiClient.getUrl('${baseUrl}get_all.php');
      if (res.statusCode != 200) return null;
      final body = _decode(res);
      if (body is! Map || body['status'] != 'success') return null;

      final summaryJson = (body['summary'] as Map?)?.cast<String, dynamic>() ?? {};
      final rowsJson = (body['data'] as List<dynamic>?) ?? const <dynamic>[];
      final rows = rowsJson
          .map((e) => AdminNotification.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      return AdminNotificationResponse(
        summary: AdminNotificationSummary.fromJson(summaryJson),
        rows: rows,
      );
    } catch (e) {
      // ignore: avoid_print
      print('getAll notifications error: $e');
      return null;
    }
  }

  Future<bool> markRead(int id) async {
    try {
      final res = await DashboardApiClient.postUrl(
        '${baseUrl}mark_read.php',
        body: {'notification_id': '$id'},
      );
      if (res.statusCode != 200) return false;
      final body = _decode(res);
      return body is Map && body['status'] == 'success';
    } catch (e) {
      // ignore: avoid_print
      print('markRead error: $e');
      return false;
    }
  }

  Future<bool> markAllRead() async {
    try {
      final res = await DashboardApiClient.postUrl('${baseUrl}mark_all_read.php');
      if (res.statusCode != 200) return false;
      final body = _decode(res);
      return body is Map && body['status'] == 'success';
    } catch (e) {
      // ignore: avoid_print
      print('markAllRead error: $e');
      return false;
    }
  }
}
