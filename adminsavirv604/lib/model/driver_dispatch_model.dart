class DriverDispatchOption {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? vehicleType;
  final String? vehicleNumber;
  final String status;
  final double? latitude;
  final double? longitude;
  final String? lastSeenAt;
  final int vendorId;
  final int activeOrdersCount;
  final bool isAvailable;
  final double? distanceKm;

  const DriverDispatchOption({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.lastSeenAt,
    required this.vendorId,
    required this.activeOrdersCount,
    required this.isAvailable,
    required this.distanceKm,
  });

  bool get hasLocation {
    final lat = latitude;
    final lng = longitude;
    return lat != null && lng != null && lat != 0 && lng != 0;
  }

  bool get canDispatch => isAvailable && activeOrdersCount == 0;

  factory DriverDispatchOption.fromJson(Map<String, dynamic> json) {
    final isAvailableRaw = json['is_available'];
    return DriverDispatchOption(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      vehicleType: json['vehicle_type']?.toString(),
      vehicleNumber: json['vehicle_number']?.toString(),
      status: json['status']?.toString() ?? 'offline',
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      lastSeenAt: json['last_seen_at']?.toString(),
      vendorId: int.tryParse(json['vendor_id']?.toString() ?? '') ?? 0,
      activeOrdersCount:
          int.tryParse(json['active_orders_count']?.toString() ?? '') ?? 0,
      isAvailable: isAvailableRaw is bool
          ? isAvailableRaw
          : int.tryParse(isAvailableRaw?.toString() ?? '') == 1,
      distanceKm: double.tryParse(json['distance_km']?.toString() ?? ''),
    );
  }

  String get vehicleLabel {
    final parts = <String>[
      if ((vehicleType ?? '').trim().isNotEmpty) vehicleType!.trim(),
      if ((vehicleNumber ?? '').trim().isNotEmpty) '#${vehicleNumber!.trim()}',
    ];
    return parts.isEmpty ? 'غير محدد' : parts.join(' • ');
  }
}
