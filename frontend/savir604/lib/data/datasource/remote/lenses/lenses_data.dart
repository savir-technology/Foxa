import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tks/data/datasource/model/lens_selection_model.dart';
import 'package:tks/linkapi/linkapi.dart';

class LensesRemoteData {
  Future<List<LensOption>> getActiveLenses() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppLink.server}/lenses/get_active_lenses.php',
        ),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] as List<dynamic>? ?? [];
        return data
            .map((e) => LensOption.fromJson(Map<String, dynamic>.from(e)))
            .where((lens) => lens.code.isNotEmpty)
            .toList();
      }
    } catch (_) {}

    return LensCatalog.fallbackOptions;
  }
}
