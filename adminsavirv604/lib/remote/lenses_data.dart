import 'dart:convert';

import 'package:admin_tks/model/lens_model.dart';
import 'package:http/http.dart' as http;

class LensesData {
  final String baseUrl =
      "https://savir-technology.online/roaqv2/dash/lenses/";

  Future<List<LensModel>> getLenses() async {
    try {
      final res = await http.get(Uri.parse("${baseUrl}get/get_lenses.php"));
      if (res.statusCode == 200) {
        final jsonBody = json.decode(res.body);
        final data = jsonBody['data'] as List<dynamic>? ?? [];
        return data.map((e) => LensModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> addLens(LensModel lens) async {
    return _write("${baseUrl}add/add_lens.php", lens.toJson());
  }

  Future<bool> updateLens(LensModel lens) async {
    return _write("${baseUrl}update/update_lens.php", lens.toJson());
  }

  Future<bool> deleteLens(String lensId) async {
    return _write("${baseUrl}delete/delete_lens.php", {'lens_id': lensId});
  }

  Future<bool> _write(String url, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        final jsonBody = json.decode(res.body);
        return jsonBody['status'] == 'success';
      }
    } catch (_) {}
    return false;
  }
}
