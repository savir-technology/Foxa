import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:tks/core/services/mapbox_runtime_config.dart';
import 'package:tks/linkapi/linkapi.dart';
import 'package:tks/data/datasource/model/ordersmodel.dart';
import 'package:tks/firebase_options.dart';

class TrackingCoordinate {
  const TrackingCoordinate({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  bool get isValid => latitude != 0 && longitude != 0;
}

class TrackingDriverInfo {
  const TrackingDriverInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.photoUrl,
  });

  final String id;
  final String name;
  final String phone;
  final String vehicle;
  final String photoUrl;

  bool get hasId => id.trim().isNotEmpty;
  bool get hasPhone => phone.trim().isNotEmpty;
  bool get hasPhoto => photoUrl.trim().isNotEmpty;
}

class OrderTrackingLiveSnapshot {
  const OrderTrackingLiveSnapshot({
    required this.status,
    required this.etaMinutes,
    required this.routeDistanceKm,
    required this.hasLiveData,
    required this.lastUpdated,
    required this.driver,
    required this.restaurantLocation,
    required this.driverLocation,
    required this.recipientLocation,
    required this.deliveryProofImageUrl,
    required this.supportPhone,
    required this.sharePath,
  });

  final String status;
  final int etaMinutes;
  final double routeDistanceKm;
  final bool hasLiveData;
  final DateTime? lastUpdated;
  final TrackingDriverInfo driver;
  final TrackingCoordinate? restaurantLocation;
  final TrackingCoordinate? driverLocation;
  final TrackingCoordinate? recipientLocation;
  final String deliveryProofImageUrl;
  final String supportPhone;
  final String sharePath;

  bool get hasDeliveryProof => deliveryProofImageUrl.trim().isNotEmpty;
  bool get hasSupportPhone => supportPhone.trim().isNotEmpty;

  OrderTrackingLiveSnapshot copyWith({
    String? status,
    int? etaMinutes,
    double? routeDistanceKm,
    bool? hasLiveData,
    DateTime? lastUpdated,
    TrackingDriverInfo? driver,
    TrackingCoordinate? restaurantLocation,
    TrackingCoordinate? driverLocation,
    TrackingCoordinate? recipientLocation,
    String? deliveryProofImageUrl,
    String? supportPhone,
    String? sharePath,
  }) {
    return OrderTrackingLiveSnapshot(
      status: status ?? this.status,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      routeDistanceKm: routeDistanceKm ?? this.routeDistanceKm,
      hasLiveData: hasLiveData ?? this.hasLiveData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      driver: driver ?? this.driver,
      restaurantLocation: restaurantLocation ?? this.restaurantLocation,
      driverLocation: driverLocation ?? this.driverLocation,
      recipientLocation: recipientLocation ?? this.recipientLocation,
      deliveryProofImageUrl:
          deliveryProofImageUrl ?? this.deliveryProofImageUrl,
      supportPhone: supportPhone ?? this.supportPhone,
      sharePath: sharePath ?? this.sharePath,
    );
  }
}

