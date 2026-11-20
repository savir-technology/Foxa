import 'dart:convert';

import 'package:admin_tks/core/services/dashboard_api_client.dart';

class MasterVendorRecord {
  const MasterVendorRecord({
    required this.vendorId,
    required this.vendorName,
    required this.storeName,
    required this.storeSlug,
    required this.email,
    required this.phone,
    required this.status,
    required this.isVerified,
    required this.createdAt,
    this.logo,
  });

  final int vendorId;
  final String vendorName;
  final String storeName;
  final String storeSlug;
  final String email;
  final String phone;
  final String status;
  final bool isVerified;
  final String createdAt;
  final String? logo;

  factory MasterVendorRecord.fromJson(Map<String, dynamic> json) {
    return MasterVendorRecord(
      vendorId: int.tryParse(json['vendor_id']?.toString() ?? '') ?? 0,
      vendorName: json['vendor_name']?.toString() ?? '',
      storeName: json['store_name']?.toString() ?? '',
      storeSlug: json['store_slug']?.toString() ?? '',
      email: json['vendor_email']?.toString() ?? '',
      phone: json['vendor_phone']?.toString() ?? '',
      status: json['vendor_status']?.toString() ?? 'pending',
      isVerified: (json['vendor_is_verified']?.toString() ?? '0') == '1',
      createdAt: json['vendor_created_at']?.toString() ?? '',
      logo: json['vendor_logo']?.toString(),
    );
  }
}

class MasterVendorsData {
  static const String _vendorsUrl =
      'https://savir-technology.online/roaqv2/dash/master/vendors/get_vendors.php';
  static const String _updateStatusUrl =
      'https://savir-technology.online/roaqv2/dash/master/vendors/update_status.php';

  Future<List<MasterVendorRecord>> fetchVendors() async {
    final response = await DashboardApiClient.getUrl(_vendorsUrl);
    final decoded = json.decode(response.body);
    if (response.statusCode == 200 &&
        decoded is Map &&
        decoded['status'] == 'success') {
      final data = (decoded['data'] as List?) ?? const [];
      return data
          .map((entry) => MasterVendorRecord.fromJson(
              (entry as Map).cast<String, dynamic>()))
          .toList();
    }

    throw Exception(decoded is Map
        ? decoded['message']?.toString() ?? 'Failed to load vendors'
        : 'Failed to load vendors');
  }

  Future<void> updateVendorStatus({
    required int vendorId,
    required String status,
  }) async {
    final response = await DashboardApiClient.postJsonUrl(
      _updateStatusUrl,
      body: {
        'vendor_id': vendorId,
        'vendor_status': status,
      },
    );

    final decoded = json.decode(response.body);
    if (response.statusCode != 200 ||
        decoded is! Map ||
        decoded['status'] != 'success') {
      throw Exception(decoded is Map
          ? decoded['message']?.toString() ?? 'Failed to update vendor'
          : 'Failed to update vendor');
    }
  }
}
