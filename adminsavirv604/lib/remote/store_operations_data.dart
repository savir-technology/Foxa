import 'dart:convert';

import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/model/store_operations_model.dart';

class StoreOperationsData {
  static const String _baseUrl =
      '${DashboardApiConfig.dashBaseUrl}/vendor/store_operations';
  static const String _overviewUrl = '$_baseUrl/get_overview.php';
  static const String _acknowledgeLowStockUrl =
      '$_baseUrl/acknowledge_low_stock.php';
  static const String _updateReturnStatusUrl =
      '$_baseUrl/update_return_status.php';
  static const String _toggleReportUrl = '$_baseUrl/toggle_report.php';
  static const String _exportSnapshotUrl = '$_baseUrl/export_snapshot.php';

  String? _messageFromResponse(dynamic decoded) {
    if (decoded is Map) {
      return decoded['message']?.toString();
    }
    return null;
  }

  Future<StoreOperationsOverview?> getOverview() async {
    try {
      final response = await DashboardApiClient.getUrl(_overviewUrl);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is! Map || decoded['status'] != 'success') {
        return null;
      }

      return StoreOperationsOverview.fromJson(
        decoded.cast<String, dynamic>(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> acknowledgeLowStock(int itemId) async {
    try {
      final response = await DashboardApiClient.postJsonUrl(
        _acknowledgeLowStockUrl,
        body: {'item_id': itemId},
      );
      final decoded = DashboardApiClient.decodeJson(response);
      if (response.statusCode != 200 || decoded is! Map) {
        return null;
      }
      return _messageFromResponse(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<String?> updateReturnStatus(int returnId, String statusLabel) async {
    try {
      final response = await DashboardApiClient.postJsonUrl(
        _updateReturnStatusUrl,
        body: {
          'return_id': returnId,
          'status_label': statusLabel,
        },
      );
      final decoded = DashboardApiClient.decodeJson(response);
      if (response.statusCode != 200 || decoded is! Map) {
        return null;
      }
      return _messageFromResponse(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<String?> toggleReport(int reportId, bool isActive) async {
    try {
      final response = await DashboardApiClient.postJsonUrl(
        _toggleReportUrl,
        body: {
          'report_id': reportId,
          'is_active': isActive ? 1 : 0,
        },
      );
      final decoded = DashboardApiClient.decodeJson(response);
      if (response.statusCode != 200 || decoded is! Map) {
        return null;
      }
      return _messageFromResponse(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<String?> updateDriverRequest(int driverId, bool approve) async {
    try {
      final response = await DashboardApiClient.postJsonUrl(
        '${DashboardApiConfig.dashBaseUrl}/vendor/store_operations/driver_request_action.php',
        body: {'driver_id': driverId, 'action': approve ? 'approve' : 'reject'},
      );
      final decoded = DashboardApiClient.decodeJson(response);
      if (response.statusCode != 200 || decoded is! Map) return null;
      return decoded['message']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> exportSnapshot() async {
    try {
      final response = await DashboardApiClient.postJsonUrl(
        _exportSnapshotUrl,
        body: const {},
      );
      final decoded = DashboardApiClient.decodeJson(response);
      if (response.statusCode != 200 || decoded is! Map) {
        return null;
      }
      if (decoded['status'] != 'success') {
        return null;
      }
      return decoded.cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }
}
