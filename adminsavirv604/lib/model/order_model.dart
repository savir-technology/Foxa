class OrderModel {
  int? ordersId;
  int? ordersUsersid;
  String? usersName;
  String? usersEmail;
  String? addressCity;
  String? addressStreet;
  String? addressPhone;
  double? ordersRecipientLat;
  double? ordersRecipientLng;
  double? storeLatitude;
  double? storeLongitude;
  String? ordersTotalprice;
  int? ordersPaymentmethod;
  String? paymentMethod;
  String? paymentKey;
  String? paymentLabel;
  String? paidAmount;
  String? transactionId;
  String? gatewayRef;
  String? ordersStatus;
  String? ordersGiftMessage;
  String? ordersDeliveryNote;
  String? ordersRejectionReason;
  String? ordersDatetime;
  String? orderMode;
  String? scheduledFor;
  int? ordersEstimatedMinutes;
  int? ordersType;
  int? deliveryId;
  int? ordersItemsCount;
  String? driverName;
  String? driverPhone;
  String? driverStatus;
  String? assignedAt;
  String? acceptedAt;
  String? arrivedAtRestaurantAt;
  String? pickedUpAt;
  String? arrivedAtCustomerAt;
  String? deliveredAt;
  String? flowStatus;
  String? deliveryCode;
  String? proofType;
  String? proofImage;
  int? vendorId;
  String? vendorName;
  String? storeName;

  OrderModel({
    this.ordersId,
    this.ordersUsersid,
    this.usersName,
    this.usersEmail,
    this.addressCity,
    this.addressStreet,
    this.addressPhone,
    this.ordersRecipientLat,
    this.ordersRecipientLng,
    this.storeLatitude,
    this.storeLongitude,
    this.ordersTotalprice,
    this.ordersPaymentmethod,
    this.paymentMethod,
    this.paymentKey,
    this.paymentLabel,
    this.paidAmount,
    this.transactionId,
    this.gatewayRef,
    this.ordersStatus,
    this.ordersGiftMessage,
    this.ordersDeliveryNote,
    this.ordersRejectionReason,
    this.ordersDatetime,
    this.orderMode,
    this.scheduledFor,
    this.ordersEstimatedMinutes,
    this.ordersType,
    this.deliveryId,
    this.ordersItemsCount,
    this.driverName,
    this.assignedAt,
    this.acceptedAt,
    this.arrivedAtRestaurantAt,
    this.pickedUpAt,
    this.arrivedAtCustomerAt,
    this.deliveredAt,
    this.flowStatus,
    this.driverPhone,
    this.driverStatus,
    this.deliveryCode,
    this.proofType,
    this.proofImage,
    this.vendorId,
    this.vendorName,
    this.storeName,
  });

  OrderModel.fromJson(Map<String, dynamic> json) {
    ordersId = _toInt(json['orders_id']);
    ordersUsersid = _toInt(json['orders_usersid']);
    usersName = json['users_name']?.toString();
    usersEmail = json['users_email']?.toString();
    addressCity = json['address_city']?.toString();
    addressStreet = json['address_street']?.toString();
    addressPhone = json['address_phone']?.toString();
    ordersRecipientLat = double.tryParse(
      json['orders_recipient_lat']?.toString() ?? '',
    );
    ordersRecipientLng = double.tryParse(
      json['orders_recipient_lng']?.toString() ?? '',
    );
    storeLatitude = double.tryParse(json['store_latitude']?.toString() ?? '');
    storeLongitude = double.tryParse(json['store_longitude']?.toString() ?? '');
    ordersTotalprice = json['orders_totalprice']?.toString();
    ordersPaymentmethod = _toInt(json['orders_paymentmethod']);
    paymentMethod = json['payment_method']?.toString();
    paymentKey = json['payment_key']?.toString();
    paymentLabel = json['payment_label']?.toString();
    paidAmount = json['paid_amount']?.toString();
    transactionId = json['transaction_id']?.toString();
    gatewayRef = json['orders_gateway_ref']?.toString();
    ordersStatus = json['orders_status']?.toString();
    ordersGiftMessage = json['orders_gift_message']?.toString() ??
        json['gift_message']?.toString();
    ordersDeliveryNote = json['orders_delivery_note']?.toString() ??
        json['delivery_note']?.toString();
    ordersRejectionReason = json['orders_rejection_reason']?.toString();
    ordersDatetime = json['orders_datetime']?.toString();
    orderMode = json['order_mode']?.toString();
    scheduledFor = json['scheduled_for']?.toString();
    ordersEstimatedMinutes = _toInt(json['orders_estimated_minutes']);
    ordersType = _toInt(json['orders_type']);
    deliveryId = _toInt(json['delivery_id']);
    ordersItemsCount = _toInt(json['orders_items_count']);
    driverName = json['driver_name']?.toString();
    driverPhone = json['driver_phone']?.toString();
    driverStatus = json['driver_status']?.toString();
    assignedAt = json['assigned_at']?.toString();
    acceptedAt = json['accepted_at']?.toString();
    arrivedAtRestaurantAt = json['arrived_at_restaurant_at']?.toString();
    pickedUpAt = json['picked_up_at']?.toString();
    arrivedAtCustomerAt = json['arrived_at_customer_at']?.toString();
    deliveredAt = json['delivered_at']?.toString();
    flowStatus = json['status']?.toString();
    deliveryCode = json['delivery_code']?.toString();
    proofType = _firstNonEmptyString(json, const [
      'proof_type',
      'delivery_proof_type',
    ]);
    proofImage = _firstNonEmptyString(json, const [
      'proof_image',
      'delivery_proof_image',
      'delivery_proof_image_url',
      'delivery_proof_url',
      'proof_image_url',
    ]);
    vendorId = _toInt(json['vendor_id']);
    vendorName = json['vendor_name']?.toString();
    storeName = json['store_name']?.toString();
  }

  double get totalPriceValue => double.tryParse(ordersTotalprice ?? '') ?? 0;
  DateTime? get orderDateTime => DateTime.tryParse(
        (ordersDatetime ?? '').replaceFirst(' ', 'T'),
      );
  DateTime? get scheduledDateTime => DateTime.tryParse(
        (scheduledFor ?? '').replaceFirst(' ', 'T'),
      );
  bool get isScheduled =>
      scheduledDateTime != null && scheduledDateTime!.isAfter(DateTime.now());
  bool get isPickup => ordersType == 1;
  String get resolvedPaymentKey {
    final directKey = (paymentKey ?? '').trim().toLowerCase();
    if (directKey == 'visa' || directKey == 'wallet' || directKey == 'cash') {
      return directKey;
    }
    final raw = (paymentMethod ?? '').trim().toLowerCase();
    if (raw == '2' || raw.contains('wallet') || raw.contains('محفظ')) {
      return 'wallet';
    }
    if (raw == '1' ||
        raw.contains('visa') ||
        raw.contains('card') ||
        raw.contains('credit') ||
        raw.contains('master') ||
        raw.contains('online') ||
        raw.contains('paymob') ||
        raw.contains('meeza') ||
        raw.contains('فيزا')) {
      return 'visa';
    }
    if (ordersPaymentmethod == 2) return 'wallet';
    if (ordersPaymentmethod == 1) return 'visa';
    return 'cash';
  }

  String get resolvedPaymentLabel {
    final directLabel = (paymentLabel ?? '').trim();
    if (directLabel.isNotEmpty && directLabel.toLowerCase() != 'null') {
      return directLabel;
    }
    switch (resolvedPaymentKey) {
      case 'wallet':
        return 'محفظة';
      case 'visa':
        return 'فيزا / بطاقة';
      default:
        return 'الدفع عند الاستلام';
    }
  }

  String get orderTypeLabel {
    if (isPickup) return 'استلام ذاتي';
    final mode = (orderMode ?? '').trim().toLowerCase();
    if (mode == 'scheduled') return 'طلب مجدول';
    if (mode == 'preorder') return 'طلب مسبق';
    if (isScheduled) return 'طلب مجدول';
    return 'طلب عادي';
  }

  String get flowStatusKey {
    final raw = (flowStatus ?? '').trim().toLowerCase();
    if (raw.isEmpty) {
      return 'new';
    }
    if (raw == 'cancelled') {
      return 'canceled';
    }
    return raw;
  }

  bool get isCancelledOrder {
    final paymentStatus = (ordersStatus ?? '').trim().toLowerCase();
    final flowStatus = flowStatusKey;
    return paymentStatus == 'canceled' ||
        paymentStatus == 'failed' ||
        flowStatus == 'canceled' ||
        flowStatus == 'failed';
  }

  bool get isDeliveredOrder {
    final flowStatus = flowStatusKey;
    return flowStatus == 'delivered';
  }

  bool get isInDeliveryOrder {
    final flowStatus = flowStatusKey;
    return flowStatus == 'picked_up' ||
        flowStatus == 'heading_to_customer' ||
        flowStatus == 'arrived_at_customer';
  }

  bool get isPreparingOrder {
    final flowStatus = flowStatusKey;
    final paymentStatus = (ordersStatus ?? '').trim().toLowerCase();
    if (paymentStatus == 'paid') {
      return true;
    }
    return flowStatus == 'assigned' ||
        flowStatus == 'accepted' ||
        flowStatus == 'arrived_at_restaurant';
  }

  bool get isScheduledOrder {
    return scheduledDateTime != null &&
        scheduledDateTime!.isAfter(DateTime.now());
  }

  String get lifecycleBucket {
    if (isCancelledOrder) return 'canceled';
    if (isScheduledOrder) return 'scheduled';
    if (isDeliveredOrder) return 'delivered';
    if (isInDeliveryOrder) return 'in_delivery';
    if (isPreparingOrder) return 'preparing';
    return 'new';
  }

  String get lifecycleLabelAr {
    switch (lifecycleBucket) {
      case 'scheduled':
        return 'مجدول';
      case 'preparing':
        return 'قيد التحضير';
      case 'in_delivery':
        return 'في الطريق';
      case 'delivered':
        return 'مكتمل';
      case 'canceled':
        return 'ملغي';
      default:
        return 'جديد';
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['orders_id'] = ordersId;
    data['orders_usersid'] = ordersUsersid;
    data['users_name'] = usersName;
    data['users_email'] = usersEmail;
    data['address_city'] = addressCity;
    data['address_street'] = addressStreet;
    data['address_phone'] = addressPhone;
    data['orders_recipient_lat'] = ordersRecipientLat;
    data['orders_recipient_lng'] = ordersRecipientLng;
    data['store_latitude'] = storeLatitude;
    data['store_longitude'] = storeLongitude;
    data['orders_totalprice'] = ordersTotalprice;
    data['orders_paymentmethod'] = ordersPaymentmethod;
    data['payment_method'] = paymentMethod;
    data['payment_key'] = paymentKey;
    data['payment_label'] = paymentLabel;
    data['paid_amount'] = paidAmount;
    data['transaction_id'] = transactionId;
    data['orders_gateway_ref'] = gatewayRef;
    data['orders_status'] = ordersStatus;
    data['orders_gift_message'] = ordersGiftMessage;
    data['orders_delivery_note'] = ordersDeliveryNote;
    data['orders_rejection_reason'] = ordersRejectionReason;
    data['orders_datetime'] = ordersDatetime;
    data['order_mode'] = orderMode;
    data['scheduled_for'] = scheduledFor;
    data['orders_estimated_minutes'] = ordersEstimatedMinutes;
    data['orders_type'] = ordersType;
    data['delivery_id'] = deliveryId;
    data['orders_items_count'] = ordersItemsCount;
    data['driver_name'] = driverName;
    data['driver_phone'] = driverPhone;
    data['driver_status'] = driverStatus;
    data['assigned_at'] = assignedAt;
    data['accepted_at'] = acceptedAt;
    data['arrived_at_restaurant_at'] = arrivedAtRestaurantAt;
    data['picked_up_at'] = pickedUpAt;
    data['arrived_at_customer_at'] = arrivedAtCustomerAt;
    data['delivered_at'] = deliveredAt;
    data['status'] = flowStatus;
    data['delivery_code'] = deliveryCode;
    data['proof_type'] = proofType;
    data['proof_image'] = proofImage;
    data['vendor_id'] = vendorId;
    data['vendor_name'] = vendorName;
    data['store_name'] = storeName;
    return data;
  }
}

class OrderItemDetail {
  final int orderItemId;
  final int itemId;
  final String itemName;
  final String? itemColor;
  final String? itemSize;
  final double itemPrice;
  final int itemDiscount;
  final int quantity;
  final double? quantityWeight;
  final int vendorId;
  final String? lensCode;
  final String? lensName;
  final String? lensColor;
  final String? lensFeatures;
  final double lensUnitPrice;
  final double lensTotalPrice;
  final String? prescriptionJson;
  final String? prescriptionSummary;
  final String? foodItemNote;
  final String? foodMenuOptionsJson;
  final String? foodMenuOptionsSummary;
  final String? variantAttributesJson;
  final String? stockUnit;
  final double subtotal;
  final double lineTotal;
  final double totalAfterDiscount;

  const OrderItemDetail({
    required this.orderItemId,
    required this.itemId,
    required this.itemName,
    required this.itemColor,
    required this.itemSize,
    required this.itemPrice,
    required this.itemDiscount,
    required this.quantity,
    required this.quantityWeight,
    required this.vendorId,
    required this.lensCode,
    required this.lensName,
    required this.lensColor,
    required this.lensFeatures,
    required this.lensUnitPrice,
    required this.lensTotalPrice,
    required this.prescriptionJson,
    required this.prescriptionSummary,
    required this.foodItemNote,
    required this.foodMenuOptionsJson,
    required this.foodMenuOptionsSummary,
    required this.variantAttributesJson,
    required this.stockUnit,
    required this.subtotal,
    required this.lineTotal,
    required this.totalAfterDiscount,
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) {
    return OrderItemDetail(
      orderItemId: _toInt(json['order_item_id']),
      itemId: _toInt(json['item_id']),
      itemName: json['item_name']?.toString() ?? '',
      itemColor: json['item_color']?.toString(),
      itemSize: json['item_size']?.toString(),
      itemPrice: _toDouble(json['item_price']),
      itemDiscount: _toInt(json['item_discount']),
      quantity: _toInt(json['quantity']),
      quantityWeight: double.tryParse(json['quantity_weight']?.toString() ?? ''),
      vendorId: _toInt(json['vendor_id']),
      lensCode: json['lens_code']?.toString(),
      lensName: json['lens_name']?.toString(),
      lensColor: json['lens_color']?.toString(),
      lensFeatures: json['lens_features']?.toString(),
      lensUnitPrice: _toDouble(json['lens_unit_price']),
      lensTotalPrice: _toDouble(json['lens_total_price']),
      prescriptionJson: json['prescription_json']?.toString(),
      prescriptionSummary: json['prescription_summary']?.toString(),
      foodItemNote: json['food_item_note']?.toString(),
      foodMenuOptionsJson: json['food_menu_options_json']?.toString(),
      foodMenuOptionsSummary: json['food_menu_options_summary']?.toString(),
      variantAttributesJson: json['variant_attributes_json']?.toString(),
      stockUnit: json['stock_unit']?.toString(),
      subtotal: _toDouble(json['subtotal']),
      lineTotal: _toDouble(json['line_total']),
      totalAfterDiscount: _toDouble(json['total_after_discount']),
    );
  }

  bool get hasLens => lensName != null && lensName!.trim().isNotEmpty;
  bool get hasPrescription =>
      prescriptionSummary != null && prescriptionSummary!.trim().isNotEmpty;
  bool get hasFoodNote =>
      foodItemNote != null && foodItemNote!.trim().isNotEmpty;
  bool get hasFoodOptions =>
      foodMenuOptionsSummary != null &&
      foodMenuOptionsSummary!.trim().isNotEmpty;
  bool get isFrameOnly => !hasLens;

  double get frameTotal => totalAfterDiscount;

  List<String> get lensFeatureList {
    final raw = lensFeatures?.trim();
    if (raw == null || raw.isEmpty) return const [];
    var cleaned = raw
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .replaceAll('&#34;', '');
    return cleaned
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  String get orderTypeLabel {
    if (hasPrescription) return 'Prescription + Lens';
    if (hasLens) return 'Frame + Lens';
    return 'Frame Only';
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String? _firstNonEmptyString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
  }
  return null;
}
