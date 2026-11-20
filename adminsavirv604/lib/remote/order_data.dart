import 'dart:convert';

import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/model/driver_dispatch_model.dart';
import 'package:admin_tks/model/order_model.dart';

class OrderData {
  static const String baseUrl =
      'https://savir-technology.online/roaqv2/dash/order/';

  static Future<List<OrderModel>> fetchOrders({String scope = 'all'}) async {
    final uri = Uri.parse('${baseUrl}get/get_orders.php').replace(
      queryParameters: scope == 'all' ? null : {'scope': scope},
    );
    final response = await DashboardApiClient.getUrl(uri.toString());
    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic> && decoded['status'] == 'success') {
        final raw = decoded['data'];
        final List<dynamic> data = raw is List
            ? raw
            : raw is Map && raw['data'] is List
                ? raw['data'] as List<dynamic>
                : const <dynamic>[];
        return data
            .whereType<Map>()
            .map((order) => OrderModel.fromJson(order.cast<String, dynamic>()))
            .toList();
      }
      if (decoded is Map && decoded['message'] != null) {
        throw Exception(decoded['message']);
      }
      throw Exception('فشل تحميل الطلبات');
    }
    throw Exception('فشل تحميل الطلبات');
  }

  static Future<List<Map<String, dynamic>>> fetchOrderDetails(
    String orderId,
    int vendorId,
  ) async {
    final response = await DashboardApiClient.getUrl(
      '${baseUrl}get/get_order_details.php?order_id=$orderId&vendor_id=$vendorId',
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic> && decoded['status'] == 'success') {
        final raw = decoded['data'];
        final List<dynamic> data = raw is List
            ? raw
            : raw is Map && raw['data'] is List
                ? raw['data'] as List<dynamic>
                : const <dynamic>[];
        return data
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList();
      }
      return [];
    }
    throw Exception('فشل تحميل تفاصيل الطلب');
  }

  static Future<List<OrderItemDetail>> fetchOrderItemDetails(
    String orderId,
    int vendorId,
  ) async {
    final rawItems = await fetchOrderDetails(orderId, vendorId);
    return rawItems.map((item) => OrderItemDetail.fromJson(item)).toList();
  }

  static Future<void> updateOrderStatus(
      String orderId, int vendorId, String status,
      {int? estimatedMinutes, String? reason}) async {
    final query = StringBuffer(
      '${baseUrl}update/update_order_status.php?order_id=$orderId&vendor_id=$vendorId&orderStatus=$status',
    );
    if (estimatedMinutes != null && estimatedMinutes > 0) {
      query.write('&estimated_minutes=$estimatedMinutes');
    }
    if (reason != null && reason.trim().isNotEmpty) {
      query.write('&reason=${Uri.encodeComponent(reason.trim())}');
    }

    final response = await DashboardApiClient.getUrl(query.toString());
    final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
    if (jsonResponse['status'] != 'success') {
      throw Exception(jsonResponse['message']);
    }
  }

  static Future<void> updateOrderFlowStatus(
    String orderId,
    int vendorId,
    String status,
  ) async {
    final response = await DashboardApiClient.postJsonUrl(
      DashboardApiClient.dashUri('/order/update/update_order_flow_status.php')
          .toString(),
      body: {
        'order_id': orderId,
        'vendor_id': vendorId.toString(),
        'status': status,
      },
    );
    final decoded = json.decode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic> && decoded['status'] != 'success') {
      throw Exception(decoded['message'] ?? 'تعذر تحديث حالة الطلب');
    }
  }

  static Future<void> deleteOrderByOrderId(String orderId) async {
    final response = await DashboardApiClient.getUrl(
      '${baseUrl}remove/delete_order.php?order_id=$orderId',
    );
    final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
    if (jsonResponse['status'] != 'success') {
      throw Exception(jsonResponse['message']);
    }
  }

  static Future<List<DriverDispatchOption>> fetchAvailableDrivers({
    required int vendorId,
    double? restaurantLatitude,
    double? restaurantLongitude,
    bool onlyAvailable = true,
  }) async {
    final query = StringBuffer('/driver/get/get_drivers.php');
    final params = <String, String>{
      'vendor_id': vendorId.toString(),
      if (onlyAvailable) 'only_available': '1',
    };
    if (restaurantLatitude != null && restaurantLongitude != null) {
      params['restaurant_latitude'] = restaurantLatitude.toStringAsFixed(7);
      params['restaurant_longitude'] = restaurantLongitude.toStringAsFixed(7);
    }
    query.write('?${Uri(queryParameters: params).query}');
    final response = await DashboardApiClient.getUrl(
      DashboardApiClient.dashUri(
        query.toString(),
      ).toString(),
    );
    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic> && decoded['status'] == 'success') {
        final raw = decoded['data'];
        final List<dynamic> data = raw is List
            ? raw
            : raw is Map && raw['data'] is List
                ? raw['data'] as List<dynamic>
                : const <dynamic>[];
        return data
            .whereType<Map>()
            .map(
              (item) => DriverDispatchOption.fromJson(
                item.cast<String, dynamic>(),
              ),
            )
            .toList();
      }
      if (decoded is Map && decoded['message'] != null) {
        throw Exception(decoded['message']);
      }
      throw Exception('تعذر تحميل السائقين المتاحين');
    }
    throw Exception('تعذر تحميل السائقين المتاحين');
  }

  static Future<void> assignOrderToDriver({
    required int orderId,
    required int driverId,
    required int vendorId,
  }) async {
    final response = await DashboardApiClient.postJsonUrl(
      DashboardApiClient.dashUri('/order/assign/assign_driver.php').toString(),
      body: {
        'action': 'assign_order',
        'order_id': orderId.toString(),
        'driver_id': driverId.toString(),
        'vendor_id': vendorId.toString(),
      },
    );
    final decoded = json.decode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic> && decoded['status'] != 'success') {
      throw Exception(decoded['message'] ?? 'تعذر إرسال الطلب للسائق');
    }
  }
}
