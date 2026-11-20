// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

class _MasterDeliveryLogisticsData {
  const _MasterDeliveryLogisticsData({
    required this.serverNow,
    required this.stats,
    required this.dispatchStats,
    required this.drivers,
    required this.unassignedOrders,
    required this.activeOrders,
    required this.assignmentHistory,
    required this.mapMarkers,
    required this.serviceZones,
    required this.emergencyRequests,
    required this.summary,
  });

  final DateTime? serverNow;
  final List<_OperationsStatCardData> stats;
  final List<_OperationsStatCardData> dispatchStats;
  final List<_DeliveryDriverData> drivers;
  final List<_DeliveryOrderData> unassignedOrders;
  final List<_DeliveryActiveOrderData> activeOrders;
  final List<_DeliveryAssignmentEventData> assignmentHistory;
  final List<_OperationsMapMarkerData> mapMarkers;
  final List<_ServiceZoneRecord> serviceZones;
  final List<_EmergencyRequestRecord> emergencyRequests;
  final Map<String, dynamic> summary;

  factory _MasterDeliveryLogisticsData.empty() {
    return const _MasterDeliveryLogisticsData(
      serverNow: null,
      stats: [],
      dispatchStats: [],
      drivers: [],
      unassignedOrders: [],
      activeOrders: [],
      assignmentHistory: [],
      mapMarkers: [],
      serviceZones: [],
      emergencyRequests: [],
      summary: {},
    );
  }

  factory _MasterDeliveryLogisticsData.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    return _MasterDeliveryLogisticsData(
      serverNow: _parseDateTime(data['server_now']),
      stats: _asMapList(
        data['stats'],
      ).map(_OperationsStatCardData.fromJson).toList(),
      dispatchStats: _asMapList(
        data['dispatch_stats'],
      ).map(_OperationsStatCardData.fromJson).toList(),
      drivers: _asMapList(
        data['drivers'],
      ).map(_DeliveryDriverData.fromJson).toList(),
      unassignedOrders: _asMapList(
        data['unassigned_orders'],
      ).map(_DeliveryOrderData.fromJson).toList(),
      activeOrders: _asMapList(
        data['active_orders'],
      ).map(_DeliveryActiveOrderData.fromJson).toList(),
      assignmentHistory: _asMapList(
        data['assignment_history'],
      ).map(_DeliveryAssignmentEventData.fromJson).toList(),
      mapMarkers: _asMapList(
        data['map_markers'],
      ).map(_OperationsMapMarkerData.fromJson).toList(),
      serviceZones: _asMapList(
        data['service_zones'],
      ).map(_ServiceZoneRecord.fromJson).toList(),
      emergencyRequests: _asMapList(
        data['emergency_requests'],
      ).map(_EmergencyRequestRecord.fromJson).toList(),
      summary: _asMap(data['summary']),
    );
  }

  int summaryInt(String key) => _toInt(summary[key]);

  double summaryDouble(String key) => _toDouble(summary[key]);
}

class _DeliveryDriverData {
  const _DeliveryDriverData({
    required this.driverId,
    required this.name,
    required this.phone,
    required this.vendorId,
    required this.vendorName,
    required this.approvalStatus,
    required this.approvalNote,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.statusKey,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.currentLocation,
    required this.todayOrders,
    required this.activeOrders,
    required this.rating,
  });

  final int driverId;
  final String name;
  final String phone;
  final int vendorId;
  final String vendorName;
  final String approvalStatus;
  final String approvalNote;
  final String vehicleType;
  final String vehicleNumber;
  final String statusKey;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final String currentLocation;
  final int todayOrders;
  final int activeOrders;
  final double rating;

  factory _DeliveryDriverData.fromJson(Map<String, dynamic> json) {
    return _DeliveryDriverData(
      driverId: _toInt(json['driver_id']),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      vendorId: _toInt(json['vendor_id']),
      vendorName: (json['vendor_name'] ?? '').toString(),
      approvalStatus: (json['approval_status'] ?? 'pending').toString(),
      approvalNote: (json['approval_note'] ?? '').toString(),
      vehicleType: (json['vehicle_type'] ?? '').toString(),
      vehicleNumber: (json['vehicle_number'] ?? '').toString(),
      statusKey: (json['status_key'] ?? '').toString(),
      statusLabel: (json['status_label'] ?? '').toString(),
      statusColor: _hexToColor(
        (json['status_color_hex'] ?? '#1A8B4A').toString(),
      ),
      statusBackground: _hexToColor(
        (json['status_background_hex'] ?? '#EAF5ED').toString(),
        fallback: const Color(0xFFEAF5ED),
      ),
      currentLocation: (json['current_location'] ?? '').toString(),
      todayOrders: _toInt(json['today_orders']),
      activeOrders: _toInt(json['active_orders']),
      rating: _toDouble(json['rating'], 0),
    );
  }
}

