import 'package:admin_tks/model/support_model.dart';
import 'package:admin_tks/remote/support_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SupportController {
  final SupportData supportData = SupportData();

  Future<List<support_model>> fetchComplaints() async {
    try {
      final response = await http.get(Uri.parse(supportData.fetchComplaintsUrl));

      // اطبع محتوى الاستجابة للتحقق
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => support_model.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load complaints');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
