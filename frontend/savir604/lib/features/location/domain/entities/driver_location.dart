import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class DriverLocation {
  const DriverLocation({
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speedMetersPerSecond,
    required this.accuracyMeters,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double heading;
  final double speedMetersPerSecond;
  final double accuracyMeters;
  final DateTime timestamp;

  bool get hasReliableHeading => heading > 0;

  Point toPoint() => Point(coordinates: Position(longitude, latitude));

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed_mps': speedMetersPerSecond,
      'accuracy_meters': accuracyMeters,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
