import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:tks/core/services/order_tracking_realtime_service.dart';
import 'package:tks/features/navigation/domain/entities/navigation_route_bundle.dart';

class OrderTrackingMapService {
  static const String _routeSourceId = 'order-tracking-route-source';
  static const String _routeLayerId = 'order-tracking-route-layer';

  MapboxMap? _mapboxMap;
  GeoJsonSource? _routeSource;
  CircleAnnotationManager? _driverPulseManager;
  PointAnnotationManager? _driverMarkerManager;
  PointAnnotationManager? _restaurantMarkerManager;
  CircleAnnotationManager? _recipientMarkerManager;
  final Map<String, Uint8List> _driverMarkerImageCache = {};
  final Map<String, Uint8List> _restaurantMarkerImageCache = {};

  Future<void> attachMap(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
  }

  Future<void> prepareMapStyle() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }

    final style = mapboxMap.style;
    try {
      await style.removeStyleLayer(_routeLayerId);
    } catch (_) {}
    try {
      await style.removeStyleSource(_routeSourceId);
    } catch (_) {}

    _routeSource = GeoJsonSource(
      id: _routeSourceId,
      lineMetrics: true,
      data: _emptyRouteGeoJson(),
    );
    await style.addSource(_routeSource!);
    await style.addLayer(
      LineLayer(
        id: _routeLayerId,
        sourceId: _routeSourceId,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
        lineColor: const Color(0xFFFF6500).toARGB32(),
        lineWidth: 8.0,
        lineOpacity: 0.96,
        lineBorderColor: const Color(0x33212121).toARGB32(),
        lineBorderWidth: 2.0,
      ),
    );

    _driverPulseManager ??=
        await mapboxMap.annotations.createCircleAnnotationManager();
    _driverMarkerManager ??=
        await mapboxMap.annotations.createPointAnnotationManager();
    _restaurantMarkerManager ??=
        await mapboxMap.annotations.createPointAnnotationManager();
    _recipientMarkerManager ??=
        await mapboxMap.annotations.createCircleAnnotationManager();
  }

  Future<void> renderMarkers({
    TrackingCoordinate? driverLocation,
    TrackingCoordinate? restaurantLocation,
    TrackingCoordinate? recipientLocation,
    bool driverIsActive = true,
    bool restaurantIsActive = true,
    String? driverVehicleType,
  }) async {
    final driverPulseManager = _driverPulseManager;
    final driverManager = _driverMarkerManager;
    final restaurantManager = _restaurantMarkerManager;
    final recipientManager = _recipientMarkerManager;
    if (driverPulseManager == null ||
        driverManager == null ||
        restaurantManager == null ||
        recipientManager == null) {
      return;
    }

    await driverPulseManager.deleteAll();
    await driverManager.deleteAll();
    await restaurantManager.deleteAll();
    await recipientManager.deleteAll();

    if (driverLocation != null && driverLocation.isValid) {
      await driverPulseManager.create(
        CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              driverLocation.longitude,
              driverLocation.latitude,
            ),
          ),
          circleColor: (driverIsActive
                  ? const Color(0xFFFF6500)
                  : const Color(0xFF8A8A8A))
              .withValues(alpha: 0.20)
              .toARGB32(),
          circleRadius: 26,
          circleStrokeColor: Colors.white.withValues(alpha: 0.10).toARGB32(),
          circleStrokeWidth: 1.5,
        ),
      );

      await driverManager.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              driverLocation.longitude,
              driverLocation.latitude,
            ),
          ),
          image: await _buildDriverMarkerImage(
            driverIsActive: driverIsActive,
            driverVehicleType: driverVehicleType ?? '',
          ),
          iconAnchor: IconAnchor.CENTER,
          iconSize: 1.0,
          symbolSortKey: 20,
        ),
      );
    }

    if (restaurantLocation != null && restaurantLocation.isValid) {
      await restaurantManager.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              restaurantLocation.longitude,
              restaurantLocation.latitude,
            ),
          ),
          image: await _buildRestaurantMarkerImage(
            isActive: restaurantIsActive,
          ),
          iconAnchor: IconAnchor.CENTER,
          iconSize: 1.0,
          symbolSortKey: 18,
        ),
      );
    }

    if (recipientLocation != null && recipientLocation.isValid) {
      await recipientManager.create(
        CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              recipientLocation.longitude,
              recipientLocation.latitude,
            ),
          ),
          circleColor: const Color(0xFFFF6500).toARGB32(),
          circleRadius: 11,
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 4,
        ),
      );
    }
  }

  Future<void> renderRoute(NavigationRouteBundle? route) async {
    final routeSource = _routeSource;
    if (routeSource == null) {
      return;
    }

    if (route == null || !route.hasGeometry) {
      await routeSource.updateGeoJSON(_emptyRouteGeoJson());
      return;
    }

    final featureCollection = FeatureCollection(
      features: [
        Feature(
          id: 'order-tracking-route-feature',
          geometry: LineString(
            coordinates: route.polyline
                .map(
                  (point) => Position(point.longitude, point.latitude),
                )
                .toList(),
          ),
        ),
      ],
    );

    await routeSource.updateGeoJSON(jsonEncode(featureCollection.toJson()));
  }

  Future<void> focusOnTracking({
    required TrackingCoordinate? driverLocation,
    required TrackingCoordinate? restaurantLocation,
    required TrackingCoordinate? recipientLocation,
    bool followDriver = true,
    bool immediate = false,
  }) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }

    final driverPoint = driverLocation == null || !driverLocation.isValid
        ? null
        : Point(
            coordinates: Position(
              driverLocation.longitude,
              driverLocation.latitude,
            ),
          );
    final restaurantPoint =
        restaurantLocation == null || !restaurantLocation.isValid
            ? null
            : Point(
                coordinates: Position(
                  restaurantLocation.longitude,
                  restaurantLocation.latitude,
                ),
              );
    final recipientPoint =
        recipientLocation == null || !recipientLocation.isValid
            ? null
            : Point(
                coordinates: Position(
                  recipientLocation.longitude,
                  recipientLocation.latitude,
                ),
              );

    if (driverPoint == null &&
        restaurantPoint == null &&
        recipientPoint == null) {
      return;
    }

    final points = <Point>[];
    if (followDriver) {
      if (driverPoint != null && recipientPoint != null) {
        points.add(driverPoint);
        points.add(recipientPoint);
      } else if (restaurantPoint != null && recipientPoint != null) {
        points.add(restaurantPoint);
        points.add(recipientPoint);
      } else if (driverPoint != null) {
        points.add(driverPoint);
      } else if (restaurantPoint != null) {
        points.add(restaurantPoint);
      } else if (recipientPoint != null) {
        points.add(recipientPoint);
      }
    } else {
      if (driverPoint != null) {
        points.add(driverPoint);
      }
      if (restaurantPoint != null) {
        points.add(restaurantPoint);
      }
      if (recipientPoint != null) {
        points.add(recipientPoint);
      }
    }

    if (points.length > 1) {
      final cameraState = await mapboxMap.cameraForCoordinatesPadding(
        points,
        CameraOptions(pitch: 18, bearing: 0),
        MbxEdgeInsets(top: 120, left: 28, bottom: 280, right: 28),
        16,
        null,
      );
      await _applyCamera(
        mapboxMap,
        CameraOptions(
          center: cameraState.center,
          zoom: cameraState.zoom,
          bearing: cameraState.bearing,
          pitch: followDriver ? 18 : 20,
          padding: cameraState.padding,
        ),
        immediate: immediate,
      );
      return;
    }

    final target = points.first;
    await _applyCamera(
      mapboxMap,
      CameraOptions(
        center: target,
        zoom: followDriver ? 15.0 : 14.0,
        pitch: followDriver ? 46 : 18,
        bearing: 0,
        padding: MbxEdgeInsets(top: 120, left: 28, bottom: 280, right: 28),
      ),
      immediate: immediate,
    );
  }

  Future<void> focusOnPoint(
    Point center, {
    double zoom = 15.0,
    double pitch = 46,
    double bearing = 0,
    bool immediate = false,
  }) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }

    await _applyCamera(
      mapboxMap,
      CameraOptions(
        center: center,
        zoom: zoom,
        pitch: pitch,
        bearing: bearing,
        padding: MbxEdgeInsets(top: 120, left: 28, bottom: 280, right: 28),
      ),
      immediate: immediate,
    );
  }

  IconData _vehicleIconFor(String vehicleType) {
    final normalized = vehicleType.toLowerCase().trim();
    if (normalized.contains('car') ||
        normalized.contains('sedan') ||
        normalized.contains('auto') ||
        normalized.contains('vehicle') ||
        normalized.contains('سيارة')) {
      return Icons.directions_car_filled_rounded;
    }

    if (normalized.contains('truck') ||
        normalized.contains('van') ||
        normalized.contains('شاحنة')) {
      return Icons.local_shipping_rounded;
    }

    return Icons.two_wheeler_rounded;
  }

  Future<Uint8List> _buildDriverMarkerImage({
    required bool driverIsActive,
    required String driverVehicleType,
  }) async {
    final icon = _vehicleIconFor(driverVehicleType);
    final cacheKey = '${icon.codePoint}_${driverIsActive ? 'active' : 'idle'}';
    final cached = _driverMarkerImageCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    const size = 128.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);
    final baseColor =
        driverIsActive ? const Color(0xFFFF6500) : const Color(0xFF8A8A8A);

    canvas.drawCircle(
      center,
      size * 0.38,
      Paint()..color = baseColor.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      center,
      size * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    canvas.drawCircle(
      center,
      size * 0.24,
      Paint()..color = baseColor,
    );
    canvas.drawCircle(
      Offset(center.dx - 10, center.dy - 12),
      size * 0.045,
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 46,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to render driver marker image');
    }

    final bytes = byteData.buffer.asUint8List();
    _driverMarkerImageCache[cacheKey] = bytes;
    return bytes;
  }

  Future<Uint8List> _buildRestaurantMarkerImage({
    required bool isActive,
  }) async {
    const icon = Icons.storefront_rounded;
    final cacheKey = 'restaurant_${isActive ? 'active' : 'idle'}';
    final cached = _restaurantMarkerImageCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    const size = 128.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);
    final baseColor =
        isActive ? const Color(0xFFFF6500) : const Color(0xFF7A7A7A);

    canvas.drawCircle(
      center,
      size * 0.38,
      Paint()..color = baseColor.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      center,
      size * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    canvas.drawCircle(
      center,
      size * 0.24,
      Paint()..color = baseColor,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 46,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to render restaurant marker image');
    }

    final bytes = byteData.buffer.asUint8List();
    _restaurantMarkerImageCache[cacheKey] = bytes;
    return bytes;
  }

  Future<void> _applyCamera(
    MapboxMap mapboxMap,
    CameraOptions camera, {
    required bool immediate,
  }) async {
    if (immediate) {
      await mapboxMap.setCamera(camera);
    } else {
      await mapboxMap.easeTo(
        camera,
        MapAnimationOptions(duration: 800),
      );
    }
  }

  Future<void> showOverview({
    required TrackingCoordinate? driverLocation,
    required TrackingCoordinate? restaurantLocation,
    required TrackingCoordinate? recipientLocation,
  }) async {
    await focusOnTracking(
      driverLocation: driverLocation,
      restaurantLocation: restaurantLocation,
      recipientLocation: recipientLocation,
      followDriver: false,
      immediate: false,
    );
  }

  String _emptyRouteGeoJson() {
    return jsonEncode(
      {
        'type': 'FeatureCollection',
        'features': const [],
      },
    );
  }
}
