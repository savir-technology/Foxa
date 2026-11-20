import 'dart:convert';

import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/model/vendor_dashboard_model.dart';

class VendorDashboardData {
  static const String _dashboardUrl =
      '${DashboardApiConfig.dashBaseUrl}/vendor/dashboard/get_dashboard.php';

  Future<VendorDashboardSnapshot?> getSnapshot() async {
    try {
      final response = await DashboardApiClient.getUrl(_dashboardUrl);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is! Map || decoded['status'] != 'success') {
        return null;
      }

      return VendorDashboardSnapshot.fromJson(
        decoded.cast<String, dynamic>(),
      );
    } catch (_) {
      return null;
    }
  }
}
