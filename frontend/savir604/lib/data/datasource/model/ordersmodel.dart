// ignore_for_file: unnecessary_new, prefer_collection_literals, unnecessary_this

class OrdersModel {
  String? ordersId;
  String? ordersUsersid;
  String? ordersAddress;
  String? ordersType;
  String? ordersPricedelivery;
  String? ordersPrice;
  String? ordersTotalprice;
  String? ordersCoupon;
  String? ordersPaymentmethod;
  String? ordersStatus;
  String? status;
  String? ordersDatetime;
  String? deliveredAt;
  String? ordersRecipientLabel;
  String? ordersRecipientName;
  String? ordersRecipientPhone;
  String? ordersRecipientAddressName;
  String? ordersRecipientAddressLine;
  String? ordersRecipientLocationNote;
  String? ordersRecipientLat;
  String? ordersRecipientLng;
  String? deliveryLatitude;
  String? deliveryLongitude;
  String? deliveryAddress;
  String? ordersGiftMessage;
  String? ordersDeliveryNote;
  String? ordersShareToken;
  String? orderMode;
  String? scheduledFor;
  String? ordersEstimatedMinutes;
  String? deliveryCode;
  String? deliveryId;
  String? vendorId;
  String? vendorName;
  String? storeName;
  String? storeSlug;
  String? vendorLogo;
  String? storeBannerUrl;
  String? vendorDescription;
  String? storeAddress;
  String? storeLatitude;
  String? storeLongitude;
  String? addressId;
  String? addressUsersid;
  String? addressName;
  String? addressCity;
  String? addressStreet;
  String? addressLat;
  String? addressLong;

  OrdersModel({
    this.ordersId,
    this.ordersUsersid,
    this.ordersAddress,
    this.ordersType,
    this.ordersPricedelivery,
    this.ordersPrice,
    this.ordersTotalprice,
    this.ordersCoupon,
    this.ordersPaymentmethod,
    this.ordersStatus,
    this.status,
    this.ordersDatetime,
    this.deliveredAt,
    this.ordersRecipientLabel,
    this.ordersRecipientName,
    this.ordersRecipientPhone,
    this.ordersRecipientAddressName,
    this.ordersRecipientAddressLine,
    this.ordersRecipientLocationNote,
    this.ordersRecipientLat,
    this.ordersRecipientLng,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryAddress,
    this.ordersGiftMessage,
    this.ordersDeliveryNote,
    this.ordersShareToken,
    this.orderMode,
    this.scheduledFor,
    this.ordersEstimatedMinutes,
    this.deliveryCode,
    this.deliveryId,
    this.vendorId,
    this.vendorName,
    this.storeName,
    this.storeSlug,
    this.vendorLogo,
    this.storeBannerUrl,
    this.vendorDescription,
    this.storeAddress,
    this.storeLatitude,
    this.storeLongitude,
    this.addressId,
    this.addressUsersid,
    this.addressName,
    this.addressCity,
    this.addressStreet,
    this.addressLat,
    this.addressLong,
  });

