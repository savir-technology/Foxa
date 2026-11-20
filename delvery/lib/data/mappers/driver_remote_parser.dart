import 'dart:convert';
import 'dart:math' as math;

import 'package:delvery/data/models/driver_models.dart';
import 'package:delvery/core/services/driver_platform_settings.dart';

class DriverRemoteParser {
  static DriverProfile parseProfile(dynamic raw, {String fallbackPhone = ''}) {
    final data = _asMap(raw);
    if (data.isEmpty) {
      return DriverProfile(
        id: '',
        name: fallbackPhone,
        phone: fallbackPhone,
        email: '',
        vendorId: 0,
        vendorName: '',
        storeName: '',
        vehicleType: 'Motorcycle',
        vehicleNumber: '',
      );
    }

    return DriverProfile(
      id:
          _string(data, ['driver_id', 'id', 'users_id', 'profile_id']) ??
          fallbackPhone,
      name:
          _string(data, ['name', 'driver_name', 'users_name', 'full_name']) ??
          fallbackPhone,
      phone:
          _string(data, ['phone', 'driver_phone', 'users_phone', 'mobile']) ??
          fallbackPhone,
      email:
          _string(data, ['email', 'driver_email', 'users_email', 'mail']) ?? '',
      vendorId: _int(data, ['vendor_id', 'assigned_vendor_id']) ?? 0,
      vendorName: _string(data, ['assigned_vendor_name', 'vendor_name']) ?? '',
      storeName: _string(data, ['assigned_store_name', 'store_name']) ?? '',
      photoUrl:
          _string(data, ['profile_image', 'photo_url', 'driver_photo']) ?? '',
      vehicleType:
          _string(data, [
            'vehicle_type',
            'vehicleType',
            'vehicle',
            'car_type',
          ]) ??
          'Motorcycle',
      vehicleNumber:
          _string(data, [
            'vehicle_number',
            'vehicleNumber',
            'plate_number',
            'plate',
          ]) ??
          '',
      profileCompleted:
          _bool(data, ['profile_completed', 'profileCompleted']) ?? false,
      approvalStatus:
          _string(data, ['approval_status', 'approvalStatus']) ?? 'pending',
      approvalNote: _string(data, ['approval_note', 'approvalNote']) ?? '',
    );
  }

