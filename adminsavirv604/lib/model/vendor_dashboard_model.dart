import 'package:flutter/material.dart';

int _toInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
double _toDouble(dynamic value) =>
    double.tryParse(value?.toString() ?? '') ?? 0.0;

DateTime? _tryParseDate(dynamic value) {
  final raw = value?.toString() ?? '';
  if (raw.trim().isEmpty) return null;
  return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
}

Color _parseHexColor(String? value, Color fallback) {
  if (value == null || value.trim().isEmpty) {
    return fallback;
  }
  final hex = value.replaceAll('#', '').trim();
  final normalized = hex.length == 6 ? 'FF$hex' : hex;
  final parsed = int.tryParse(normalized, radix: 16);
  if (parsed == null) return fallback;
  return Color(parsed);
}

class VendorDashboardSnapshot {
  const VendorDashboardSnapshot({
    required this.summary,
    required this.headline,
    required this.topProductsToday,
    required this.alerts,
    required this.scheduledOrders,
    required this.recentOrders,
  });

  final VendorDashboardSummary summary;
  final List<VendorDashboardHeadline> headline;
  final List<VendorDashboardProduct> topProductsToday;
  final List<VendorDashboardAlert> alerts;
  final List<VendorDashboardOrder> scheduledOrders;
  final List<VendorDashboardOrder> recentOrders;

  factory VendorDashboardSnapshot.fromJson(Map<String, dynamic> json) {
    final summaryJson =
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
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

    return VendorDashboardSnapshot(
      summary: VendorDashboardSummary.fromJson(summaryJson),
      headline: mapList('headline', VendorDashboardHeadline.fromJson),
      topProductsToday:
          mapList('top_products_today', VendorDashboardProduct.fromJson),
      alerts: mapList('alerts', VendorDashboardAlert.fromJson),
      scheduledOrders: mapList('scheduled_orders', VendorDashboardOrder.fromJson),
      recentOrders: mapList('recent_orders', VendorDashboardOrder.fromJson),
    );
  }
}

class VendorDashboardSummary {
  const VendorDashboardSummary({
    required this.totalOrdersCount,
    required this.newOrdersCount,
    required this.readyToReceiveCount,
    required this.preparingCount,
    required this.inDeliveryCount,
    required this.completedTodayCount,
    required this.canceledTodayCount,
    required this.notDeliveredCount,
    required this.salesToday,
    required this.salesWeek,
    required this.salesMonth,
    required this.averagePrepMinutes,
    required this.averageRating,
    required this.totalReviews,
    required this.lowStockCount,
  });

  final int totalOrdersCount;
  final int newOrdersCount;
  final int readyToReceiveCount;
  final int preparingCount;
  final int inDeliveryCount;
  final int completedTodayCount;
  final int canceledTodayCount;
  final int notDeliveredCount;
  final double salesToday;
  final double salesWeek;
  final double salesMonth;
  final double averagePrepMinutes;
  final double averageRating;
  final int totalReviews;
  final int lowStockCount;

  factory VendorDashboardSummary.fromJson(Map<String, dynamic> json) {
    return VendorDashboardSummary(
      totalOrdersCount: _toInt(json['total_orders_count']),
      newOrdersCount: _toInt(json['new_orders_count']),
      readyToReceiveCount: _toInt(json['ready_to_receive_count']),
      preparingCount: _toInt(json['preparing_count']),
      inDeliveryCount: _toInt(json['in_delivery_count']),
      completedTodayCount: _toInt(json['completed_today_count']),
      canceledTodayCount: _toInt(json['canceled_today_count']),
      notDeliveredCount: _toInt(json['not_delivered_count']),
      salesToday: _toDouble(json['sales_today']),
      salesWeek: _toDouble(json['sales_week']),
      salesMonth: _toDouble(json['sales_month']),
      averagePrepMinutes: _toDouble(json['average_prep_minutes']),
      averageRating: _toDouble(json['average_rating']),
      totalReviews: _toInt(json['total_reviews']),
      lowStockCount: _toInt(json['low_stock_count']),
    );
  }
}

class VendorDashboardHeadline {
  const VendorDashboardHeadline({
    required this.title,
    required this.count,
    required this.subtitle,
    required this.tint,
  });

  final String title;
  final int count;
  final String subtitle;
  final Color tint;

  factory VendorDashboardHeadline.fromJson(Map<String, dynamic> json) {
    return VendorDashboardHeadline(
      title: json['title']?.toString() ?? '',
      count: _toInt(json['count']),
      subtitle: json['subtitle']?.toString() ?? '',
      tint: _parseHexColor(json['tint_hex']?.toString(), const Color(0xFF1B7A3A)),
    );
  }
}

class VendorDashboardProduct {
  const VendorDashboardProduct({
    required this.itemId,
    required this.productName,
    required this.imageUrl,
    required this.quantitySold,
    required this.ordersCount,
    required this.revenueAmount,
  });

  final int itemId;
  final String productName;
  final String imageUrl;
  final int quantitySold;
  final int ordersCount;
  final double revenueAmount;

  factory VendorDashboardProduct.fromJson(Map<String, dynamic> json) {
    return VendorDashboardProduct(
      itemId: _toInt(json['item_id']),
      productName: json['product_name']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      quantitySold: _toInt(json['quantity_sold']),
      ordersCount: _toInt(json['orders_count']),
      revenueAmount: _toDouble(json['revenue_amount']),
    );
  }
}

class VendorDashboardAlert {
  const VendorDashboardAlert({
    required this.label,
    required this.subtitle,
    required this.tint,
  });

  final String label;
  final String subtitle;
  final Color tint;

  factory VendorDashboardAlert.fromJson(Map<String, dynamic> json) {
    return VendorDashboardAlert(
      label: json['label']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      tint: _parseHexColor(json['tint_hex']?.toString(), const Color(0xFFD4A657)),
    );
  }
}

class VendorDashboardOrder {
  const VendorDashboardOrder({
    required this.orderId,
    required this.customerName,
    required this.itemsSummary,
    required this.orderTypeLabel,
    required this.giftMessage,
    required this.deliveryNote,
    required this.flowStatus,
    required this.vendorStatus,
    required this.totalPrice,
    required this.estimatedMinutes,
    required this.ordersDatetime,
  });

  final int orderId;
  final String customerName;
  final String itemsSummary;
  final String orderTypeLabel;
  final String giftMessage;
  final String deliveryNote;
  final String flowStatus;
  final String vendorStatus;
  final double totalPrice;
  final int estimatedMinutes;
  final DateTime? ordersDatetime;

  bool get isScheduled => ordersDatetime != null && ordersDatetime!.isAfter(DateTime.now());

  factory VendorDashboardOrder.fromJson(Map<String, dynamic> json) {
    return VendorDashboardOrder(
      orderId: _toInt(json['orders_id']),
      customerName: json['customer_name']?.toString() ?? '',
      itemsSummary: json['items_summary']?.toString() ?? '',
      orderTypeLabel: json['order_type_label']?.toString() ?? 'طلب عادي',
      giftMessage: json['orders_gift_message']?.toString() ??
          json['gift_message']?.toString() ??
          '',
      deliveryNote: json['orders_delivery_note']?.toString() ??
          json['delivery_note']?.toString() ??
          '',
      flowStatus: json['flow_status']?.toString() ?? 'new',
      vendorStatus: json['vendor_status']?.toString() ?? 'pending',
      totalPrice: _toDouble(json['orders_totalprice']),
      estimatedMinutes: _toInt(json['orders_estimated_minutes']),
      ordersDatetime: _tryParseDate(json['orders_datetime']),
    );
  }
}