class OrderTrackingRealtimeService {
  OrderTrackingRealtimeService({FirebaseDatabase? database})
      : _database = database ??
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL ??
                  'https://savirv604-default-rtdb.firebaseio.com',
            );

  final FirebaseDatabase _database;

  Stream<OrderTrackingLiveSnapshot> watchOrder(OrdersModel order) async* {
    final recipientLocation = await _resolveRecipientLocation(order);
    final restaurantLocation = await _resolveRestaurantLocation(order);
    yield await _enrichWithDriverFallback(
      order,
      _fallbackSnapshot(
        order,
        recipientLocation: recipientLocation,
        restaurantLocation: restaurantLocation,
      ),
    );

    final orderId = (order.ordersId ?? '').trim();
    if (orderId.isEmpty) {
      return;
    }

    final ref = _database.ref('order_tracking/$orderId');
    await for (final event in ref.onValue) {
      final raw = event.snapshot.value;
      if (raw is Map) {
        yield await _enrichWithDriverFallback(
          order,
          _fromMap(
            order,
            Map<Object?, Object?>.from(raw),
            fallbackRecipientLocation: recipientLocation,
            fallbackRestaurantLocation: restaurantLocation,
          ),
        );
      }
    }
  }

  Future<OrderTrackingLiveSnapshot> _enrichWithDriverFallback(
    OrdersModel order,
    OrderTrackingLiveSnapshot snapshot,
  ) async {
    final driver = snapshot.driver;
    final driverId = _driverIdFromOrder(order, driver.id);
    final needsDriverFallback = snapshot.driverLocation?.isValid != true ||
        !driver.hasId ||
        driver.name.trim().isEmpty ||
        driver.phone.trim().isEmpty ||
        driver.vehicle.trim().isEmpty;

    if (!needsDriverFallback || driverId <= 0) {
      return snapshot;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppLink.server}/driver_dashboard.php'),
        body: {'driver_id': driverId.toString()},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return snapshot;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return snapshot;
      }

      final map = decoded.map((key, value) => MapEntry('$key', value));
      if (map['status']?.toString().toLowerCase() != 'success') {
        return snapshot;
      }

      final activeOrderMap = _mapValue(
        map['active_order'] ??
            map['activeOrder'] ??
            map['current_order'] ??
            map['currentOrder'],
      );
      final incomingOrderMap = _mapValue(
        map['incoming_order'] ??
            map['incomingOrder'] ??
            map['pending_order'] ??
            map['pendingOrder'],
      );
      final profileRaw = map['profile'] ?? map['data'] ?? map['driver'];
      if (profileRaw is! Map) {
        return snapshot;
      }

      final profile = profileRaw.map((key, value) => MapEntry('$key', value));
      final fallbackDriverLocation = _coordinateFromMap({
            'lat': profile['latitude'],
            'lng': profile['longitude'],
          }) ??
          _coordinateFromKeyPairs(activeOrderMap, const [
            ['driver_current_latitude', 'driver_current_longitude'],
            ['driver_latitude', 'driver_longitude'],
          ]) ??
          _coordinateFromKeyPairs(incomingOrderMap, const [
            ['driver_current_latitude', 'driver_current_longitude'],
            ['driver_latitude', 'driver_longitude'],
          ]);
      final driverVehicleParts = <String>[
        _stringValue(profile['vehicle_type']),
        _stringValue(profile['vehicle_number']),
      ].where((part) => part.trim().isNotEmpty).toList();

      return snapshot.copyWith(
        hasLiveData: true,
        driver: TrackingDriverInfo(
          id: _stringValue(profile['id']).ifEmpty(driver.id),
          name: _stringValue(profile['name']).ifEmpty(driver.name),
          phone: _stringValue(profile['phone']).ifEmpty(driver.phone),
          vehicle: driverVehicleParts.isEmpty
              ? driver.vehicle
              : driverVehicleParts.join(' - '),
          photoUrl: driver.photoUrl,
        ),
        driverLocation: snapshot.driverLocation?.isValid == true
            ? snapshot.driverLocation
            : fallbackDriverLocation,
      );
    } catch (_) {
      return snapshot;
    }
  }

  OrderTrackingLiveSnapshot _fallbackSnapshot(
    OrdersModel order, {
    TrackingCoordinate? recipientLocation,
    TrackingCoordinate? restaurantLocation,
  }) {
    final defaultStatus = (order.ordersStatus ?? 'pending').trim();
    final defaultEta = int.tryParse(order.ordersEstimatedMinutes ?? '') ?? 45;
    final restaurant = restaurantLocation;

    return OrderTrackingLiveSnapshot(
      status: defaultStatus.isEmpty ? 'pending' : defaultStatus,
      etaMinutes: defaultEta,
      routeDistanceKm: restaurant != null && recipientLocation != null
          ? _distanceBetween(restaurant, recipientLocation)
          : 0,
      hasLiveData: false,
      lastUpdated: DateTime.now(),
      driver: const TrackingDriverInfo(
        id: '',
        name: '',
        phone: '',
        vehicle: '',
        photoUrl: '',
      ),
      restaurantLocation: restaurant,
      driverLocation: null,
      recipientLocation: recipientLocation,
      deliveryProofImageUrl: '',
      supportPhone: '',
      sharePath: '',
    );
  }

  OrderTrackingLiveSnapshot _fromMap(
    OrdersModel order,
    Map<Object?, Object?> raw, {
    TrackingCoordinate? fallbackRecipientLocation,
    TrackingCoordinate? fallbackRestaurantLocation,
  }) {
    final fallback = _fallbackSnapshot(
      order,
      recipientLocation: fallbackRecipientLocation,
      restaurantLocation: fallbackRestaurantLocation,
    );
    final map = raw.map(
      (key, value) => MapEntry('$key', value),
    );
    final driverMap = _mapValue(map['driver']);
    final restaurantLocationMap = _mapValue(map['restaurant_location']);
    final driverLocationMap = _mapValue(map['driver_location']);
    final recipientLocationMap = _mapValue(map['recipient_location']);
    final deliveryLocationMap = _mapValue(map['delivery_location']);
    final proofMap = _mapValue(map['delivery_proof']);
    final resolvedDriverLocation = _coordinateFromMap(driverLocationMap) ??
        _coordinateFromKeyPairs(map, const [
          ['driver_latitude', 'driver_longitude'],
          ['driver_current_latitude', 'driver_current_longitude'],
          ['driver_location_lat', 'driver_location_lng'],
        ]);
    final resolvedRecipientLocation =
        _coordinateFromMap(recipientLocationMap) ??
            _coordinateFromMap(deliveryLocationMap) ??
            _coordinateFromKeyPairs(map, const [
              ['delivery_latitude', 'delivery_longitude'],
              ['recipient_latitude', 'recipient_longitude'],
              ['recipient_lat', 'recipient_lng'],
              ['orders_recipient_lat', 'orders_recipient_lng'],
            ]) ??
            fallback.recipientLocation;
    final resolvedRestaurantLocation =
        _coordinateFromMap(restaurantLocationMap) ??
            _coordinateFromKeyPairs(map, const [
              ['restaurant_latitude', 'restaurant_longitude'],
              ['restaurant_lat', 'restaurant_lng'],
              ['store_latitude', 'store_longitude'],
            ]) ??
            fallback.restaurantLocation;

    return OrderTrackingLiveSnapshot(
      status: _stringValue(map['status']).ifEmpty(fallback.status),
      etaMinutes: _intValue(map['eta_minutes']) ?? fallback.etaMinutes,
      routeDistanceKm: _doubleValue(map['route_distance_km']) ??
          _doubleValue(map['distance_km']) ??
          (resolvedDriverLocation != null && resolvedRecipientLocation != null
              ? _distanceBetween(
                  resolvedDriverLocation,
                  resolvedRecipientLocation,
                )
              : resolvedRestaurantLocation != null &&
                      resolvedRecipientLocation != null
                  ? _distanceBetween(
                      resolvedRestaurantLocation,
                      resolvedRecipientLocation,
                    )
                  : fallback.routeDistanceKm),
      hasLiveData: true,
      lastUpdated: _dateValue(map['last_updated']) ?? fallback.lastUpdated,
      driver: TrackingDriverInfo(
        id: _stringValue(map['driver_id']) != ''
            ? _stringValue(map['driver_id'])
            : _stringValue(driverMap['id']),
        name: _stringValue(driverMap['name']),
        phone: _stringValue(driverMap['phone']),
        vehicle: _stringValue(driverMap['vehicle']),
        photoUrl: _stringValue(driverMap['photo_url']),
      ),
      restaurantLocation: resolvedRestaurantLocation,
      driverLocation: resolvedDriverLocation,
      recipientLocation: resolvedRecipientLocation,
      deliveryProofImageUrl: _stringValue(
        proofMap['image_url'] ?? map['delivery_proof_image_url'],
      ),
      supportPhone: _stringValue(map['support_phone']),
      sharePath: _stringValue(map['share_path']),
    );
  }

  int _driverIdFromOrder(OrdersModel order, String snapshotDriverId) {
    final id = snapshotDriverId.trim().isNotEmpty
        ? snapshotDriverId.trim()
        : (order.deliveryId ?? '').trim();
    return int.tryParse(id) ?? 0;
  }

  Future<TrackingCoordinate?> _resolveRecipientLocation(
    OrdersModel order,
  ) async {
    final lat = order.resolvedDeliveryLatitude ??
        order.resolvedRecipientLatitude ??
        order.resolvedAddressLatitude;
    final lng = order.resolvedDeliveryLongitude ??
        order.resolvedRecipientLongitude ??
        order.resolvedAddressLongitude;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return TrackingCoordinate(latitude: lat, longitude: lng);
    }

    return await _geocodeDeliveryAddress(order);
  }

  Future<TrackingCoordinate?> _resolveRestaurantLocation(
    OrdersModel order,
  ) async {
    final lat = order.resolvedRestaurantLatitude;
    final lng = order.resolvedRestaurantLongitude;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return TrackingCoordinate(latitude: lat, longitude: lng);
    }

    return await _geocodeRestaurantAddress(order);
  }

  Future<TrackingCoordinate?> _geocodeDeliveryAddress(
    OrdersModel order,
  ) async {
    final token = MapboxRuntimeConfig.accessToken;
    if (token.isEmpty) {
      return null;
    }

    final queryParts = <String>[
      (order.deliveryAddress ?? '').trim(),
      (order.ordersRecipientAddressName ?? '').trim(),
      (order.ordersRecipientAddressLine ?? '').trim(),
      (order.ordersRecipientLocationNote ?? '').trim(),
      (order.addressStreet ?? '').trim(),
      (order.addressCity ?? '').trim(),
    ].where((part) => part.isNotEmpty).toList();

    if (queryParts.isEmpty) {
      return null;
    }

    final uri = Uri.https(
      'api.mapbox.com',
      '/geocoding/v5/mapbox.places/${Uri.encodeComponent(queryParts.join(', '))}.json',
      <String, String>{
        'limit': '1',
        'country': 'SY',
        'language': 'ar',
        'types': 'address,place,poi',
        'access_token': token,
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final features = (payload['features'] as List?) ?? const [];
      if (features.isEmpty || features.first is! Map) {
        return null;
      }

      final feature = Map<String, dynamic>.from(features.first as Map);
      final center = (feature['center'] as List?) ?? const [];
      if (center.length < 2) {
        return null;
      }

      final lng = (center[0] as num?)?.toDouble();
      final lat = (center[1] as num?)?.toDouble();
      if (lat == null || lng == null) {
        return null;
      }

      return TrackingCoordinate(latitude: lat, longitude: lng);
    } catch (_) {
      return null;
    }
  }

  Future<TrackingCoordinate?> _geocodeRestaurantAddress(
    OrdersModel order,
  ) async {
    final token = MapboxRuntimeConfig.accessToken;
    if (token.isEmpty) {
      return null;
    }

    final queryParts = <String>[
      order.storeName ?? '',
      order.storeAddress ?? '',
      order.vendorDescription ?? '',
      order.vendorName ?? '',
      order.addressCity ?? '',
    ].where((part) => part.trim().isNotEmpty).toList();

    if (queryParts.isEmpty) {
      return null;
    }

    final uri = Uri.https(
      'api.mapbox.com',
      '/geocoding/v5/mapbox.places/${Uri.encodeComponent(queryParts.join(', '))}.json',
      <String, String>{
        'limit': '1',
        'country': 'SY',
        'language': 'ar',
        'types': 'address,place,poi',
        'access_token': token,
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final features = (payload['features'] as List?) ?? const [];
      if (features.isEmpty || features.first is! Map) {
        return null;
      }

      final feature = Map<String, dynamic>.from(features.first as Map);
      final center = (feature['center'] as List?) ?? const [];
      if (center.length < 2) {
        return null;
      }

      final lng = (center[0] as num?)?.toDouble();
      final lat = (center[1] as num?)?.toDouble();
      if (lat == null || lng == null) {
        return null;
      }

      return TrackingCoordinate(latitude: lat, longitude: lng);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _mapValue(Object? value) {
    if (value is Map) {
      return value.map((key, innerValue) => MapEntry('$key', innerValue));
    }
    return const <String, dynamic>{};
  }

  TrackingCoordinate? _coordinateFromMap(Map<String, dynamic> map) {
    final lat = _doubleValue(map['lat'] ?? map['latitude']);
    final lng = _doubleValue(map['lng'] ?? map['longitude']);
    if (lat == null || lng == null) {
      return null;
    }
    if (lat == 0 || lng == 0) {
      return null;
    }
    return TrackingCoordinate(latitude: lat, longitude: lng);
  }

  TrackingCoordinate? _coordinateFromKeyPairs(
    Map<String, dynamic> map,
    List<List<String>> pairs,
  ) {
    for (final pair in pairs) {
      if (pair.length < 2) continue;
      final lat = _doubleValue(map[pair[0]]);
      final lng = _doubleValue(map[pair[1]]);
      if (lat != null && lng != null && lat != 0 && lng != 0) {
        return TrackingCoordinate(latitude: lat, longitude: lng);
      }
    }
    return null;
  }

  String _stringValue(Object? value) => value?.toString().trim() ?? '';

  int? _intValue(Object? value) => int.tryParse(_stringValue(value));

  double? _doubleValue(Object? value) => double.tryParse(_stringValue(value));

  DateTime? _dateValue(Object? value) {
    final raw = _stringValue(value);
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  double _distanceBetween(TrackingCoordinate from, TrackingCoordinate to) {
    const earthRadiusKm = 6371.0;
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);
    final deltaLat = _toRadians(to.latitude - from.latitude);
    final deltaLng = _toRadians(to.longitude - from.longitude);
    final a = (math.sin(deltaLat / 2) * math.sin(deltaLat / 2)) +
        (math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(math.max(0, 1 - a)));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) => degree * math.pi / 180.0;
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
