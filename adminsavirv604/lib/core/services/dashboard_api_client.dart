import 'dart:convert';

import 'package:admin_tks/core/services/dashboard_session_service.dart';
import 'package:http/http.dart' as http;

class DashboardApiConfig {
  static const String dashBaseUrl =
      'https://savir-technology.online/roaqv2/dash';
  static const String authBaseUrl = '$dashBaseUrl/auth';
  static const String masterAuthBaseUrl = '$dashBaseUrl/master_auth';
}

class DashboardApiClient {
  DashboardApiClient._();

  static Uri dashUri(String path) =>
      Uri.parse('${DashboardApiConfig.dashBaseUrl}$path');
  static Uri authUri(String path) =>
      Uri.parse('${DashboardApiConfig.authBaseUrl}$path');
  static Uri masterAuthUri(String path) =>
      Uri.parse('${DashboardApiConfig.masterAuthBaseUrl}$path');

  static Future<Map<String, String>> _headers({
    bool authorized = true,
    bool jsonBody = false,
    Map<String, String>? extra,
  }) async {
    final headers = <String, String>{};
    if (jsonBody) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }

    if (authorized) {
      final session = await DashboardSessionService.instance.loadSession();
      final token = session?.token ?? '';
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (extra != null) {
      headers.addAll(extra);
    }

    return headers;
  }

  static Future<http.Response> getUrl(
    String url, {
    bool authorized = true,
    Map<String, String>? headers,
  }) async {
    return http.get(
      Uri.parse(url),
      headers: await _headers(authorized: authorized, extra: headers),
    );
  }

  static Future<http.Response> postUrl(
    String url, {
    bool authorized = true,
    Map<String, String>? headers,
    Map<String, String>? body,
  }) async {
    return http.post(
      Uri.parse(url),
      headers: await _headers(authorized: authorized, extra: headers),
      body: body,
    );
  }

  static Future<http.Response> postJsonUrl(
    String url, {
    bool authorized = true,
    Map<String, String>? headers,
    Object? body,
  }) async {
    return http.post(
      Uri.parse(url),
      headers: await _headers(
        authorized: authorized,
        jsonBody: true,
        extra: headers,
      ),
      body: jsonEncode(body),
    );
  }

  static dynamic decodeJson(http.Response response) {
    return json.decode(utf8.decode(response.bodyBytes));
  }
}
