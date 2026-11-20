import 'package:tks/features/navigation/domain/entities/navigation_step_info.dart';

class NavigationCoordinate {
  const NavigationCoordinate({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class NavigationRouteBundle {
  const NavigationRouteBundle({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.polyline,
    required this.steps,
  });

  final double distanceMeters;
  final double durationSeconds;
  final List<NavigationCoordinate> polyline;
  final List<NavigationStepInfo> steps;

  bool get hasGeometry => polyline.length > 1;
}
