import 'dart:math' as math;

import 'package:delvery/data/models/driver_models.dart';

class DriverRouteVariant {
  const DriverRouteVariant({
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
    this.isPrimary = false,
  });

  final List<DriverCoordinate> coordinates;
  final double distanceMeters;
  final double durationSeconds;
  final bool isPrimary;

  bool get hasRoute => coordinates.length > 1;
}

class DriverRouteBundle {
  const DriverRouteBundle({
    required this.routes,
  });

  final List<DriverRouteVariant> routes;

  DriverRouteVariant? get primaryRoute {
    if (routes.isEmpty) {
      return null;
    }

    for (final route in routes) {
      if (route.isPrimary) {
        return route;
      }
    }

    return routes.first;
  }

  List<DriverRouteVariant> get alternatives {
    if (routes.length <= 1) {
      return const [];
    }

    return routes.skip(1).toList(growable: false);
  }

  bool get hasRoute => primaryRoute?.hasRoute ?? false;
}

class DriverNavigationStep {
  const DriverNavigationStep({
    required this.index,
    required this.routeIndex,
    required this.location,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuverType,
    required this.modifier,
    required this.streetName,
    required this.rawInstruction,
    required this.exitNumber,
  });

  final int index;
  final int routeIndex;
  final DriverCoordinate location;
  final double distanceMeters;
  final double durationSeconds;
  final String maneuverType;
  final String? modifier;
  final String streetName;
  final String rawInstruction;
  final int? exitNumber;

  bool get isArrival => maneuverType == 'arrive';
}

class DriverNavigationPlan {
  const DriverNavigationPlan({
    required this.route,
    required this.steps,
    required this.routeDistanceMeters,
    required this.routeDurationSeconds,
  });

  final List<DriverCoordinate> route;
  final List<DriverNavigationStep> steps;
  final double routeDistanceMeters;
  final double routeDurationSeconds;

  int? closestRouteIndex(DriverCoordinate point) {
    if (route.isEmpty) {
      return null;
    }

    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var index = 0; index < route.length; index++) {
      final distance = _distanceMeters(point, route[index]);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = index;
      }
    }
    return bestIndex;
  }

  DriverNavigationStep? nextStepAfter(int routeIndex) {
    for (final step in steps) {
      if (step.routeIndex > routeIndex) {
        return step;
      }
    }
    return steps.isEmpty ? null : steps.last;
  }

  bool get hasRoute => route.length > 1;

  double routeDistanceKm() => routeDistanceMeters / 1000.0;

  int routeDurationMinutes() => (routeDurationSeconds / 60.0).ceil();
}

double _distanceMeters(DriverCoordinate from, DriverCoordinate to) {
  const earthRadiusKm = 6371.0;
  final lat1 = _toRadians(from.latitude);
  final lat2 = _toRadians(to.latitude);
  final deltaLat = _toRadians(to.latitude - from.latitude);
  final deltaLng = _toRadians(to.longitude - from.longitude);

  final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
      math.cos(lat1) * math.cos(lat2) *
          math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(math.max(0, 1 - a)));
  return earthRadiusKm * c * 1000.0;
}

double _toRadians(double degree) => degree * math.pi / 180.0;