  OrdersModel.fromJson(Map<String, dynamic> json) {
    ordersId = json['orders_id']?.toString();
    ordersUsersid = json['orders_usersid']?.toString();
    ordersAddress = json['orders_address']?.toString();
    ordersType = json['orders_type']?.toString();
    ordersPricedelivery = json['orders_pricedelivery']?.toString();
    ordersPrice = json['orders_price']?.toString();
    ordersTotalprice = json['orders_totalprice']?.toString();
    ordersCoupon = json['orders_coupon']?.toString();
    ordersPaymentmethod = json['orders_paymentmethod']?.toString();
    ordersStatus = json['orders_status']?.toString();
    status = json['status']?.toString();
    ordersDatetime = json['orders_datetime']?.toString();
    deliveredAt = json['delivered_at']?.toString();
    ordersRecipientLabel = json['orders_recipient_label']?.toString();
    ordersRecipientName = json['orders_recipient_name']?.toString();
    ordersRecipientPhone = json['orders_recipient_phone']?.toString();
    ordersRecipientAddressName =
        json['orders_recipient_address_name']?.toString();
    ordersRecipientAddressLine =
        json['orders_recipient_address_line']?.toString();
    ordersRecipientLocationNote =
        json['orders_recipient_location_note']?.toString();
    ordersRecipientLat = json['orders_recipient_lat']?.toString();
    ordersRecipientLng = json['orders_recipient_lng']?.toString();
    deliveryLatitude = json['delivery_latitude']?.toString();
    deliveryLongitude = json['delivery_longitude']?.toString();
    deliveryAddress = json['delivery_address']?.toString();
    ordersGiftMessage = json['orders_gift_message']?.toString() ??
        json['gift_message']?.toString();
    ordersDeliveryNote = json['orders_delivery_note']?.toString() ??
        json['delivery_note']?.toString();
    ordersShareToken = json['orders_share_token']?.toString();
    orderMode = json['order_mode']?.toString();
    scheduledFor = json['scheduled_for']?.toString();
    ordersEstimatedMinutes = json['orders_estimated_minutes']?.toString();
    deliveryCode = json['delivery_code']?.toString();
    deliveryId = json['delivery_id']?.toString();
    vendorId = json['vendor_id']?.toString();
    vendorName = json['vendor_name']?.toString();
    storeName = json['store_name']?.toString();
    storeSlug = json['store_slug']?.toString();
    vendorLogo = json['vendor_logo']?.toString();
    storeBannerUrl = json['store_banner_url']?.toString();
    vendorDescription = json['vendor_description']?.toString();
    storeAddress = json['store_address']?.toString();
    storeLatitude = json['store_latitude']?.toString();
    storeLongitude = json['store_longitude']?.toString();
    addressId = json['address_id']?.toString();
    addressUsersid = json['address_usersid']?.toString();
    addressName = json['address_name']?.toString();
    addressCity = json['address_city']?.toString();
    addressStreet = json['address_street']?.toString();
    addressLat = json['address_lat']?.toString();
    addressLong = json['address_long']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['orders_id'] = this.ordersId;
    data['orders_usersid'] = this.ordersUsersid;
    data['orders_address'] = this.ordersAddress;
    data['orders_type'] = this.ordersType;
    data['orders_pricedelivery'] = this.ordersPricedelivery;
    data['orders_price'] = this.ordersPrice;
    data['orders_totalprice'] = this.ordersTotalprice;
    data['orders_coupon'] = this.ordersCoupon;
    data['orders_paymentmethod'] = this.ordersPaymentmethod;
    data['orders_status'] = this.ordersStatus;
    data['status'] = this.status;
    data['orders_datetime'] = this.ordersDatetime;
    data['delivered_at'] = this.deliveredAt;
    data['orders_recipient_label'] = this.ordersRecipientLabel;
    data['orders_recipient_name'] = this.ordersRecipientName;
    data['orders_recipient_phone'] = this.ordersRecipientPhone;
    data['orders_recipient_address_name'] = this.ordersRecipientAddressName;
    data['orders_recipient_address_line'] = this.ordersRecipientAddressLine;
    data['orders_recipient_location_note'] = this.ordersRecipientLocationNote;
    data['orders_recipient_lat'] = this.ordersRecipientLat;
    data['orders_recipient_lng'] = this.ordersRecipientLng;
    data['delivery_latitude'] = this.deliveryLatitude;
    data['delivery_longitude'] = this.deliveryLongitude;
    data['delivery_address'] = this.deliveryAddress;
    data['orders_gift_message'] = this.ordersGiftMessage;
    data['orders_delivery_note'] = this.ordersDeliveryNote;
    data['orders_share_token'] = this.ordersShareToken;
    data['order_mode'] = this.orderMode;
    data['scheduled_for'] = this.scheduledFor;
    data['orders_estimated_minutes'] = this.ordersEstimatedMinutes;
    data['delivery_code'] = this.deliveryCode;
    data['delivery_id'] = this.deliveryId;
    data['vendor_id'] = this.vendorId;
    data['vendor_name'] = this.vendorName;
    data['store_name'] = this.storeName;
    data['store_slug'] = this.storeSlug;
    data['vendor_logo'] = this.vendorLogo;
    data['store_banner_url'] = this.storeBannerUrl;
    data['vendor_description'] = this.vendorDescription;
    data['store_address'] = this.storeAddress;
    data['store_latitude'] = this.storeLatitude;
    data['store_longitude'] = this.storeLongitude;
    data['address_id'] = this.addressId;
    data['address_usersid'] = this.addressUsersid;
    data['address_name'] = this.addressName;
    data['address_city'] = this.addressCity;
    data['address_street'] = this.addressStreet;
    data['address_lat'] = this.addressLat;
    data['address_long'] = this.addressLong;
    return data;
  }

  double? get resolvedRecipientLatitude {
    return _parseCoordinate(deliveryLatitude) ??
        _parseCoordinate(ordersRecipientLat) ??
        _parseCoordinatePair(
          '$ordersRecipientAddressName $ordersRecipientAddressLine',
        )?.latitude ??
        _parseCoordinatePair('$addressName $addressStreet')?.latitude;
  }

