import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:tks/core/services/mapbox_runtime_config.dart';
import 'package:tks/features/location/domain/entities/driver_location.dart';
import 'package:tks/features/navigation/domain/entities/driver_trip_destination.dart';
import 'package:tks/features/navigation/domain/entities/navigation_lane_guidance.dart';
import 'package:tks/features/navigation/domain/entities/navigation_progress_snapshot.dart';
import 'package:tks/features/navigation/domain/entities/navigation_route_bundle.dart';
import 'package:tks/features/navigation/domain/entities/navigation_step_info.dart';

class NavigationService {
  NavigationService({
    http.Client? client,
    FlutterTts? tts,
  })  : _client = client ?? http.Client(),
        _tts = tts ?? FlutterTts() {
    _configureTts();
  }

  final http.Client _client;
  final FlutterTts _tts;
  final Set<String> _announcedInstructionKeys = <String>{};

  Future<void> _configureTts() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> speakText(
    String message, {
    required bool isArabic,
  }) async {
    final text = message.trim();
    if (text.isEmpty) {
      return;
    }

    await _tts.stop();
    await _tts.setLanguage(isArabic ? 'ar' : 'en-US');
    await _tts.speak(text);
  }

  Future<NavigationRouteBundle> fetchRoute({
    required DriverLocation origin,
    required DriverTripDestination destination,
    required bool isArabic,
  }) async {
    final token = MapboxRuntimeConfig.accessToken;
    if (token.isEmpty) {
      return _fallbackRoute(origin, destination);
    }

    final language = isArabic ? 'ar' : 'en';
    final uri = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving/'
      '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}'
      '?alternatives=false'
      '&geometries=geojson'
      '&language=$language'
      '&overview=full'
      '&steps=true'
      '&banner_instructions=true'
      '&voice_instructions=true'
      '&annotations=maxspeed'
      '&access_token=$token',
    );

    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return _fallbackRoute(origin, destination);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = (json['routes'] as List?) ?? const [];
    if (routes.isEmpty) {
      return _fallbackRoute(origin, destination);
    }

    final route = Map<String, dynamic>.from(routes.first as Map);
    final geometry =
        Map<String, dynamic>.from(route['geometry'] as Map? ?? const {});
    final coordinates = (geometry['coordinates'] as List?) ?? const [];
    final polyline = coordinates
        .whereType<List>()
        .where((coordinate) => coordinate.length >= 2)
        .map(
          (coordinate) => NavigationCoordinate(
            latitude: (coordinate[1] as num).toDouble(),
            longitude: (coordinate[0] as num).toDouble(),
          ),
        )
        .toList();

    final legs = (route['legs'] as List?) ?? const [];
    final firstLeg = legs.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(legs.first as Map);
    final stepMaps = (firstLeg['steps'] as List?) ?? const [];

    final steps = <NavigationStepInfo>[];
    for (var i = 0; i < stepMaps.length; i++) {
      final stepMap = Map<String, dynamic>.from(stepMaps[i] as Map);
      final maneuver = Map<String, dynamic>.from(
        stepMap['maneuver'] as Map? ?? const {},
      );
      final location = (maneuver['location'] as List?) ?? const [0, 0];
      final voiceInstructions =
          (stepMap['voiceInstructions'] as List?) ?? const [];
      final intersections = (stepMap['intersections'] as List?) ?? const [];

      final laneGuidance = <NavigationLaneGuidance>[];
      for (final intersection in intersections.whereType<Map>()) {
        final lanes = (intersection['lanes'] as List?) ?? const [];
        for (final lane in lanes.whereType<Map>()) {
          final indications = (lane['indications'] as List?)
                  ?.map((value) => '$value')
                  .where((value) => value.trim().isNotEmpty)
                  .toList() ??
              const <String>[];
          if (indications.isEmpty) {
            continue;
          }

          laneGuidance.add(
            NavigationLaneGuidance(
              indications: indications,
              isValid: lane['valid'] == true,
              isActive: lane['active'] == true,
            ),
          );
        }
        if (laneGuidance.isNotEmpty) {
          break;
        }
      }

      final voiceMap = voiceInstructions.isEmpty
          ? null
          : Map<String, dynamic>.from(voiceInstructions.first as Map);

      final maneuverLatitude =
          ((location.length > 1 ? location[1] : 0) as num).toDouble();
      final maneuverLongitude =
          ((location.isNotEmpty ? location[0] : 0) as num).toDouble();

      steps.add(
        NavigationStepInfo(
          index: i,
          roadName: '${stepMap['name'] ?? ''}',
          instruction: '${maneuver['instruction'] ?? stepMap['name'] ?? ''}',
          distanceMeters: (stepMap['distance'] as num?)?.toDouble() ?? 0,
          durationSeconds: (stepMap['duration'] as num?)?.toDouble() ?? 0,
          maneuverType: '${maneuver['type'] ?? ''}',
          maneuverModifier: '${maneuver['modifier'] ?? ''}',
          maneuverLocation: DriverLocation(
            latitude: maneuverLatitude,
            longitude: maneuverLongitude,
            heading: 0,
            speedMetersPerSecond: 0,
            accuracyMeters: 0,
            timestamp: DateTime.now(),
          ),
          laneGuidance: laneGuidance,
          voiceInstruction: voiceMap?['announcement']?.toString() ??
              '${maneuver['instruction'] ?? ''}',
        ),
      );
    }