class _DeliveryOrderData {
  const _DeliveryOrderData({
    required this.orderId,
    this.vendorId = 0,
    required this.orderNo,
    required this.customer,
    required this.phone,
    required this.restaurant,
    required this.restaurantLogoUrl,
    required this.amountLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.typeLabel,
    required this.timeLabel,
    required this.relativeLabel,
    required this.addressLabel,
  });

  final int orderId;
  final int vendorId;
  final String orderNo;
  final String customer;
  final String phone;
  final String restaurant;
  final String restaurantLogoUrl;
  final String amountLabel;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final String typeLabel;
  final String timeLabel;
  final String relativeLabel;
  final String addressLabel;

  factory _DeliveryOrderData.fromJson(Map<String, dynamic> json) {
    return _DeliveryOrderData(
      orderId: _toInt(json['order_id']),
      vendorId: _toInt(json['vendor_id']),
      orderNo: (json['order_no'] ?? '').toString(),
      customer: (json['customer'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      restaurant: (json['restaurant'] ?? '').toString(),
      restaurantLogoUrl: (json['restaurant_logo_url'] ?? '').toString(),
      amountLabel: (json['amount_label'] ?? '').toString(),
      statusLabel: (json['status_label'] ?? '').toString(),
      statusColor: _hexToColor(
        (json['status_color_hex'] ?? '#1A8B4A').toString(),
      ),
      statusBackground: _hexToColor(
        (json['status_background_hex'] ?? '#EAF5ED').toString(),
        fallback: const Color(0xFFEAF5ED),
      ),
      typeLabel: (json['type_label'] ?? '').toString(),
      timeLabel: (json['time_label'] ?? '').toString(),
      relativeLabel: (json['relative_label'] ?? '').toString(),
      addressLabel: (json['address_label'] ?? '').toString(),
    );
  }
}

class _DeliveryActiveOrderData {
  const _DeliveryActiveOrderData({
    required this.orderId,
    required this.orderNo,
    required this.customer,
    required this.driverName,
    required this.restaurant,
    required this.amountLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.timeLabel,
    required this.relativeLabel,
  });

  final int orderId;
  final String orderNo;
  final String customer;
  final String driverName;
  final String restaurant;
  final String amountLabel;
  final String statusLabel;
  final Color statusColor;
  final String timeLabel;
  final String relativeLabel;

  factory _DeliveryActiveOrderData.fromJson(Map<String, dynamic> json) {
    return _DeliveryActiveOrderData(
      orderId: _toInt(json['order_id']),
      orderNo: (json['order_no'] ?? '').toString(),
      customer: (json['customer'] ?? '').toString(),
      driverName: (json['driver_name'] ?? '').toString(),
      restaurant: (json['restaurant'] ?? '').toString(),
      amountLabel: (json['amount_label'] ?? '').toString(),
      statusLabel: (json['status_label'] ?? '').toString(),
      statusColor: _hexToColor(
        (json['status_color_hex'] ?? '#1A8B4A').toString(),
      ),
      timeLabel: (json['time_label'] ?? '').toString(),
      relativeLabel: (json['relative_label'] ?? '').toString(),
    );
  }
}

class _DeliveryAssignmentEventData {
  const _DeliveryAssignmentEventData({
    required this.orderNo,
    required this.driverName,
    required this.restaurant,
    required this.timeLabel,
    required this.relativeLabel,
    required this.statusLabel,
  });

  final String orderNo;
  final String driverName;
  final String restaurant;
  final String timeLabel;
  final String relativeLabel;
  final String statusLabel;

  factory _DeliveryAssignmentEventData.fromJson(Map<String, dynamic> json) {
    return _DeliveryAssignmentEventData(
      orderNo: (json['order_no'] ?? '').toString(),
      driverName: (json['driver_name'] ?? '').toString(),
      restaurant: (json['restaurant'] ?? '').toString(),
      timeLabel: (json['time_label'] ?? '').toString(),
      relativeLabel: (json['relative_label'] ?? '').toString(),
      statusLabel: (json['status_label'] ?? '').toString(),
    );
  }
}
