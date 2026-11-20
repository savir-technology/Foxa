import 'package:flutter/material.dart';

Color _parseHexColor(String? value, Color fallback) {
  if (value == null || value.trim().isEmpty) {
    return fallback;
  }

  final hex = value.replaceAll('#', '').trim();
  final normalized = hex.length == 6 ? 'FF$hex' : hex;
  final colorValue = int.tryParse(normalized, radix: 16);
  if (colorValue == null) {
    return fallback;
  }

  return Color(colorValue);
}

int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
double _toDouble(dynamic value) =>
    double.tryParse(value?.toString() ?? '') ?? 0.0;

class StoreOperationsOverview {
  const StoreOperationsOverview({
    required this.summary,
    required this.lowStockRows,
    required this.salesBreakdowns,
    required this.orderSources,
    required this.returnRequests,
    required this.teamMembers,
    required this.customerInsights,
    required this.scheduledReports,
    required this.driverRequests,
  });

  final StoreOperationsSummary summary;
  final List<LowStockRow> lowStockRows;
  final List<SalesBreakdown> salesBreakdowns;
  final List<CampaignAttribution> orderSources;
  final List<ReturnRequest> returnRequests;
  final List<TeamMember> teamMembers;
  final List<CustomerInsight> customerInsights;
  final List<ScheduledReport> scheduledReports;
  final List<DriverRequest> driverRequests;

  factory StoreOperationsOverview.fromJson(Map<String, dynamic> json) {
    final summaryJson = (json['summary'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final dataJson =
        (json['data'] as Map?)?.cast<String, dynamic>() ?? const {};

    List<T> mapList<T>(
      String key,
      T Function(Map<String, dynamic>) builder,
    ) {
      final raw = (dataJson[key] as List?) ?? const [];
      return raw
          .map((entry) => builder((entry as Map).cast<String, dynamic>()))
          .toList();
    }

    return StoreOperationsOverview(
      summary: StoreOperationsSummary.fromJson(summaryJson),
      lowStockRows: mapList('low_stock', LowStockRow.fromJson),
      salesBreakdowns: mapList('sales_breakdowns', SalesBreakdown.fromJson),
      orderSources: mapList('order_sources', CampaignAttribution.fromJson),
      returnRequests: mapList('return_requests', ReturnRequest.fromJson),
      teamMembers: mapList('team_members', TeamMember.fromJson),
      customerInsights: mapList('customer_insights', CustomerInsight.fromJson),
      scheduledReports: mapList('scheduled_reports', ScheduledReport.fromJson),
      driverRequests: mapList('driver_requests', DriverRequest.fromJson),
    );
  }
}

class DriverRequest {
  const DriverRequest(
      {required this.id,
      required this.name,
      required this.phone,
      required this.vehicle,
      required this.status});
  final int id;
  final String name;
  final String phone;
  final String vehicle;
  final String status;
  factory DriverRequest.fromJson(Map<String, dynamic> json) => DriverRequest(
        id: _toInt(json['driver_id']),
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        vehicle: '${json['vehicle_type'] ?? ''} ${json['vehicle_number'] ?? ''}'
            .trim(),
        status: json['approval_status']?.toString() ?? 'pending',
      );
}

class StoreOperationsSummary {
  const StoreOperationsSummary({
    required this.lowStockCount,
    required this.openReturnsCount,
    required this.repeatCustomersCount,
    required this.scheduledReportsCount,
  });

  final int lowStockCount;
  final int openReturnsCount;
  final int repeatCustomersCount;
  final int scheduledReportsCount;

  factory StoreOperationsSummary.fromJson(Map<String, dynamic> json) {
    return StoreOperationsSummary(
      lowStockCount: _toInt(json['low_stock_count']),
      openReturnsCount: _toInt(json['open_returns_count']),
      repeatCustomersCount: _toInt(json['repeat_customers_count']),
      scheduledReportsCount: _toInt(json['scheduled_reports_count']),
    );
  }
}

class LowStockRow {
  const LowStockRow({
    required this.itemId,
    required this.product,
    required this.currentStock,
    required this.minimumStock,
    required this.supplierEta,
    required this.actionLabel,
  });

  final int itemId;
  final String product;
  final int currentStock;
  final int minimumStock;
  final String supplierEta;
  final String actionLabel;

  factory LowStockRow.fromJson(Map<String, dynamic> json) {
    return LowStockRow(
      itemId: _toInt(json['item_id']),
      product: json['product']?.toString() ?? '',
      currentStock: _toInt(json['current_stock']),
      minimumStock: _toInt(json['minimum_stock']),
      supplierEta: json['supplier_eta']?.toString() ?? '',
      actionLabel: json['action_label']?.toString() ?? '',
    );
  }
}

class SalesBreakdown {
  const SalesBreakdown({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.progress,
    required this.tint,
  });

  final String label;
  final String value;
  final String subtitle;
  final double progress;
  final Color tint;

  factory SalesBreakdown.fromJson(Map<String, dynamic> json) {
    return SalesBreakdown(
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      progress: _toDouble(json['progress']),
      tint:
          _parseHexColor(json['tint_hex']?.toString(), const Color(0xFF3B82F6)),
    );
  }
}

class CampaignAttribution {
  const CampaignAttribution({
    required this.source,
    required this.orders,
    required this.revenue,
    required this.conversion,
  });

  final String source;
  final String orders;
  final String revenue;
  final String conversion;

  factory CampaignAttribution.fromJson(Map<String, dynamic> json) {
    final ordersCount = _toInt(json['orders_count']);
    final revenueAmount = _toDouble(json['revenue_amount']);
    final conversionRate = _toDouble(json['conversion_rate']);

    return CampaignAttribution(
      source: json['source']?.toString() ?? '',
      orders: '$ordersCount',
      revenue: '${revenueAmount.toStringAsFixed(0)} SAR',
      conversion: '${conversionRate.toStringAsFixed(1)}%',
    );
  }
}

class ReturnRequest {
  const ReturnRequest({
    required this.returnId,
    required this.orderId,
    required this.customer,
    required this.reason,
    required this.status,
    required this.tint,
  });

  final int returnId;
  final String orderId;
  final String customer;
  final String reason;
  final String status;
  final Color tint;

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    return ReturnRequest(
      returnId: _toInt(json['return_id']),
      orderId: json['order_label']?.toString() ?? '',
      customer: json['customer_name']?.toString() ?? '',
      reason: json['reason_text']?.toString() ?? '',
      status: json['status_label']?.toString() ?? '',
      tint:
          _parseHexColor(json['tint_hex']?.toString(), const Color(0xFFF59E0B)),
    );
  }
}

class TeamMember {
  const TeamMember({
    required this.name,
    required this.role,
    required this.note,
    required this.permissions,
    required this.tint,
  });