    return NavigationRouteBundle(
      distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
      polyline: polyline,
      steps: steps,
    );
  }

  NavigationRouteBundle _fallbackRoute(
    DriverLocation origin,
    DriverTripDestination destination,
  ) {
    final distanceMeters = geo.Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );
    final durationSeconds = math
        .max(
          60,
          (distanceMeters / 1000.0 / 25.0 * 3600.0).round(),
        )
        .toDouble();

    return NavigationRouteBundle(
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      polyline: [
        NavigationCoordinate(
          latitude: origin.latitude,
          longitude: origin.longitude,
        ),
        NavigationCoordinate(
          latitude: destination.latitude,
          longitude: destination.longitude,
        ),
      ],
      steps: const [],
    );
  }

  NavigationProgressSnapshot buildProgress({
    required NavigationRouteBundle route,
    required DriverLocation currentLocation,
    required int previousStepIndex,
  }) {
    final currentStepIndex = _resolveCurrentStepIndex(
      route: route,
      currentLocation: currentLocation,
      previousStepIndex: previousStepIndex,
    );
    final step = route.steps.isEmpty
        ? null
        : route.steps[currentStepIndex.clamp(0, route.steps.length - 1)];

    final turnDistanceMeters = step == null
        ? 0.0
        : geo.Geolocator.distanceBetween(
            currentLocation.latitude,
            currentLocation.longitude,
            step.maneuverLocation.latitude,
            step.maneuverLocation.longitude,
          );

    final remainingDistanceMeters =
        _remainingRouteDistance(route, currentLocation, currentStepIndex);
    final remainingSeconds = route.distanceMeters <= 0
        ? 0
        : ((route.durationSeconds *
                    (remainingDistanceMeters / route.distanceMeters))
                .round())
            .clamp(0, route.durationSeconds.round());
    final offRouteDistanceMeters = _distanceToNearestRoutePoint(
      currentLocation,
      route.polyline,
    );

    return NavigationProgressSnapshot(
      currentStepIndex: currentStepIndex,
      nextStreetName: step == null
          ? ''
          : (step.roadName.trim().isNotEmpty
              ? step.roadName
              : step.instruction),
      nextInstruction: step?.instruction ?? '',
      turnDistanceMeters: turnDistanceMeters,
      eta: Duration(seconds: remainingSeconds),
      remainingDistanceMeters: remainingDistanceMeters,
      maneuverType: step?.maneuverType ?? '',
      maneuverModifier: step?.maneuverModifier ?? '',
      laneGuidance: step?.laneGuidance ?? const [],
      offRouteDistanceMeters: offRouteDistanceMeters,
      isOffRoute: offRouteDistanceMeters > 35,
    );
  }

  Future<void> speakInstructionIfNeeded({
    required NavigationProgressSnapshot progress,
    required bool isArabic,
  }) async {
    if (progress.nextInstruction.trim().isEmpty) {
      return;
    }

    String? key;
    String? message;
    if (progress.turnDistanceMeters <= 55) {
      key = '${progress.currentStepIndex}:now';
      message = progress.nextInstruction;
    } else if (progress.turnDistanceMeters <= 220) {
      key = '${progress.currentStepIndex}:soon';
      message = isArabic
          ? 'بعد ${progress.turnDistanceMeters.round()} متر، ${progress.nextInstruction}'
          : 'In ${progress.turnDistanceMeters.round()} meters, ${progress.nextInstruction}';
    }

    if (key == null ||
        message == null ||
        _announcedInstructionKeys.contains(key)) {
      return;
    }

    _announcedInstructionKeys.add(key);
    await _tts.setLanguage(isArabic ? 'ar' : 'en-US');
    await _tts.speak(message);
  }

  void resetSpeechState() {
    _announcedInstructionKeys.clear();
  }

  Future<void> stopSpeaking() => _tts.stop();

  void dispose() {
    _client.close();
    _tts.stop();
  }

  int _resolveCurrentStepIndex({
    required NavigationRouteBundle route,
    required DriverLocation currentLocation,
    required int previousStepIndex,
  }) {
    if (route.steps.isEmpty) {
      return 0;
    }

    var bestIndex = previousStepIndex.clamp(0, route.steps.length - 1);
    var bestDistance = double.infinity;

    for (var i = bestIndex; i < route.steps.length; i++) {
      final step = route.steps[i];
      final distance = geo.Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        step.maneuverLocation.latitude,
        step.maneuverLocation.longitude,
      );

      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }

      if (i > previousStepIndex && distance > bestDistance + 250) {
        break;
      }
    }

    if (bestDistance < 18 && bestIndex < route.steps.length - 1) {
      return bestIndex + 1;
    }

    return bestIndex;
  }

  double _remainingRouteDistance(
    NavigationRouteBundle route,
    DriverLocation currentLocation,
    int currentStepIndex,
  ) {
    if (route.steps.isEmpty) {
      return 0;
    }

    final currentStep =
        route.steps[currentStepIndex.clamp(0, route.steps.length - 1)];
    var remaining = geo.Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      currentStep.maneuverLocation.latitude,
      currentStep.maneuverLocation.longitude,
    );

    for (var i = currentStepIndex + 1; i < route.steps.length; i++) {
      remaining += route.steps[i].distanceMeters;
    }

    return remaining.clamp(0, route.distanceMeters);
  }

  double _distanceToNearestRoutePoint(
    DriverLocation currentLocation,
    List<NavigationCoordinate> polyline,
  ) {
    if (polyline.isEmpty) {
      return 0;
    }

    if (polyline.length == 1) {
      return geo.Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        polyline.first.latitude,
        polyline.first.longitude,
      );
    }

    var nearest = double.infinity;
    for (var i = 0; i < polyline.length - 1; i++) {
      final distance = _distanceToSegmentMeters(
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
        start: polyline[i],
        end: polyline[i + 1],
      );
      nearest = math.min(nearest, distance);
    }
    return nearest;
  }

  double _distanceToSegmentMeters({
    required double latitude,
    required double longitude,
    required NavigationCoordinate start,
    required NavigationCoordinate end,
  }) {
    final referenceLatitude = latitude * math.pi / 180;
    const metersPerDegreeLat = 111320.0;
    final metersPerDegreeLng = metersPerDegreeLat * math.cos(referenceLatitude);

    double toX(double lon) => (lon - longitude) * metersPerDegreeLng;
    double toY(double lat) => (lat - latitude) * metersPerDegreeLat;

    final ax = toX(start.longitude);
    final ay = toY(start.latitude);
    final bx = toX(end.longitude);
    final by = toY(end.latitude);
    final dx = bx - ax;
    final dy = by - ay;
    final denominator = (dx * dx) + (dy * dy);
    if (denominator == 0) {
      return math.sqrt((ax * ax) + (ay * ay));
    }

    final t = ((-ax * dx) + (-ay * dy)) / denominator;
    final clampedT = t.clamp(0.0, 1.0);
    final closestX = ax + (dx * clampedT);
    final closestY = ay + (dy * clampedT);
    return math.sqrt((closestX * closestX) + (closestY * closestY));
  }
}