  static DriverOrder? parseOrder(dynamic raw) {
    final data = _asMap(raw);
    if (data.isEmpty) {
      return null;
    }

    final status = _orderStatusFromString(
      _string(data, ['status', 'orders_status', 'order_status']) ?? '',
    );

    final restaurantLocation = _resolveCoordinate(
      data,
      latitudeKeys: [
        'restaurant_lat',
        'store_latitude',
        'restaurant_location_lat',
        'restaurant_location_latitude',
        'restaurantLatitude',
        'restaurant_latitude',
        'rest_lat',
        'store_lat',
      ],
      longitudeKeys: [
        'restaurant_lng',
        'store_longitude',
        'restaurant_location_lng',
        'restaurant_location_longitude',
        'restaurantLongitude',
        'restaurant_longitude',
        'rest_lng',
        'restaurant_long',
        'store_lng',
      ],
      textFallbackKeys: [
        'restaurant_address_name',
        'restaurant_address',
        'store_address',
        'vendor_address',
        'branch_address',
      ],
      mapKeys: ['restaurant_location', 'restaurant', 'store_location'],
    );

    final customerLocation = _resolveCoordinate(
      data,
      latitudeKeys: [
        'customer_lat',
        'recipient_lat',
        'recipient_location_lat',
        'recipient_location_latitude',
        'orders_recipient_lat',
        'orders_recipient_latitude',
        'orders_address_lat',
        'address_lat',
        'customer_latitude',
      ],
      longitudeKeys: [
        'customer_lng',
        'recipient_lng',
        'recipient_location_lng',
        'recipient_location_longitude',
        'orders_recipient_lng',
        'orders_recipient_longitude',
        'orders_address_long',
        'address_long',
        'customer_longitude',
      ],
      textFallbackKeys: [
        'customer_address_name',
        'customer_address',
        'recipient_address_name',
        'recipient_address',
        'orders_recipient_address_name',
        'orders_recipient_address_line',
      ],
      mapKeys: ['recipient_location', 'customer_location'],
    );

    final driverLocation =
        _coordinateFromMap(_mapValue(data['driver_location'])) ??
        DriverCoordinate(
          latitude:
              _double(data, ['driver_latitude', 'driver_current_latitude']) ??
              0,
          longitude:
              _double(data, ['driver_longitude', 'driver_current_longitude']) ??
              0,
        );

    final parsedDistance = _double(data, [
      'distance_km',
      'distanceKm',
      'distance',
      'order_distance',
    ]);
    final parsedRouteDistance = _double(data, [
      'route_distance_km',
      'routeDistanceKm',
      'route_distance',
    ]);
    final distanceKm = parsedDistance != null && parsedDistance > 0
        ? parsedDistance
        : _fallbackDistanceKm(
            driverLocation: driverLocation,
            restaurantLocation: restaurantLocation,
            customerLocation: customerLocation,
          );

    final items = _parseItems(
      data['items_json'] ??
          data['items'] ??
          data['order_items'] ??
          data['products'] ??
          data['cart'],
    );

    final totalPrice =
        _double(data, [
          'orders_totalprice',
          'orders_total_price',
          'total_price',
          'grand_total',
        ]) ??
        0;
    final deliveryFee =
        _double(data, [
          'orders_pricedelivery',
          'orders_delivery_fee',
          'delivery_fee',
          'shipping_fee',
        ]) ??
        0;
    final currency = _normalizeCurrency(
      _string(data, ['currency_symbol', 'currency', 'currency_code']) ?? '',
    );

    return DriverOrder(
      id: _int(data, ['id', 'order_id', 'orders_id', 'delivery_order_id']) ?? 0,
      vendorId: _int(data, ['vendor_id', 'assigned_vendor_id']) ?? 0,
      restaurantName:
          _string(data, [
            'restaurant_name',
            'store_name',
            'vendor_name',
            'restaurant',
          ]) ??
          'Restaurant',
      restaurantAddress:
          _string(data, [
            'restaurant_address',
            'restaurant_address_name',
            'store_address',
            'store_address_name',
            'address',
            'orders_restaurant_address',
          ]) ??
          '',
      restaurantPhone:
          _string(data, ['restaurant_phone', 'store_phone', 'vendor_phone']) ??
          '',
      restaurantLogoUrl:
          _string(data, [
            'restaurant_logo',
            'vendor_logo',
            'store_logo',
            'logo_url',
          ]) ??
          '',
      restaurantImageUrl:
          _string(data, [
            'restaurant_image',
            'store_image',
            'vendor_image',
            'image_url',
          ]) ??
          '',
      customerName:
          _string(data, [
            'customer_name',
            'recipient_name',
            'users_name',
            'name',
          ]) ??
          'Customer',
      customerPhone:
          _string(data, [
            'customer_phone',
            'recipient_phone',
            'orders_recipient_phone',
          ]) ??
          '',
      customerUserId:
          _string(data, [
            'orders_usersid',
            'customer_user_id',
            'user_id',
            'customer_id',
            'users_id',
            'recipient_id',
          ]) ??
          '',
      customerAddress:
          _string(data, [
            'customer_address',
            'customer_address_name',
            'customer_address_line',
            'recipient_address',
            'recipient_address_name',
            'recipient_address_line',
            'orders_recipient_address_name',
            'orders_recipient_address_line',
            'address',
            'orders_address',
          ]) ??
          '',
      zone:
          _string(data, ['zone', 'area', 'region', 'delivery_zone', 'city']) ??
          'Aleppo',
      distanceKm: distanceKm,
      routeDistanceKm: parsedRouteDistance != null && parsedRouteDistance > 0
          ? parsedRouteDistance
          : distanceKm,
      etaMinutes:
          _int(data, ['eta_minutes', 'etaMinutes', 'eta', 'minutes_eta']) ?? 0,
      status: status,
      items: items,
      customerNote:
          _string(data, [
            'customer_note',
            'delivery_note',
            'note',
            'orders_note',
          ]) ??
          '',
      giftMessage:
          _string(data, [
            'gift_message',
            'orders_gift_message',
            'customer_gift_message',
          ]) ??
          '',
      createdAt:
          _dateTime(data, [
            'created_at',
            'assigned_at',
            'updated_at',
            'orders_datetime',
          ]) ??
          DateTime.now(),
      restaurantLocation: restaurantLocation,
      customerLocation: customerLocation,
      deliveryCode:
          _string(data, ['delivery_code', 'proof_code', 'verification_code']) ??
          '',
      totalPrice: totalPrice,
      deliveryFee: deliveryFee,
      currency: currency,
    );
  }

