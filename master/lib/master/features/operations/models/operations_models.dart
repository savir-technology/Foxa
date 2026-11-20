// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

class _OperationsLiveItemData {
  const _OperationsLiveItemData({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.icon,
    required this.accent,
    required this.background,
    required this.border,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
  final IconData icon;
  final Color accent;
  final Color background;
  final Color border;
}

class _OperationsSidebarTileData {
  const _OperationsSidebarTileData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _OperationsSubMenuTileData {
  const _OperationsSubMenuTileData({
    required this.label,
    required this.icon,
    required this.sectionKey,
  });

  final String label;
  final IconData icon;
  final String sectionKey;
}

class _TrackingFilterOptionData {
  const _TrackingFilterOptionData({
    required this.label,
    required this.icon,
    required this.color,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
}

class _TrackingListItemData {
  const _TrackingListItemData({
    required this.title,
    required this.subtitle,
    required this.note,
    required this.statusLabel,
    required this.statusColor,
    required this.icon,
    required this.iconColor,
    required this.background,
  });

  final String title;
  final String subtitle;
  final String note;
  final String statusLabel;
  final Color statusColor;
  final IconData icon;
  final Color iconColor;
  final Color background;
}

class _TrackingOrderData {
  const _TrackingOrderData({
    required this.orderId,
    required this.orderNo,
    required this.confirmationCode,
    required this.customer,
    required this.destination,
    required this.timeLabel,
    required this.statusKey,
    required this.orderType,
    required this.dateKey,
    required this.statusLabel,
    required this.statusColor,
    required this.avatarBackground,
    required this.avatarIcon,
  });

  final int orderId;
  final String orderNo;
  final String confirmationCode;
  final String customer;
  final String destination;
  final String timeLabel;
  final String statusKey;
  final String orderType;
  final String dateKey;
  final String statusLabel;
  final Color statusColor;
  final Color avatarBackground;
  final IconData avatarIcon;
}

class _TrackingMomentMetricData {
  const _TrackingMomentMetricData({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    required this.background,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;
  final Color background;
}

class _TrackingAreaStatusData {
  const _TrackingAreaStatusData({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.dotColor,
  });

  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final Color dotColor;
}

class _TrackingLiveStatData {
  const _TrackingLiveStatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;
}

class _OperationsStatCardData {
  const _OperationsStatCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    required this.background,
    required this.detailLine,
    required this.trendLabel,
    required this.trendCaption,
    required this.trendPositive,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final Color background;
  final String detailLine;
  final String trendLabel;
  final String trendCaption;
  final bool trendPositive;

  factory _OperationsStatCardData.fromJson(Map<String, dynamic> json) {
    return _OperationsStatCardData(
      title: (json['title'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      icon: _iconFromKey(json['icon_key']?.toString()),
      accent: _hexToColor((json['accent_hex'] ?? '#1A8B4A').toString()),
      background: _hexToColor(
        (json['background_hex'] ?? '#EAF5ED').toString(),
        fallback: const Color(0xFFEAF5ED),
      ),
      detailLine: (json['detail_line'] ?? '').toString(),
      trendLabel: (json['trend_label'] ?? '').toString(),
      trendCaption: (json['trend_caption'] ?? '').toString(),
      trendPositive:
          json['trend_positive'] == true || json['trend_positive'] == 1,
    );
  }

  Widget toWidget({
    required double height,
    required double valueFontSize,
    bool showTrendIcon = true,
  }) {
    return _OperationsStatCard(
      title: title,
      value: value,
      icon: icon,
      accent: accent,
      background: background,
      height: height,
      valueFontSize: valueFontSize,
      detailLine: detailLine.isEmpty ? null : detailLine,
      trendLabel: trendLabel.isEmpty ? null : trendLabel,
      trendCaption: trendCaption.isEmpty ? null : trendCaption,
      trendPositive: trendPositive,
      showTrendIcon: showTrendIcon,
    );
  }
}

class _OperationsMapMarkerData {
  const _OperationsMapMarkerData({
    this.entityId = 0,
    required this.type,
    required this.label,
    required this.subtitle,
    this.statusKey = '',
    required this.point,
    required this.icon,
    required this.color,
  });

  final String type;
  final int entityId;
  final String label;
  final String subtitle;
  final String statusKey;
  final LatLng point;
  final IconData icon;
  final Color color;

  factory _OperationsMapMarkerData.fromJson(Map<String, dynamic> json) {
    return _OperationsMapMarkerData(
      entityId: _toInt(json['entity_id']),
      type: (json['type'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      statusKey: (json['status_key'] ?? '').toString().toLowerCase(),
      point: LatLng(_toDouble(json['lat']), _toDouble(json['lng'])),
      icon: _iconFromKey(json['icon_key']?.toString()),
      color: _hexToColor((json['color_hex'] ?? '#1A8B4A').toString()),
    );
  }
}

class _OperationsRouteData {
  const _OperationsRouteData({
    required this.orderNo,
    required this.label,
    required this.points,
    required this.color,
  });

  final String orderNo;
  final String label;
  final List<LatLng> points;
  final Color color;

  factory _OperationsRouteData.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'];
    final points = rawPoints is List
        ? rawPoints
              .whereType<Map>()
              .map(
                (point) =>
                    LatLng(_toDouble(point['lat']), _toDouble(point['lng'])),
              )
              .where(
                (point) =>
                    point.latitude.abs() > 0.000001 &&
                    point.longitude.abs() > 0.000001,
              )
              .toList()
        : <LatLng>[];
    return _OperationsRouteData(
      orderNo: (json['order_no'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      points: points,
      color: _hexToColor((json['color_hex'] ?? '#2563EB').toString()),
    );
  }

  _OperationsRouteData withPoints(List<LatLng> nextPoints) {
    return _OperationsRouteData(
      orderNo: orderNo,
      label: label,
      points: nextPoints,
      color: color,
    );
  }
}

class _MasterOrderChatsData {
  const _MasterOrderChatsData({
    required this.serverNow,
    required this.stats,
    required this.conversations,
    required this.selectedOrder,
    required this.messages,
    required this.page,
    required this.limit,
    required this.total,
  });

  final DateTime? serverNow;
  final _OrderChatStatsData stats;
  final List<_OrderChatConversationData> conversations;
  final _OrderChatConversationData? selectedOrder;
  final List<_OrderChatMessageData> messages;
  final int page;
  final int limit;
  final int total;

  factory _MasterOrderChatsData.empty() {
    return const _MasterOrderChatsData(
      serverNow: null,
      stats: _OrderChatStatsData.empty(),
      conversations: [],
      selectedOrder: null,
      messages: [],
      page: 1,
      limit: 30,
      total: 0,
    );
  }

  factory _MasterOrderChatsData.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final pagination = _asMap(data['pagination']);
    final selectedMap = _asMap(data['selected_order']);
    return _MasterOrderChatsData(
      serverNow: _parseDateTime(data['server_now']),
      stats: _OrderChatStatsData.fromJson(_asMap(data['stats'])),
      conversations: _asMapList(
        data['conversations'],
      ).map(_OrderChatConversationData.fromJson).toList(),
      selectedOrder: selectedMap.isEmpty
          ? null
          : _OrderChatConversationData.fromJson(selectedMap),
      messages: _asMapList(
        data['messages'],
      ).map(_OrderChatMessageData.fromJson).toList(),
      page: _toInt(pagination['page'], 1),
      limit: _toInt(pagination['limit'], 30),
      total: _toInt(pagination['total']),
    );
  }
}

class _OrderChatStatsData {
  const _OrderChatStatsData({
    required this.total,
    required this.open,
    required this.waiting,
    required this.resolvedToday,
    required this.critical,
    required this.rating,
  });

  const _OrderChatStatsData.empty()
    : total = 0,
      open = 0,
      waiting = 0,
      resolvedToday = 0,
      critical = 0,
      rating = 0;

  final int total;
  final int open;
  final int waiting;
  final int resolvedToday;
  final int critical;
  final double rating;

  factory _OrderChatStatsData.fromJson(Map<String, dynamic> json) {
    return _OrderChatStatsData(
      total: _toInt(json['total']),
      open: _toInt(json['open']),
      waiting: _toInt(json['waiting']),
      resolvedToday: _toInt(json['resolved_today']),
      critical: _toInt(json['critical']),
      rating: _toDouble(json['rating']),
    );
  }
}

class _OrderChatConversationData {
  const _OrderChatConversationData({
    required this.orderId,
    required this.orderNo,
    required this.customerId,
    required this.customer,
    required this.phone,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.restaurant,
    required this.restaurantLogoUrl,
    required this.typeLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.amountLabel,
    required this.paymentLabel,
    required this.timeLabel,
    required this.relativeLabel,
    required this.addressLabel,
    required this.lastMessage,
    required this.lastSenderLabel,
    required this.totalMessages,
    required this.unreadForAdmin,
    required this.hasDriver,
    required this.critical,
  });

  final int orderId;
  final String orderNo;
  final int customerId;
  final String customer;
  final String phone;
  final int driverId;
  final String driverName;
  final String driverPhone;
  final String restaurant;
  final String restaurantLogoUrl;
  final String typeLabel;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final String amountLabel;
  final String paymentLabel;
  final String timeLabel;
  final String relativeLabel;
  final String addressLabel;
  final String lastMessage;
  final String lastSenderLabel;
  final int totalMessages;
  final int unreadForAdmin;
  final bool hasDriver;
  final bool critical;

  factory _OrderChatConversationData.fromJson(Map<String, dynamic> json) {
    return _OrderChatConversationData(
      orderId: _toInt(json['order_id']),
      orderNo: (json['order_no'] ?? '').toString(),
      customerId: _toInt(json['customer_id']),
      customer: (json['customer_name'] ?? '').toString(),
      phone: (json['customer_phone'] ?? '').toString(),
      driverId: _toInt(json['driver_id']),
      driverName: (json['driver_name'] ?? '').toString(),
      driverPhone: (json['driver_phone'] ?? '').toString(),
      restaurant: (json['restaurant'] ?? '').toString(),
      restaurantLogoUrl: (json['restaurant_logo_url'] ?? '').toString(),
      typeLabel: (json['type_label'] ?? '').toString(),
      statusLabel: (json['status_label'] ?? '').toString(),
      statusColor: _hexToColor(
        (json['status_color_hex'] ?? '#1A8B4A').toString(),
      ),
      statusBackground: _hexToColor(
        (json['status_background_hex'] ?? '#EAF5ED').toString(),
        fallback: const Color(0xFFEAF5ED),
      ),
      amountLabel: (json['amount_label'] ?? '').toString(),
      paymentLabel: (json['payment_label'] ?? '').toString(),
      timeLabel: (json['time_label'] ?? '').toString(),
      relativeLabel: (json['relative_label'] ?? '').toString(),
      addressLabel: (json['address_label'] ?? '').toString(),
      lastMessage: (json['last_message'] ?? '').toString(),
      lastSenderLabel: (json['last_sender_label'] ?? '').toString(),
      totalMessages: _toInt(json['total_messages']),
      unreadForAdmin: _toInt(json['unread_for_admin']),
      hasDriver: json['has_driver'] == true || json['has_driver'] == 1,
      critical: json['critical'] == true || json['critical'] == 1,
    );
  }
}

class _MasterOrdersData {
  const _MasterOrdersData({
    required this.serverNow,
    required this.stats,
    required this.orders,
    required this.channels,
    required this.timeChannels,
    required this.finance,
    required this.topRestaurants,
    required this.avgPreparationMinutes,
    required this.printing,
    required this.page,
    required this.limit,
    required this.total,
  });

  final DateTime? serverNow;
  final List<_OperationsStatCardData> stats;
  final List<_MasterOrderRowData> orders;
  final List<_OrdersChannelData> channels;
  final List<_OrdersChannelData> timeChannels;
  final List<_OrdersMetricData> finance;
  final List<_OrdersTopRestaurantData> topRestaurants;
  final int avgPreparationMinutes;
  final _OrdersPrintingData printing;
  final int page;
  final int limit;
  final int total;

  factory _MasterOrdersData.empty() {
    return _MasterOrdersData(
      serverNow: null,
      stats: const [],
      orders: const [],
      channels: const [],
      timeChannels: const [],
      finance: const [],
      topRestaurants: const [],
      avgPreparationMinutes: 0,
      printing: _OrdersPrintingData.empty(),
      page: 1,
      limit: 20,
      total: 0,
    );
  }

  factory _MasterOrdersData.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final pagination = _asMap(data['pagination']);
    return _MasterOrdersData(
      serverNow: _parseDateTime(data['server_now']),
      stats: _asMapList(
        data['stats'],
      ).map(_OperationsStatCardData.fromJson).toList(),
      orders: _asMapList(
        data['orders'],
      ).map(_MasterOrderRowData.fromJson).toList(),
      channels: _asMapList(
        data['channels'],
      ).map(_OrdersChannelData.fromJson).toList(),
      timeChannels: _asMapList(
        data['time_channels'],
      ).map(_OrdersChannelData.fromJson).toList(),
      finance: _asMapList(
        data['finance'],
      ).map(_OrdersMetricData.fromJson).toList(),
      topRestaurants: _asMapList(
        data['top_restaurants'],
      ).map(_OrdersTopRestaurantData.fromJson).toList(),
      avgPreparationMinutes: _toInt(data['avg_preparation_minutes']),
      printing: _OrdersPrintingData.fromJson(_asMap(data['printing'])),
      page: _toInt(pagination['page'], 1),
      limit: _toInt(pagination['limit'], 20),
      total: _toInt(pagination['total']),
    );
  }
}

class _MasterOrderRowData {
  const _MasterOrderRowData({
    required this.orderId,
    required this.orderNo,
    required this.shareToken,
    required this.trackingUrl,
    required this.customer,
    required this.phone,
    required this.driverName,
    required this.restaurant,
    required this.restaurantLogoUrl,
    required this.branch,
    required this.typeLabel,
    required this.scheduledLabel,
    required this.addressLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.amountLabel,
    required this.paymentKey,
    required this.paymentLabel,
    required this.paymentIcon,
    required this.timeLabel,
    required this.relativeLabel,
    required this.items,
  });

  final int orderId;
  final String orderNo;
  final String shareToken;
  final String trackingUrl;
  final String customer;
  final String phone;
  final String driverName;
  final String restaurant;
  final String restaurantLogoUrl;
  final String branch;
  final String typeLabel;
  final String scheduledLabel;
  final String addressLabel;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final String amountLabel;
  final String paymentKey;
  final String paymentLabel;
  final IconData paymentIcon;
  final String timeLabel;
  final String relativeLabel;
  final List<_OrderReceiptItemData> items;

  factory _MasterOrderRowData.fromJson(Map<String, dynamic> json) {
    final rawPaymentKey = (json['payment_key'] ?? '').toString().toLowerCase();
    final rawPaymentLabel = (json['payment_label'] ?? '').toString();
    final paymentKey = rawPaymentKey == 'visa'
        ? 'visa'
        : rawPaymentKey == 'wallet'
        ? 'wallet'
        : 'cash';
    final paymentLabel = paymentKey == 'visa'
        ? 'فيزا / بطاقة'
        : paymentKey == 'wallet'
        ? 'محفظة'
        : 'الدفع عند الاستلام';
    return _MasterOrderRowData(
      orderId: _toInt(json['order_id']),
      orderNo: (json['order_no'] ?? '').toString(),
      shareToken: (json['share_token'] ?? '').toString(),
      trackingUrl: (json['tracking_url'] ?? '').toString(),
      customer: (json['customer'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      driverName: (json['driver_name'] ?? '').toString(),
      restaurant: (json['restaurant'] ?? '').toString(),
      restaurantLogoUrl: (json['restaurant_logo_url'] ?? '').toString(),
      branch: (json['branch'] ?? '').toString(),
      typeLabel: (json['type_label'] ?? '').toString(),
      scheduledLabel: (json['scheduled_label'] ?? '').toString(),
      addressLabel: (json['address_label'] ?? '').toString(),
      statusLabel: (json['status_label'] ?? '').toString(),
      statusColor: _hexToColor(
        (json['status_color_hex'] ?? '#1A8B4A').toString(),
      ),
      statusBackground: _hexToColor(
        (json['status_background_hex'] ?? '#EAF5ED').toString(),
        fallback: const Color(0xFFEAF5ED),
      ),
      amountLabel: (json['amount_label'] ?? '').toString(),
      paymentKey: paymentKey,
      paymentLabel: rawPaymentLabel.trim().isEmpty
          ? paymentLabel
          : rawPaymentLabel,
      paymentIcon: _iconFromKey(paymentKey == 'wallet' ? 'wallet' : 'payments'),
      timeLabel: (json['time_label'] ?? '').toString(),
      relativeLabel: (json['relative_label'] ?? '').toString(),
      items: _asMapList(
        json['items'],
      ).map(_OrderReceiptItemData.fromJson).toList(),
    );
  }
}

class _OrderReceiptItemData {
  const _OrderReceiptItemData({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  final String name;
  final int quantity;
  final String unitPrice;
  final String total;

  factory _OrderReceiptItemData.fromJson(Map<String, dynamic> json) {
    return _OrderReceiptItemData(
      name: (json['name'] ?? 'صنف').toString(),
      quantity: math.max(1, _toInt(json['quantity'], 1)),
      unitPrice: (json['unit_price'] ?? '').toString(),
      total: (json['total'] ?? '').toString(),
    );
  }
}

class _OrdersChannelData {
  const _OrdersChannelData({
    required this.label,
    required this.value,
    required this.percent,
  });

  final String label;
  final int value;
  final int percent;

  factory _OrdersChannelData.fromJson(Map<String, dynamic> json) {
    return _OrdersChannelData(
      label: (json['label'] ?? '').toString(),
      value: _toInt(json['value']),
      percent: _toInt(json['percent']),
    );
  }
}

class _OrdersMetricData {
  const _OrdersMetricData({required this.label, required this.value});

  final String label;
  final String value;

  factory _OrdersMetricData.fromJson(Map<String, dynamic> json) {
    return _OrdersMetricData(
      label: (json['label'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
    );
  }
}

class _OrdersTopRestaurantData {
  const _OrdersTopRestaurantData({required this.name, required this.orders});

  final String name;
  final int orders;

  factory _OrdersTopRestaurantData.fromJson(Map<String, dynamic> json) {
    return _OrdersTopRestaurantData(
      name: (json['name'] ?? '').toString(),
      orders: _toInt(json['orders']),
    );
  }
}

class _OrdersPrintingData {
  const _OrdersPrintingData({
    required this.connectedPrinters,
    required this.printedToday,
    required this.printedInvoices,
    required this.printedReceipts,
    required this.invoiceCopies,
    required this.printLogo,
    required this.printers,
    required this.templates,
  });

  final int connectedPrinters;
  final int printedToday;
  final int printedInvoices;
  final int printedReceipts;
  final int invoiceCopies;
  final bool printLogo;
  final List<_OrdersPrinterData> printers;
  final List<String> templates;

  factory _OrdersPrintingData.empty() {
    return const _OrdersPrintingData(
      connectedPrinters: 0,
      printedToday: 0,
      printedInvoices: 0,
      printedReceipts: 0,
      invoiceCopies: 1,
      printLogo: true,
      printers: [],
      templates: [],
    );
  }

  factory _OrdersPrintingData.fromJson(Map<String, dynamic> json) {
    final settings = _asMap(json['settings']);
    return _OrdersPrintingData(
      connectedPrinters: _toInt(json['connected_printers']),
      printedToday: _toInt(json['printed_today']),
      printedInvoices: _toInt(json['printed_invoices']),
      printedReceipts: _toInt(json['printed_receipts']),
      invoiceCopies: math.max(1, _toInt(settings['invoice_copies'], 1)),
      printLogo: settings['print_logo'] != false && settings['print_logo'] != 0,
      printers: _asMapList(
        json['printers'],
      ).map(_OrdersPrinterData.fromJson).toList(),
      templates: (json['templates'] is List)
          ? (json['templates'] as List)
                .map((value) => value.toString())
                .where((value) => value.trim().isNotEmpty)
                .toList()
          : const <String>[],
    );
  }
}

class _OrdersPrinterData {
  const _OrdersPrinterData({
    required this.name,
    required this.type,
    required this.location,
    required this.isActive,
  });

  final String name;
  final String type;
  final String location;
  final bool isActive;

  String get displayLabel {
    final details = [
      type,
      location,
    ].where((value) => value.trim().isNotEmpty).join(' - ');
    return details.isEmpty ? name : '$name - $details';
  }

  factory _OrdersPrinterData.fromJson(Map<String, dynamic> json) {
    return _OrdersPrinterData(
      name: (json['name'] ?? 'طابعة').toString(),
      type: (json['type'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}

class _MasterOperationsData {
  const _MasterOperationsData({
    required this.serverNow,
    required this.notificationBadge,
    required this.messageBadge,
    required this.alertBadge,
    required this.overviewStatCards,
    required this.overviewLiveItems,
    required this.overviewMapMarkers,
    required this.performanceCards,
    required this.alertCards,
    required this.trackingOrders,
    required this.trackingDrivers,
    required this.trackingRestaurants,
    required this.trackingMapMarkers,
    required this.trackingRoutes,
    required this.trackingMomentMetrics,
    required this.trackingPressureAreas,
    required this.trackingShortageAreas,
    required this.trackingLiveStats,
    required this.activityStats,
    required this.activitySummaryGroups,
    required this.activityFeedItems,
    required this.activityEventItems,
    required this.activityFooterStatusItems,
  });

  final DateTime? serverNow;
  final int notificationBadge;
  final int messageBadge;
  final int alertBadge;
  final List<_OperationsStatCardData> overviewStatCards;
  final List<_OperationsLiveItemData> overviewLiveItems;
  final List<_OperationsMapMarkerData> overviewMapMarkers;
  final List<_OperationsStatCardData> performanceCards;
  final List<_OperationsStatCardData> alertCards;
  final List<_TrackingOrderData> trackingOrders;
  final List<_TrackingListItemData> trackingDrivers;
  final List<_TrackingListItemData> trackingRestaurants;
  final List<_OperationsMapMarkerData> trackingMapMarkers;
  final List<_OperationsRouteData> trackingRoutes;
  final List<_TrackingMomentMetricData> trackingMomentMetrics;
  final List<_TrackingAreaStatusData> trackingPressureAreas;
  final List<_TrackingAreaStatusData> trackingShortageAreas;
  final List<_TrackingLiveStatData> trackingLiveStats;
  final List<_OperationsStatCardData> activityStats;
  final List<_ActivitySummaryGroupData> activitySummaryGroups;
  final List<_ActivityFeedItemData> activityFeedItems;
  final List<_ActivityEventItemData> activityEventItems;
  final List<_DashboardStatusItemData> activityFooterStatusItems;

  factory _MasterOperationsData.empty({DateTime? serverNow}) {
    return _MasterOperationsData(
      serverNow: serverNow,
      notificationBadge: 0,
      messageBadge: 0,
      alertBadge: 0,
      overviewStatCards: const [],
      overviewLiveItems: const [],
      overviewMapMarkers: const [],
      performanceCards: const [],
      alertCards: const [],
      trackingOrders: const [],
      trackingDrivers: const [],
      trackingRestaurants: const [],
      trackingMapMarkers: const [],
      trackingRoutes: const [],
      trackingMomentMetrics: const [],
      trackingPressureAreas: const [],
      trackingShortageAreas: const [],
      trackingLiveStats: const [],
      activityStats: const [],
      activitySummaryGroups: const [],
      activityFeedItems: const [],
      activityEventItems: const [],
      activityFooterStatusItems: const [],
    );
  }

  factory _MasterOperationsData.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final overview = _asMap(data['overview']);
    final tracking = _asMap(data['tracking']);
    final activity = _asMap(data['activity']);
    final badges = _asMap(data['badges']);
    return _MasterOperationsData(
      serverNow: _parseDateTime(data['server_now']),
      notificationBadge: _toInt(badges['notifications']),
      messageBadge: _toInt(badges['messages']),
      alertBadge: _toInt(badges['alerts']),
      overviewStatCards: _asMapList(
        overview['stat_cards'],
      ).map(_OperationsStatCardData.fromJson).toList(),
      overviewLiveItems: _asMapList(
        overview['live_items'],
      ).map(_operationsLiveItemFromJson).toList(),
      overviewMapMarkers: _asMapList(
        overview['map_markers'],
      ).map(_OperationsMapMarkerData.fromJson).toList(),
      performanceCards: _asMapList(
        overview['performance_cards'],
      ).map(_OperationsStatCardData.fromJson).toList(),
      alertCards: _asMapList(
        overview['alert_cards'],
      ).map(_OperationsStatCardData.fromJson).toList(),
      trackingOrders: _asMapList(
        tracking['orders'],
      ).map(_trackingOrderFromJson).toList(),
      trackingDrivers: _asMapList(
        tracking['drivers'],
      ).map(_trackingListItemFromJson).toList(),
      trackingRestaurants: _asMapList(
        tracking['restaurants'],
      ).map(_trackingListItemFromJson).toList(),
      trackingMapMarkers: _asMapList(
        tracking['map_markers'],
      ).map(_OperationsMapMarkerData.fromJson).toList(),
      trackingRoutes: _asMapList(
        tracking['routes'],
      ).map(_OperationsRouteData.fromJson).toList(),
      trackingMomentMetrics: _asMapList(
        tracking['moment_metrics'],
      ).map(_trackingMomentMetricFromJson).toList(),
      trackingPressureAreas: _asMapList(
        tracking['pressure_areas'],
      ).map(_trackingAreaStatusFromJson).toList(),
      trackingShortageAreas: _asMapList(
        tracking['shortage_areas'],
      ).map(_trackingAreaStatusFromJson).toList(),
      trackingLiveStats: _asMapList(
        tracking['live_stats'],
      ).map(_trackingLiveStatFromJson).toList(),
      activityStats: _asMapList(
        activity['stats'],
      ).map(_OperationsStatCardData.fromJson).toList(),
      activitySummaryGroups: _asMapList(
        activity['summary_groups'],
      ).map(_activitySummaryGroupFromJson).toList(),
      activityFeedItems: _asMapList(
        activity['feed_items'],
      ).map(_activityFeedItemFromJson).toList(),
      activityEventItems: _asMapList(
        activity['event_items'],
      ).map(_activityEventItemFromJson).toList(),
      activityFooterStatusItems: _asMapList(
        activity['footer_status_items'],
      ).map(_DashboardStatusItemData.fromJson).toList(),
    );
  }

  _MasterOperationsData copyWith({
    List<_OperationsMapMarkerData>? overviewMapMarkers,
    List<_OperationsMapMarkerData>? trackingMapMarkers,
  }) {
    return _MasterOperationsData(
      serverNow: serverNow,
      notificationBadge: notificationBadge,
      messageBadge: messageBadge,
      alertBadge: alertBadge,
      overviewStatCards: overviewStatCards,
      overviewLiveItems: overviewLiveItems,
      overviewMapMarkers: overviewMapMarkers ?? this.overviewMapMarkers,
      performanceCards: performanceCards,
      alertCards: alertCards,
      trackingOrders: trackingOrders,
      trackingDrivers: trackingDrivers,
      trackingRestaurants: trackingRestaurants,
      trackingMapMarkers: trackingMapMarkers ?? this.trackingMapMarkers,
      trackingRoutes: trackingRoutes,
      trackingMomentMetrics: trackingMomentMetrics,
      trackingPressureAreas: trackingPressureAreas,
      trackingShortageAreas: trackingShortageAreas,
      trackingLiveStats: trackingLiveStats,
      activityStats: activityStats,
      activitySummaryGroups: activitySummaryGroups,
      activityFeedItems: activityFeedItems,
      activityEventItems: activityEventItems,
      activityFooterStatusItems: activityFooterStatusItems,
    );
  }

  static _OperationsLiveItemData _operationsLiveItemFromJson(
    Map<String, dynamic> json,
  ) {
    final accent = _hexToColor((json['accent_hex'] ?? '#1A8B4A').toString());
    final background = _hexToColor(
      (json['background_hex'] ?? '#EAF5ED').toString(),
      fallback: const Color(0xFFEAF5ED),
    );
    return _OperationsLiveItemData(
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? json['detail'] ?? '').toString(),
      timeLabel: (json['relative_label'] ?? json['time_label'] ?? '')
          .toString(),
      icon: _iconFromKey(json['icon_key']?.toString()),
      accent: accent,
      background: background,
      border: accent.withValues(alpha: 0.25),
    );
  }

  static _TrackingListItemData _trackingListItemFromJson(
    Map<String, dynamic> json,
  ) {
    final statusColor = _hexToColor(
      (json['status_color_hex'] ?? '#1A8B4A').toString(),
    );
    return _TrackingListItemData(
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      statusLabel: (json['status_label'] ?? '').toString(),
      statusColor: statusColor,
      icon: _iconFromKey(json['icon_key']?.toString()),
      iconColor: _hexToColor(
        (json['icon_color_hex'] ?? json['status_color_hex'] ?? '#1A8B4A')
            .toString(),
      ),
      background: _hexToColor(
        (json['background_hex'] ?? '#EAF5ED').toString(),
        fallback: const Color(0xFFEAF5ED),
      ),
    );
  }

  static _TrackingOrderData _trackingOrderFromJson(Map<String, dynamic> json) {
    final statusColor = _hexToColor(
      (json['status_color_hex'] ?? '#1A8B4A').toString(),
    );
    return _TrackingOrderData(
      orderId: _toInt(
        json['order_id'] ??
            (json['order_no']?.toString().replaceFirst('#', '') ?? ''),
      ),
      orderNo: (json['order_no'] ?? '').toString(),
      confirmationCode: (json['confirmation_code'] ?? '').toString(),
      customer: (json['customer'] ?? '').toString(),
      destination: (json['destination'] ?? '').toString(),
      timeLabel: (json['time_label'] ?? '').toString(),
      statusKey: (json['status_key'] ?? '').toString().toLowerCase(),
      orderType: (json['order_type'] ?? '').toString().toLowerCase(),
      dateKey: (json['date_key'] ?? '').toString(),
      statusLabel: (json['status_label'] ?? '').toString(),
      statusColor: statusColor,
      avatarBackground: _hexToColor(
        (json['avatar_background_hex'] ?? '#EAF5ED').toString(),
        fallback: const Color(0xFFEAF5ED),
      ),
      avatarIcon: _iconFromKey(json['avatar_icon_key']?.toString()),
    );
  }

  static _TrackingMomentMetricData _trackingMomentMetricFromJson(
    Map<String, dynamic> json,
  ) {
    return _TrackingMomentMetricData(
      label: (json['label'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      progress: _toDouble(json['progress']).clamp(0, 1).toDouble(),
      color: _hexToColor((json['color_hex'] ?? '#1A8B4A').toString()),
      background: _hexToColor(
        (json['background_hex'] ?? '#EAF5ED').toString(),
        fallback: const Color(0xFFEAF5ED),
      ),
    );
  }

  static _TrackingAreaStatusData _trackingAreaStatusFromJson(
    Map<String, dynamic> json,
  ) {
    final statusColor = _hexToColor(
      (json['status_color_hex'] ?? '#D92C2C').toString(),
      fallback: const Color(0xFFD92C2C),
    );
    return _TrackingAreaStatusData(
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      statusColor: statusColor,
      dotColor: _hexToColor(
        (json['dot_hex'] ?? json['status_color_hex'] ?? '#D92C2C').toString(),
        fallback: statusColor,
      ),
    );
  }

  static _TrackingLiveStatData _trackingLiveStatFromJson(
    Map<String, dynamic> json,
  ) {
    return _TrackingLiveStatData(
      label: (json['label'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      icon: _iconFromKey(json['icon_key']?.toString()),
      color: _hexToColor((json['color_hex'] ?? '#1A8B4A').toString()),
      background: _hexToColor(
        (json['background_hex'] ?? '#EAF5ED').toString(),
        fallback: const Color(0xFFEAF5ED),
      ),
    );
  }

  static _ActivitySummaryGroupData _activitySummaryGroupFromJson(
    Map<String, dynamic> json,
  ) {
    return _ActivitySummaryGroupData(
      title: (json['title'] ?? '').toString(),
      headerAccent: _hexToColor(
        (json['header_accent_hex'] ?? '#1A8B4A').toString(),
      ),
      items: _asMapList(
        json['items'],
      ).map(_activitySummaryRowFromJson).toList(),
    );
  }

  static _ActivitySummaryRowData _activitySummaryRowFromJson(
    Map<String, dynamic> json,
  ) {
    final accent = _hexToColor((json['accent_hex'] ?? '#1A8B4A').toString());
    final valueColorHex = (json['value_color_hex'] ?? '').toString();
    return _ActivitySummaryRowData(
      label: (json['label'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      icon: _iconFromKey(json['icon_key']?.toString()),
      accent: accent,
      background: _hexToColor(
        (json['background_hex'] ?? '#EAF5ED').toString(),
        fallback: const Color(0xFFEAF5ED),
      ),
      valueColor: valueColorHex.isEmpty ? null : _hexToColor(valueColorHex),
    );
  }

  static _ActivityFeedItemData _activityFeedItemFromJson(
    Map<String, dynamic> json,
  ) {
    return _ActivityFeedItemData(
      timeLabel: (json['time_label'] ?? '').toString(),
      relativeLabel: (json['relative_label'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      detail: (json['detail'] ?? '').toString(),
      pillLabel: (json['pill_label'] ?? '').toString(),
      icon: _iconFromKey(json['icon_key']?.toString()),
      accent: _hexToColor((json['accent_hex'] ?? '#1A8B4A').toString()),
      background: _hexToColor(
        (json['background_hex'] ?? '#EAF5ED').toString(),
        fallback: const Color(0xFFEAF5ED),
      ),
    );
  }

  static _ActivityEventItemData _activityEventItemFromJson(
    Map<String, dynamic> json,
  ) {
    return _ActivityEventItemData(
      title: (json['title'] ?? '').toString(),
      reference: (json['reference'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      timeLabel: (json['time_label'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      icon: _iconFromKey(json['icon_key']?.toString()),
      accent: _hexToColor((json['accent_hex'] ?? '#D92C2C').toString()),
      background: _hexToColor(
        (json['background_hex'] ?? '#FDEEEF').toString(),
        fallback: const Color(0xFFFDEEEF),
      ),
      buttonLabel: (json['button_label'] ?? '').toString(),
    );
  }
}

const List<_TrackingMomentMetricData> _kTrackingMomentMetrics = [];

const List<_TrackingAreaStatusData> _kTrackingPressureAreas = [];

const List<_TrackingAreaStatusData> _kTrackingShortageAreas = [];

const List<_TrackingLiveStatData> _kTrackingLiveStats = [];

const List<_TrackingFilterOptionData> _kTrackingFilterOptions = [
  _TrackingFilterOptionData(
    label: 'السائقون',
    icon: Icons.electric_scooter_rounded,
    color: Color(0xFF1E7D3F),
    selected: true,
  ),
  _TrackingFilterOptionData(
    label: 'الطلبات النشطة',
    icon: Icons.view_in_ar_rounded,
    color: Color(0xFF2563EB),
    selected: true,
  ),
  _TrackingFilterOptionData(
    label: 'المطاعم',
    icon: Icons.storefront_outlined,
    color: Color(0xFFF59E0B),
    selected: true,
  ),
  _TrackingFilterOptionData(
    label: 'مناطق الضغط',
    icon: Icons.local_fire_department_outlined,
    color: Color(0xFFD92C2C),
    selected: true,
  ),
  _TrackingFilterOptionData(
    label: 'مناطق نقص السائقين',
    icon: Icons.warning_amber_rounded,
    color: Color(0xFFF59E0B),
    selected: true,
  ),
];

const List<_TrackingListItemData> _kTrackingDrivers = [];

const List<_TrackingListItemData> _kTrackingRestaurants = [];

const List<_TrackingOrderData> _kTrackingOrders = [];

const List<_OperationsLiveItemData> _kOperationsLiveItems = [];

class _ActivitySummaryGroupData {
  const _ActivitySummaryGroupData({
    required this.title,
    required this.headerAccent,
    required this.items,
  });

  final String title;
  final Color headerAccent;
  final List<_ActivitySummaryRowData> items;
}

class _ActivitySummaryRowData {
  const _ActivitySummaryRowData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.background,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color background;
  final Color? valueColor;
}

class _ActivityFeedItemData {
  const _ActivityFeedItemData({
    required this.timeLabel,
    required this.relativeLabel,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.pillLabel,
    required this.icon,
    required this.accent,
    required this.background,
  });

  final String timeLabel;
  final String relativeLabel;
  final String title;
  final String subtitle;
  final String detail;
  final String pillLabel;
  final IconData icon;
  final Color accent;
  final Color background;
}

class _ActivityEventItemData {
  const _ActivityEventItemData({
    required this.title,
    required this.reference,
    required this.role,
    required this.timeLabel,
    required this.note,
    required this.icon,
    required this.accent,
    required this.background,
    required this.buttonLabel,
  });

  final String title;
  final String reference;
  final String role;
  final String timeLabel;
  final String note;
  final IconData icon;
  final Color accent;
  final Color background;
  final String buttonLabel;
}

const List<Widget> _kActivityStatCards = [];

const List<_ActivitySummaryGroupData> _kActivitySummaryGroups = [];

const List<_ActivityFeedItemData> _kActivityFeedItems = [];

const List<_ActivityEventItemData> _kActivityLiveEvents = [];

const List<_DashboardStatusItemData> _kActivityFooterStatusItems = [];
