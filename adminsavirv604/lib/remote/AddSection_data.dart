import 'dart:convert';
import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/model/AddSection_model.dart';

class SectionData {
  final String apiUrl =
      "https://savir-technology.online/roaqv2/dash/sections/add/addcategories.php";

  Future<bool> uploadSection(SectionModel section) async {
    final response = await DashboardApiClient.postJsonUrl(
      apiUrl,
      body: section.toJson(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data is Map && data['status'] == 'success';
    } else {
      return false;
    }
  }
}
