import 'package:tks/features/navigation/domain/entities/navigation_lane_guidance.dart';

class NavigationProgressSnapshot {
  const NavigationProgressSnapshot({
    required this.currentStepIndex,
    required this.nextStreetName,
    required this.nextInstruction,
    required this.turnDistanceMeters,
    required this.eta,
    required this.remainingDistanceMeters,
    required this.maneuverType,
    required this.maneuverModifier,
    required this.laneGuidance,
    required this.offRouteDistanceMeters,
    required this.isOffRoute,
  });

  final int currentStepIndex;
  final String nextStreetName;
  final String nextInstruction;
  final double turnDistanceMeters;
  final Duration eta;
  final double remainingDistanceMeters;
  final String maneuverType;
  final String maneuverModifier;
  final List<NavigationLaneGuidance> laneGuidance;
  final double offRouteDistanceMeters;
  final bool isOffRoute;

  bool get hasLaneGuidance => laneGuidance.isNotEmpty;
}
