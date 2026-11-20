import 'dart:convert';

import 'package:admin_tks/model/user_model.dart';
import 'package:http/http.dart' as http;

class UserController {
  static const String _apiUrl =
      'https://savir-technology.online/roaqv2/dash/users/get/get_users.php';
  static const String _toggleStatusUrl =
      'https://savir-technology.online/roaqv2/dash/users/update/toggle_user_status.php';

  Future<List<User>> fetchUsers() async {
    final response = await http.get(Uri.parse(_apiUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to load users: HTTP ${response.statusCode}');
    }

    final dynamic decoded = json.decode(response.body);

    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(User.fromJson)
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      if (decoded['status'] == 'success' && decoded['data'] is List) {
        return (decoded['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(User.fromJson)
            .toList();
      }

      final errorMessage = decoded['error']?.toString();
      if (errorMessage != null && errorMessage.isNotEmpty) {
        throw Exception(errorMessage);
      }
    }

    throw Exception('Unexpected users response format');
  }

  Future<void> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    final response = await http.post(
      Uri.parse(_toggleStatusUrl),
      body: {
        'user_id': userId,
        'users_approve': isActive ? '1' : '0',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user status');
    }

    final dynamic decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['status'] != 'success') {
      throw Exception(
        decoded is Map<String, dynamic>
            ? decoded['message']?.toString() ?? 'Failed to update user status'
            : 'Failed to update user status',
      );
    }
  }
}
