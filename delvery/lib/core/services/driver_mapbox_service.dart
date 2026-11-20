import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:delvery/core/services/mapbox_runtime_config.dart';
import 'package:delvery/data/models/driver_models.dart';
import 'package:delvery/data/models/navigation_models.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class DriverMapboxService {
  static const int _routeSlots = 3;
  static const String _routeSourcePrefix = 'driver-live-route-source';
  static const String _routeLayerPrefix = 'driver-live-route-layer';
  static const List<Color> _routePalette = <Color>[
    Color(0xFF2F80FF),
    Color(0xFF8BC4FF),
    Color(0xFFF2C77A),
  ];

  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);

  MapboxMap? _mapboxMap;
  final List<GeoJsonSource?> _routeSources = List<GeoJsonSource?>.filled(
    _routeSlots,
    null,
    growable: false,
  );
  CircleAnnotationManager? _driverMarkerManager;
  CircleAnnotationManager? _targetMarkerManager;

  String _routeSourceId(int index) => '$_routeSourcePrefix-$index';

  String _routeLayerId(int index) => '$_routeLayerPrefix-$index';

  Future<void> attachMap(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
  }

  Future<void> prepareMapStyle() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }

    final style = mapboxMap.style;
    for (var index = 0; index < _routeSlots; index++) {
      try {
        await style.removeStyleLayer(_routeLayerId(index));
      } catch (_) {}
      try {
        await style.removeStyleSource(_routeSourceId(index));
      } catch (_) {}
      _routeSources[index] = null;
    }

    for (var index = _routeSlots - 1; index >= 0; index--) {
      final source = GeoJsonSource(
        id: _routeSourceId(index),
        lineMetrics: true,
        data: _emptyRouteGeoJson(),
      );
      _routeSources[index] = source;
      await style.addSource(source);
      await style.addLayer(
        LineLayer(
          id: _routeLayerId(index),
          sourceId: _routeSourceId(index),
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
          lineColor: _routePalette[index].toARGB32(),
          lineWidth: index == 0 ? 8.5 : 4.5,
          lineOpacity: index == 0 ? 0.96 : 0.52,
          lineBorderColor: const Color(0x66FFFFFF).toARGB32(),
          lineBorderWidth: index == 0 ? 1.8 : 1.0,
        ),
      );
    }

    _driverMarkerManager ??= await mapboxMap.annotations
        .createCircleAnnotationManager();
    _targetMarkerManager ??= await mapboxMap.annotations
        .createCircleAnnotationManager();
  }

  Future<void> enableLocationPuck() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }

    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        showAccuracyRing: true,
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
      ),
    );
  }

  Future<void> renderScene({
    required DriverCoordinate? driverLocation,
    required DriverCoordinate? targetLocation,
    List<DriverRouteVariant>? routes,
    bool immediate = false,
    bool autoFocus = true,
    bool navigationCamera = false,
    MbxEdgeInsets? cameraPadding,
  }) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }

    await _renderMarkers(
      driverLocation: driverLocation,
      targetLocation: targetLocation,
    );
    await _renderRoutes(routes);
    if (autoFocus) {
      await _focusOnScene(
        driverLocation: driverLocation,
        targetLocation: targetLocation,
        route: routes?.isNotEmpty == true ? routes!.first.coordinates : null,
        cameraPadding: cameraPadding,
        immediate: immediate,
        navigationCamera: navigationCamera,
      );
    }
  }

  Future<List<DriverCoordinate>?> fetchRoute({
    required DriverCoordinate origin,
    required DriverCoordinate destination,
  }) async {
    try {
      final data = await _fetchDirectionsData(
        origin: origin,
        destination: destination,
        steps: false,
        alternatives: false,
      );
      if (data == null) {
        return null;
      }

      final route = _firstRoute(data);
      if (route == null) {
        return null;
      }

      final polyline = _parsePolyline(route);
      return polyline.isEmpty ? null : polyline;
    } catch (_) {
      return null;
    }
  }

  Future<DriverRouteBundle?> fetchRouteBundle({
    required DriverCoordinate origin,
    required DriverCoordinate destination,
  }) async {
    try {
      final data = await _fetchDirectionsData(
        origin: origin,
        destination: destination,
        steps: false,
        alternatives: true,
      );
      if (data == null) {
        return null;
      }

      final routes = _parseRouteVariants(data);
      if (routes.isEmpty) {
        return null;
      }

      return DriverRouteBundle(routes: routes);
    } catch (_) {
      return null;
    }
  }

  Future<DriverNavigationPlan?> fetchNavigationPlan({
    required DriverCoordinate origin,
    required DriverCoordinate destination,
  }) async {
    try {
      final data = await _fetchDirectionsData(
        origin: origin,
        destination: destination,
        steps: true,
        alternatives: false,
      );
      if (data == null) {
        return null;
      }

      final route = _firstRoute(data);
      if (route == null) {
        return null;
      }

      final polyline = _parsePolyline(route);
      if (polyline.isEmpty) {
        return null;
      }

      final steps = _parseNavigationSteps(route, polyline);
      return DriverNavigationPlan(
        route: polyline,
        steps: steps,
        routeDistanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
        routeDurationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchDirectionsData({
    required DriverCoordinate origin,
    required DriverCoordinate destination,
    required bool steps,
    required bool alternatives,
  }) async {
    final token = MapboxRuntimeConfig.accessToken;
    if (token.isEmpty) {
      return null;
    }

    final uri = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving/'
      '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}'
      '?alternatives=${alternatives ? 'true' : 'false'}'
      '&geometries=geojson'
      '&overview=full'
      '&steps=${steps ? 'true' : 'false'}'
      '${steps ? '&voice_instructions=true&banner_instructions=true' : ''}'
      '&access_token=$token',
    );

    final request = await _client.getUrl(uri);
    final response = await request.close();
    final raw = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic>
        ? decoded
        : decoded is Map
        ? decoded.map((key, value) => MapEntry('$key', value))
        : <String, dynamic>{};
  }

  Map<String, dynamic>? _firstRoute(Map<String, dynamic> data) {
    final routes = (data['routes'] as List?) ?? const [];
    if (routes.isEmpty) {
      return null;
    }
    return Map<String, dynamic>.from(routes.first as Map);
  }

  List<DriverRouteVariant> _parseRouteVariants(Map<String, dynamic> data) {
    final routes = (data['routes'] as List?) ?? const [];
    final parsedRoutes = <DriverRouteVariant>[];

    for (final rawRoute in routes.whereType<Map>().take(_routeSlots)) {
      final route = rawRoute.map((key, value) => MapEntry('$key', value));
      final polyline = _parsePolyline(route);
      if (polyline.length < 2) {
        continue;
      }

      parsedRoutes.add(
        DriverRouteVariant(
          coordinates: polyline,
          distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
          durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
          isPrimary: parsedRoutes.isEmpty,
        ),
      );
    }

    return parsedRoutes;
  }

  List<DriverCoordinate> _parsePolyline(Map<String, dynamic> route) {
    final geometry = Map<String, dynamic>.from(
      route['geometry'] as Map? ?? const {},
    );
    final coordinates = (geometry['coordinates'] as List?) ?? const [];
    return coordinates
        .whereType<List>()
        .where((coordinate) => coordinate.length >= 2)
        .map(
          (coordinate) => DriverCoordinate(
            latitude: (coordinate[1] as num).toDouble(),
            longitude: (coordinate[0] as num).toDouble(),
          ),
        )
        .toList(growable: false);
  }

  List<DriverNavigationStep> _parseNavigationSteps(
    Map<String, dynamic> route,
    List<DriverCoordinate> polyline,
  ) {
    final steps = <DriverNavigationStep>[];
    var index = 0;

    final legs = (route['legs'] as List?) ?? const [];
    for (final leg in legs.whereType<Map>()) {
      final legData = leg.map((key, value) => MapEntry('$key', value));
      final rawSteps = (legData['steps'] as List?) ?? const [];
      for (final rawStep in rawSteps.whereType<Map>()) {
        final step = rawStep.map((key, value) => MapEntry('$key', value));
        final maneuver = _mapValue(step['maneuver']);
        final location =
            _coordinateFromList((maneuver['location'] as List?) ?? const []) ??
            _coordinateFromList((step['location'] as List?) ?? const []) ??
            (polyline.isNotEmpty
                ? polyline.first
                : const DriverCoordinate(latitude: 0, longitude: 0));
        steps.add(
          DriverNavigationStep(
            index: index,
            routeIndex: _closestRouteIndex(polyline, location),
            location: location,
            distanceMeters: _num(step, ['distance']),
            durationSeconds: _num(step, ['duration']),
            maneuverType: _text(maneuver, [
              'type',
            ], fallback: _text(step, ['type'])).trim().toLowerCase(),
            modifier: _text(maneuver, [
              'modifier',
            ], fallback: _text(step, ['modifier'])).trim().toLowerCase(),
            streetName: _text(step, ['name'], fallback: ''),
            rawInstruction: _text(step, [
              'instruction',
              'bannerInstruction',
              'banner_instruction',
            ], fallback: _text(maneuver, ['instruction'])),
            exitNumber: _int(maneuver, ['exit']),
          ),
        );
        index++;
      }
    }

    steps.sort((a, b) {
      final comparison = a.routeIndex.compareTo(b.routeIndex);
      if (comparison != 0) {
        return comparison;
      }
      return a.index.compareTo(b.index);
    });
    return steps;
  }

  int _closestRouteIndex(List<DriverCoordinate> route, DriverCoordinate point) {
    if (route.isEmpty) {
      return 0;
    }

    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var index = 0; index < route.length; index++) {
      final current = route[index];
      final distance = _distanceMeters(current, point);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = index;
      }
    }
    return bestIndex;
  }

  DriverCoordinate? _coordinateFromList(List<dynamic> coordinates) {
    if (coordinates.length < 2) {
      return null;
    }

    final longitude = coordinates[0];
    final latitude = coordinates[1];
    if (longitude is! num || latitude is! num) {
      return null;
    }

    return DriverCoordinate(
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
    );
  }

  Map<String, dynamic> _mapValue(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry('$key', value));
    }
    return <String, dynamic>{};
  }

  String _text(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return fallback;
  }

  double _num(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) {
        continue;
      }
      final parsed = double.tryParse(value.toString());
      if (parsed != null) {
        return parsed;
      }
    }
    return 0;
  }

  int? _int(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) {
        continue;
      }
      final parsed = int.tryParse(value.toString());
      if (parsed != null) {
        return parsed;
      }
      final parsedDouble = double.tryParse(value.toString());
      if (parsedDouble != null) {
        return parsedDouble.round();
      }
    }
    return null;
  }

  double _distanceMeters(DriverCoordinate from, DriverCoordinate to) {
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
    return earthRadiusKm * c * 1000.0;
  }

  double _toRadians(double degree) => degree * math.pi / 180.0;

  Future<void> _renderMarkers({
    required DriverCoordinate? driverLocation,
    required DriverCoordinate? targetLocation,
  }) async {
    final driverManager = _driverMarkerManager;
    final targetManager = _targetMarkerManager;
    if (driverManager == null || targetManager == null) {
      return;
    }

    await driverManager.deleteAll();
    await targetManager.deleteAll();

    if (_isValid(driverLocation)) {
      await driverManager.create(
        CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              driverLocation!.longitude,
              driverLocation.latitude,
            ),
          ),
          circleColor: const Color(0xFF59D98E).toARGB32(),
          circleRadius: 11,
          circleStrokeColor: const Color(0xFFFFFFFF).toARGB32(),
          circleStrokeWidth: 4,
        ),
      );
    }

    if (_isValid(targetLocation)) {
      await targetManager.create(
        CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              targetLocation!.longitude,
              targetLocation.latitude,
            ),
          ),
          circleColor: const Color(0xFFFFC857).toARGB32(),
          circleRadius: 10,
          circleStrokeColor: const Color(0xFFFFFFFF).toARGB32(),
          circleStrokeWidth: 4,
        ),
      );
    }
  }

  Future<void> _renderRoutes(List<DriverRouteVariant>? routes) async {
    final activeRoutes = routes ?? const <DriverRouteVariant>[];

    for (var index = 0; index < _routeSlots; index++) {
      final source = _routeSources[index];
      if (source == null) {
        continue;
      }

      final route = index < activeRoutes.length ? activeRoutes[index] : null;
      if (route == null || !route.hasRoute) {
        await source.updateGeoJSON(_emptyRouteGeoJson());
        continue;
      }

      final featureCollection = FeatureCollection(
        features: [
          Feature(
            id: 'driver-live-route-feature-$index',
            geometry: LineString(
              coordinates: route.coordinates
                  .map((point) => Position(point.longitude, point.latitude))
                  .toList(growable: false),
            ),
          ),
        ],
      );

      await source.updateGeoJSON(jsonEncode(featureCollection.toJson()));
    }
  }

  Future<void> _focusOnScene({
    required DriverCoordinate? driverLocation,
    required DriverCoordinate? targetLocation,
    required List<DriverCoordinate>? route,
    required MbxEdgeInsets? cameraPadding,
    required bool immediate,
    required bool navigationCamera,
  }) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }

    if (navigationCamera && _isValid(driverLocation)) {
      await _focusNavigationCamera(
        driverLocation: driverLocation!,
        targetLocation: targetLocation,
        route: route,
        cameraPadding: cameraPadding,
        immediate: immediate,
      );
      return;
    }

    final driverPoint = _isValid(driverLocation)
        ? Point(
            coordinates: Position(
              driverLocation!.longitude,
              driverLocation.latitude,
            ),
          )
        : null;
    final targetPoint = _isValid(targetLocation)
        ? Point(
            coordinates: Position(
              targetLocation!.longitude,
              targetLocation.latitude,
            ),
          )
        : null;

    if (driverPoint == null && targetPoint == null) {
      return;
    }

    final focusPoints = <Point>[
      if (route != null)
        ...route
            .where(_isValid)
            .map(
              (point) =>
                  Point(coordinates: Position(point.longitude, point.latitude)),
            ),
    ];

    if (driverPoint != null) {
      focusPoints.add(driverPoint);
    }
    if (targetPoint != null) {
      focusPoints.add(targetPoint);
    }

    if (focusPoints.length > 1) {
      final camera = await mapboxMap.cameraForCoordinatesPadding(
        focusPoints,
        CameraOptions(pitch: 8, bearing: 0),
        cameraPadding ??
            MbxEdgeInsets(top: 96, left: 36, bottom: 180, right: 36),
        16,
        null,
      );
      await _applyCamera(
        mapboxMap,
        CameraOptions(
          center: camera.center,
          zoom: camera.zoom,
          bearing: camera.bearing,
          pitch: 10,
          padding: camera.padding,
        ),
        immediate: immediate,
      );
      return;
    }

    final point = driverPoint ?? targetPoint;
    if (point == null) {
      return;
    }

    await _applyCamera(
      mapboxMap,
      CameraOptions(
        center: point,
        zoom: 15.5,
        pitch: 8,
        bearing: 0,
        padding:
            cameraPadding ??
            MbxEdgeInsets(top: 96, left: 36, bottom: 180, right: 36),
      ),
      immediate: immediate,
    );
  }

  Future<void> _focusNavigationCamera({
    required DriverCoordinate driverLocation,
    required DriverCoordinate? targetLocation,
    required List<DriverCoordinate>? route,
    required MbxEdgeInsets? cameraPadding,
    required bool immediate,
  }) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }

    final aheadPoint =
        _routePointAhead(driverLocation, route) ??
        (_isValid(targetLocation) ? targetLocation : null);
    final bearing = aheadPoint == null
        ? 0.0
        : _bearing(driverLocation, aheadPoint);

    await _applyCamera(
      mapboxMap,
      CameraOptions(
        center: Point(
          coordinates: Position(
            driverLocation.longitude,
            driverLocation.latitude,
          ),
        ),
        zoom: 17.35,
        pitch: 58,
        bearing: bearing,
        padding:
            cameraPadding ??
            MbxEdgeInsets(top: 118, left: 0, bottom: 260, right: 0),
      ),
      immediate: immediate,
    );
  }

  DriverCoordinate? _routePointAhead(
    DriverCoordinate driverLocation,
    List<DriverCoordinate>? route,
  ) {
    final points = route;
    if (points == null || points.length < 2) {
      return null;
    }

    var closestIndex = 0;
    var closestDistance = double.infinity;
    for (var index = 0; index < points.length; index++) {
      final distance = _distanceMeters(driverLocation, points[index]);
      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = index;
      }
    }

    var distanceAhead = 0.0;
    for (var index = closestIndex; index < points.length - 1; index++) {
      final segment = _distanceMeters(points[index], points[index + 1]);
      distanceAhead += segment;
      if (distanceAhead >= 38) {
        return points[index + 1];
      }
    }

    return points.last;
  }

  double _bearing(DriverCoordinate from, DriverCoordinate to) {
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);
    final deltaLng = _toRadians(to.longitude - from.longitude);
    final y = math.sin(deltaLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);
    final degrees = math.atan2(y, x) * 180.0 / math.pi;
    return (degrees + 360.0) % 360.0;
  }

  Future<void> _applyCamera(
    MapboxMap mapboxMap,
    CameraOptions camera, {
    required bool immediate,
  }) async {
    if (immediate) {
      await mapboxMap.setCamera(camera);
    } else {
      await mapboxMap.easeTo(camera, MapAnimationOptions(duration: 650));
    }
  }

  bool _isValid(DriverCoordinate? coordinate) {
    if (coordinate == null) {
      return false;
    }
    return coordinate.latitude.abs() > 0.0001 ||
        coordinate.longitude.abs() > 0.0001;
  }

  String _emptyRouteGeoJson() {
    return jsonEncode({'type': 'FeatureCollection', 'features': const []});
  }

  void dispose() {
    _client.close(force: true);
  }
}