  double? get resolvedRecipientLongitude {
    return _parseCoordinate(deliveryLongitude) ??
        _parseCoordinate(ordersRecipientLng) ??
        _parseCoordinatePair(
          '$ordersRecipientAddressName $ordersRecipientAddressLine',
        )?.longitude ??
        _parseCoordinatePair('$addressName $addressStreet')?.longitude;
  }

  double? get resolvedDeliveryLatitude {
    return _parseCoordinate(deliveryLatitude) ??
        _parseCoordinate(ordersRecipientLat) ??
        _parseCoordinate(addressLat) ??
        _parseCoordinatePair(deliveryAddress)?.latitude ??
        _parseCoordinatePair(
          '$ordersRecipientAddressName $ordersRecipientAddressLine',
        )?.latitude ??
        _parseCoordinatePair('$addressName $addressStreet')?.latitude;
  }

  double? get resolvedDeliveryLongitude {
    return _parseCoordinate(deliveryLongitude) ??
        _parseCoordinate(ordersRecipientLng) ??
        _parseCoordinate(addressLong) ??
        _parseCoordinatePair(deliveryAddress)?.longitude ??
        _parseCoordinatePair(
          '$ordersRecipientAddressName $ordersRecipientAddressLine',
        )?.longitude ??
        _parseCoordinatePair('$addressName $addressStreet')?.longitude;
  }

  double? get resolvedAddressLatitude {
    return _parseCoordinate(addressLat) ??
        _parseCoordinatePair('$addressName $addressStreet')?.latitude;
  }

  double? get resolvedAddressLongitude {
    return _parseCoordinate(addressLong) ??
        _parseCoordinatePair('$addressName $addressStreet')?.longitude;
  }

  double? get resolvedRestaurantLatitude {
    return _parseCoordinate(storeLatitude);
  }

  double? get resolvedRestaurantLongitude {
    return _parseCoordinate(storeLongitude);
  }

  String get restaurantDisplayName {
    final names = <String>[
      storeName ?? '',
      vendorName ?? '',
    ].where((item) => item.trim().isNotEmpty).toList();
    return names.isEmpty ? 'Restaurant' : names.first.trim();
  }

  String get restaurantAddressText {
    final parts = <String>[
      storeAddress ?? '',
      vendorDescription ?? '',
    ].where((item) => item.trim().isNotEmpty).toList();
    return parts.isEmpty ? '' : parts.join(', ');
  }
  String get deliveryDisplayAddress {
    final parts = <String>[
      deliveryAddress ?? '',
      ordersRecipientAddressName ?? '',
      ordersRecipientAddressLine ?? '',
      ordersRecipientLocationNote ?? '',
      addressName ?? '',
      addressStreet ?? '',
      addressCity ?? '',
    ].where((item) => item.trim().isNotEmpty).toList();
    return parts.isEmpty ? '' : parts.join(', ');
  }
  bool get isDeliveredOrder {
    final candidates = <String?>[
      status,
      ordersStatus,
    ];
    for (final candidate in candidates) {
      final normalized = candidate?.trim().toLowerCase() ?? '';
      if (normalized == 'delivered' ||
          normalized == 'completed' ||
          normalized == '4') {
        return true;
      }
    }

    final delivered = deliveredAt?.trim() ?? '';
    return delivered.isNotEmpty && delivered.toLowerCase() != 'null';
  }
}

class _CoordinatePair {
  const _CoordinatePair({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

double? _parseCoordinate(String? value) {
  if (value == null) {
    return null;
  }

  final text = value.trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }

  final number = double.tryParse(text);
  if (number == null || number == 0) {
    return null;
  }

  return number;
}

_CoordinatePair? _parseCoordinatePair(String? value) {
  if (value == null) {
    return null;
  }

  final text = value.trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }

  final match = RegExp(
    r'(-?\d+(?:\.\d+)?)\s*[,;|\s]+\s*(-?\d+(?:\.\d+)?)',
  ).firstMatch(text);
  if (match == null) {
    return null;
  }

  final latitude = double.tryParse(match.group(1) ?? '');
  final longitude = double.tryParse(match.group(2) ?? '');
  if (latitude == null || longitude == null) {
    return null;
  }

  if (latitude == 0 && longitude == 0) {
    return null;
  }

  return _CoordinatePair(latitude: latitude, longitude: longitude);
}
