import 'dart:convert';

import 'package:admin_tks/model/ar_filter_model.dart';
import 'package:http/http.dart' as http;

class ArFilterData {
  final String baseUrl =
      "https://savir-technology.online/roaqv2/dash/ar_filter/";

  Future<ArFilterModel?> getItemArFilter(String itemId) async {
    try {
      final res = await http.get(
        Uri.parse("${baseUrl}get/get_item_ar_filter.php?item_id=$itemId"),
      );
      if (res.statusCode == 200) {
        final jsonBody = json.decode(res.body);
        final data = jsonBody['data'];
        if (jsonBody['status'] == 'success' && data != null) {
          return ArFilterModel.fromJson(data);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<ArFilterModel?> upsertItemArFilter({
    required String itemId,
    required String overlayImageBase64,
    double scaleFactor = 0.10,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("${baseUrl}update/upsert_item_ar_filter.php"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'item_id': itemId,
          'overlay_image': overlayImageBase64,
          'scale_factor': scaleFactor,
        }),
      );
      if (res.statusCode == 200) {
        final jsonBody = json.decode(res.body);
        final data = jsonBody['data'];
        if (jsonBody['status'] == 'success' && data != null) {
          return ArFilterModel.fromJson(data);
        }
      }
    } catch (_) {}
    return null;
  }
}

