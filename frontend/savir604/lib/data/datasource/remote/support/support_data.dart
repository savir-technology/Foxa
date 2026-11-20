import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tks/linkapi/linkapi.dart';

class SupportData {
  Future<Map<String, dynamic>> sendComplaint(
      String userId, String complaint) async {
    var url = '${AppLink.server}/supports/support.php'; // URL API

    var response = await http.post(
      Uri.parse(url),
      body: {
        'user_id': userId,
        'complaint': complaint,
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to send complaint');
    }
  }
}