  final String name;
  final String role;
  final String note;
  final List<String> permissions;
  final Color tint;

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final rawPermissions = json['permissions_json']?.toString() ?? '[]';
    final cleaned = rawPermissions
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '');
    final permissions = cleaned
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();

    return TeamMember(
      name: json['staff_name']?.toString() ?? '',
      role: json['staff_role']?.toString() ?? '',
      note: json['staff_note']?.toString() ?? '',
      permissions: permissions,
      tint:
          _parseHexColor(json['tint_hex']?.toString(), const Color(0xFF3B82F6)),
    );
  }
}

class CustomerInsight {
  const CustomerInsight({
    required this.name,
    required this.label,
    required this.subtitle,
    required this.spend,
    required this.tint,
  });

  final String name;
  final String label;
  final String subtitle;
  final String spend;
  final Color tint;

  factory CustomerInsight.fromJson(Map<String, dynamic> json) {
    final spendAmount = _toDouble(json['spend_amount']);
    return CustomerInsight(
      name: json['customer_name']?.toString() ?? '',
      label: json['segment_label']?.toString() ?? '',
      subtitle: json['segment_subtitle']?.toString() ?? '',
      spend: '${spendAmount.toStringAsFixed(0)} SAR',
      tint:
          _parseHexColor(json['tint_hex']?.toString(), const Color(0xFF3B82F6)),
    );
  }
}

class ScheduledReport {
  const ScheduledReport({
    required this.reportId,
    required this.name,
    required this.cadence,
    required this.target,
    required this.isActive,
  });

  final int reportId;
  final String name;
  final String cadence;
  final String target;
  final bool isActive;

  factory ScheduledReport.fromJson(Map<String, dynamic> json) {
    return ScheduledReport(
      reportId: _toInt(json['report_id']),
      name: json['report_name']?.toString() ?? '',
      cadence: json['cadence_label']?.toString() ?? '',
      target: json['target_label']?.toString() ?? '',
      isActive: _toInt(json['is_active']) == 1,
    );
  }
}
