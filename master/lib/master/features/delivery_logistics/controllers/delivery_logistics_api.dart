// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

extension _MasterDeliveryLogisticsApi on MasterAuthApiService {
  Future<void> _resolveDriverEmergency(
    String token, {
    required int reportId,
    required int orderId,
    required int driverId,
  }) async {
    await _send(
      'POST',
      'dash/master/delivery/emergency_action.php',
      token: token,
      body: {
        'emergency_report_id': reportId,
        'order_id': orderId,
        'driver_id': driverId,
        'note': 'Resolved from Master emergency dashboard',
      },
    );
  }

  Future<_MasterDeliveryLogisticsData> _fetchDeliveryLogistics(
    String token, {
    String view = 'drivers',
    String query = '',
    String status = 'all',
    String vehicle = 'all',
  }) async {
    final params = <String, String>{
      'view': view,
      if (query.trim().isNotEmpty) 'q': query.trim(),
      if (status != 'all') 'status': status,
      if (vehicle != 'all') 'vehicle': vehicle,
    };
    final uri = Uri(
      path: 'dash/master/delivery/logistics.php',
      queryParameters: params,
    );
    final decoded = await _sendGet(uri.toString(), token: token);
    return _MasterDeliveryLogisticsData.fromJson(decoded);
  }

  Future<void> _assignDriverToOrder(
    String token, {
    required int orderId,
    required int driverId,
    int? vendorId,
  }) async {
    await _send(
      'POST',
      'dash/order/assign/assign_driver.php',
      token: token,
      body: {
        'order_id': orderId,
        'driver_id': driverId,
        if (vendorId != null && vendorId > 0) 'vendor_id': vendorId,
      },
    );
  }

  Future<void> _runDeliveryDriverAction(
    String token, {
    required String action,
    int? driverId,
    Map<String, dynamic>? data,
  }) async {
    await _send(
      'POST',
      'dash/master/delivery/driver_action.php',
      token: token,
      body: {
        'action': action,
        if (driverId != null && driverId > 0) 'driver_id': driverId,
        ...?data == null ? null : {'data': data},
      },
    );
  }
}
