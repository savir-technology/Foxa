import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:tks/features/location/domain/entities/driver_location.dart';

enum LocationAccessState {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class LocationService {
  const LocationService();

  Future<LocationAccessState> ensureAccess() async {
    final enabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return LocationAccessState.serviceDisabled;
    }

    var permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }

    return switch (permission) {
      geo.LocationPermission.always ||
      geo.LocationPermission.whileInUse =>
        LocationAccessState.granted,
      geo.LocationPermission.deniedForever => LocationAccessState.deniedForever,
      _ => LocationAccessState.denied,
    };
  }

  Future<DriverLocation?> getCurrentLocation() async {
    final state = await ensureAccess();
    if (state != LocationAccessState.granted) {
      return null;
    }

    final position = await geo.Geolocator.getCurrentPosition(
      locationSettings: _buildLocationSettings(),
    );
    return _mapPosition(position);
  }

  Stream<DriverLocation> driverLocationStream() {
    return geo.Geolocator.getPositionStream(
      locationSettings: _buildLocationSettings(),
    ).map(_mapPosition);
  }

  Future<void> openLocationSettings() => geo.Geolocator.openLocationSettings();

  Future<void> openAppSettings() => geo.Geolocator.openAppSettings();

  geo.LocationSettings _buildLocationSettings() {
    if (kIsWeb) {
      return const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      );
    }

    if (Platform.isAndroid) {
      return geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 2),
        forceLocationManager: false,
        foregroundNotificationConfig: const geo.ForegroundNotificationConfig(
          notificationTitle: 'Aleppo Eats navigation',
          notificationText: 'Driver navigation is running in the background.',
          enableWakeLock: true,
        ),
      );
    }

    if (Platform.isIOS) {
      return geo.AppleSettings(
        accuracy: geo.LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        activityType: geo.ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }

    return const geo.LocationSettings(
      accuracy: geo.LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );
  }

  DriverLocation _mapPosition(geo.Position position) {
    final normalizedHeading =
        position.heading.isNaN || position.heading < 0 ? 0.0 : position.heading;

    return DriverLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      heading: normalizedHeading,
      speedMetersPerSecond: position.speed.isNaN ? 0.0 : position.speed,
      accuracyMeters:
          position.accuracy.isNaN ? 0.0 : position.accuracy.toDouble(),
      timestamp: position.timestamp,
    );
  }
}