  static List<DriverOrder> parseOrders(dynamic raw) {
    if (raw is List) {
      return raw
          .map(parseOrder)
          .whereType<DriverOrder>()
          .toList(growable: false);
    }
    final order = parseOrder(raw);
    return order == null ? <DriverOrder>[] : [order];
  }

  static List<DriverOrderItem> parseItems(dynamic raw) => _parseItems(raw);

  static DriverOrderStatus _orderStatusFromString(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'incoming':
      case 'pending':
      case 'new':
      case 'queued':
        return DriverOrderStatus.incoming;
      case 'assigned':
      case 'accepted':
      case 'dispatching':
        return DriverOrderStatus.assigned;
      case 'heading_to_restaurant':
      case 'heading_to_restauran':
      case 'to_restaurant':
      case 'restaurant':
      case 'on_the_way':
        return DriverOrderStatus.headingToRestaurant;
      case 'arrived_at_restaurant':
      case 'arrived_at_restauran':
      case 'at_restaurant':
      case 'restaurant_arrived':
        return DriverOrderStatus.arrivedAtRestaurant;
      case 'picked_up':
      case 'picked':
      case 'collected':
        return DriverOrderStatus.pickedUp;
      case 'heading_to_customer':
      case 'to_customer':
      case 'delivery':
      case 'in_transit':
        return DriverOrderStatus.headingToCustomer;
      case 'arrived_at_customer':
      case 'at_customer':
      case 'customer_arrived':
        return DriverOrderStatus.arrivedAtCustomer;
      case 'awaiting_delivery_code':
      case 'awaiting_verification':
      case 'awaiting_code':
      case 'proof_uploaded':
      case 'waiting_code':
        return DriverOrderStatus.awaitingVerification;
      case 'delivered':
      case 'completed':
      case 'done':
        return DriverOrderStatus.delivered;
      default:
        return DriverOrderStatus.assigned;
    }
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value));
    }
    return <String, dynamic>{};
  }

  static Map<String, dynamic> _mapValue(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value));
    }
    return <String, dynamic>{};
  }

  static DriverCoordinate? _coordinateFromMap(Map<String, dynamic> map) {
    final lat = _double(map, ['lat', 'latitude']);
    final lng = _double(map, ['lng', 'longitude']);
    if (lat == null || lng == null) {
      return null;
    }
    return DriverCoordinate(latitude: lat, longitude: lng);
  }

  static DriverCoordinate _resolveCoordinate(
    Map<String, dynamic> data, {
    required List<String> latitudeKeys,
    required List<String> longitudeKeys,
    List<String> textFallbackKeys = const [],
    List<String> mapKeys = const [],
  }) {
    final latitude = _double(data, latitudeKeys);
    final longitude = _double(data, longitudeKeys);
    if (latitude != null && longitude != null) {
      return DriverCoordinate(latitude: latitude, longitude: longitude);
    }

    for (final key in mapKeys) {
      final coordinate = _coordinateFromMap(_mapValue(data[key]));
      if (coordinate != null) {
        return DriverCoordinate(
          latitude: latitude ?? coordinate.latitude,
          longitude: longitude ?? coordinate.longitude,
        );
      }
    }

    for (final key in textFallbackKeys) {
      final coordinate = _coordinateFromText(data[key]);
      if (coordinate != null) {
        return DriverCoordinate(
          latitude: latitude ?? coordinate.latitude,
          longitude: longitude ?? coordinate.longitude,
        );
      }
    }

    return DriverCoordinate(latitude: latitude ?? 0, longitude: longitude ?? 0);
  }

  static DriverCoordinate? _coordinateFromText(dynamic raw) {
    if (raw == null) {
      return null;
    }

    final text = raw.toString().trim();
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

    return DriverCoordinate(latitude: latitude, longitude: longitude);
  }

  static String? _string(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return null;
  }

  static int? _int(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
      final parsedDouble = double.tryParse(value.toString());
      if (parsedDouble != null) return parsedDouble.round();
    }
    return null;
  }

  static bool? _bool(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim().toLowerCase();
      if (text.isEmpty) continue;
      if (text == '1' || text == 'true' || text == 'yes') {
        return true;
      }
      if (text == '0' || text == 'false' || text == 'no') {
        return false;
      }
    }
    return null;
  }

  static double? _double(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static DateTime? _dateTime(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static List<DriverOrderItem> _parseItems(dynamic raw) {
    if (raw == null) {
      return const <DriverOrderItem>[];
    }

    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
        return const <DriverOrderItem>[];
      }

      if ((trimmed.startsWith('[') && trimmed.endsWith(']')) ||
          (trimmed.startsWith('{') && trimmed.endsWith('}'))) {
        try {
          return _parseItems(jsonDecode(trimmed));
        } catch (_) {}
      }

      final parts = trimmed
          .split(RegExp(r'[\n,;]+'))
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList(growable: false);

      return parts
          .map((part) {
            final match = RegExp(r'^(\d+)\s*[xX×]\s*(.+)$').firstMatch(part);
            if (match != null) {
              return DriverOrderItem(
                quantity: int.tryParse(match.group(1) ?? '1') ?? 1,
                name: match.group(2)?.trim() ?? part,
              );
            }
            return DriverOrderItem(name: part, quantity: 1);
          })
          .toList(growable: false);
    }

    if (raw is List) {
      return raw
          .map((item) {
            if (item is Map) {
              final data = item.map((key, value) => MapEntry('$key', value));
              return _itemFromMap(data);
            }
            if (item is String) {
              return _parseItems(item).firstOrNull ??
                  DriverOrderItem(name: item, quantity: 1);
            }
            return DriverOrderItem(name: item.toString(), quantity: 1);
          })
          .toList(growable: false);
    }

    if (raw is Map) {
      final data = raw.map((key, value) => MapEntry('$key', value));
      return [_itemFromMap(data)];
    }

    return const <DriverOrderItem>[];
  }

  static DriverOrderItem _itemFromMap(Map<String, dynamic> data) {
    return DriverOrderItem(
      name:
          _string(data, [
            'name',
            'item_name',
            'title',
            'product_name',
            'food_name',
          ]) ??
          'Item',
      quantity: _int(data, ['quantity', 'count', 'qty', 'amount']) ?? 1,
      note: _string(data, ['note', 'item_note', 'remarks', 'food_item_note']),
      imageUrl:
          _string(data, [
            'image_url',
            'item_image',
            'items_image',
            'product_image',
            'image',
          ]) ??
          '',
      unitPrice:
          _double(data, [
            'unit_price',
            'price',
            'item_price',
            'product_price',
          ]) ??
          0,
      totalPrice:
          _double(data, ['line_total', 'subtotal', 'total_price', 'amount']) ??
          0,
      currency: _normalizeCurrency(
        _string(data, ['currency_symbol', 'currency', 'currency_code']) ?? '',
      ),
    );
  }

  static double _fallbackDistanceKm({
    required DriverCoordinate driverLocation,
    required DriverCoordinate restaurantLocation,
    required DriverCoordinate customerLocation,
  }) {
    if (_isValidCoordinate(driverLocation) &&
        _isValidCoordinate(customerLocation)) {
      return _distanceBetween(driverLocation, customerLocation);
    }

    if (_isValidCoordinate(restaurantLocation) &&
        _isValidCoordinate(customerLocation)) {
      return _distanceBetween(restaurantLocation, customerLocation);
    }

    return 0;
  }

  static bool _isValidCoordinate(DriverCoordinate coordinate) {
    return coordinate.latitude != 0 && coordinate.longitude != 0;
  }

  static double _distanceBetween(DriverCoordinate from, DriverCoordinate to) {
    const earthRadiusKm = 6371.0;
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);
    final deltaLat = _toRadians(to.latitude - from.latitude);
    final deltaLng = _toRadians(to.longitude - from.longitude);
    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(math.max(0, 1 - a)));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degree) => degree * math.pi / 180.0;

  static String _normalizeCurrency(String value) {
    return DriverPlatformSettings.currencySymbol.isNotEmpty
        ? DriverPlatformSettings.currencySymbol
        : DriverPlatformSettings.currencyCode;
  }
}

extension _FirstOrNullExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
