import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:tks/features/location/domain/entities/driver_location.dart';
import 'package:tks/features/navigation/domain/entities/navigation_route_bundle.dart';

class MapboxService {
  static const String _routeSourceId = 'driver-navigation-route-source';
  static const String _routeLayerId = 'driver-navigation-route-layer';
  static const String _driverPuckAsset = 'assets/images/006-delivery.png';

  MapboxMap? _mapboxMap;
  GeoJsonSource? _routeSource;
  Uint8List? _driverPuckBytes;

  Future<void> attachMap(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
  }

  Future<void> prepareMapStyle() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }

    _driverPuckBytes ??=
        (await rootBundle.load(_driverPuckAsset)).buffer.asUint8List();

    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingColor: const Color(0x55244C1A).toARGB32(),
        pulsingMaxRadius: 30,
        showAccuracyRing: false,
        puckBearingEnabled: true,
        puckBearing: PuckBearing.COURSE,
        locationPuck: LocationPuck(
          locationPuck2D: DefaultLocationPuck2D(
            topImage: _driverPuckBytes,
            bearingImage: _driverPuckBytes,
            shadowImage: Uint8List.fromList(<int>[]),
            opacity: 1,
          ),
        ),
      ),
    );

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
        lineColor: Colors.white.toARGB32(),
        lineWidth: 8.0,
        lineOpacity: 0.96,
        lineBorderColor: const Color(0x33242B21).toARGB32(),
        lineBorderWidth: 2.0,
      ),
    );
  }

  Future<void> renderDriverMarker(DriverLocation location) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null || !location.hasReliableHeading) {
      return;
    }

    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        puckBearingEnabled: true,
        puckBearing: PuckBearing.COURSE,
      ),
    );
  }

  Future<void> renderRoutePolyline(NavigationRouteBundle route) async {
    if (_routeSource == null) {
      return;
    }

    final featureCollection = FeatureCollection(
      features: [
        Feature(
          id: 'driver-navigation-route-feature',
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

    await _routeSource!.updateGeoJSON(jsonEncode(featureCollection.toJson()));
  }

  Future<void> focusOnDriver({
    required DriverLocation location,
    bool immediate = false,
  }) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }

    final cameraOptions = CameraOptions(
      center: location.toPoint(),
      zoom: 17,
      pitch: 45,
      bearing: location.heading,
      padding: MbxEdgeInsets(top: 170, left: 24, bottom: 270, right: 24),
    );

    if (immediate) {
      await mapboxMap.setCamera(cameraOptions);
    } else {
      await mapboxMap.easeTo(
        cameraOptions,
        MapAnimationOptions(duration: 900, startDelay: 0),
      );
    }
  }

  Future<void> showRouteOverview(NavigationRouteBundle route) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null || !route.hasGeometry) {
      return;
    }

    final coordinates = route.polyline
        .map(
          (point) => Point(
            coordinates: Position(point.longitude, point.latitude),
          ),
        )
        .toList();

    final camera = await mapboxMap.cameraForCoordinatesPadding(
      coordinates,
      CameraOptions(pitch: 25, bearing: 0),
      MbxEdgeInsets(top: 120, left: 40, bottom: 220, right: 40),
      17,
      null,
    );

    await mapboxMap.easeTo(
      CameraOptions(
        center: camera.center,
        zoom: camera.zoom,
        bearing: camera.bearing,
        pitch: 35,
        padding: camera.padding,
      ),
      MapAnimationOptions(duration: 1000),
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
