import 'package:tks/features/location/domain/entities/driver_location.dart';
import 'package:tks/features/navigation/domain/entities/navigation_lane_guidance.dart';

class NavigationStepInfo {
  const NavigationStepInfo({
    required this.index,
    required this.roadName,
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuverType,
    required this.maneuverModifier,
    required this.maneuverLocation,
    required this.laneGuidance,
    this.voiceInstruction,
  });

  final int index;
  final String roadName;
  final String instruction;
  final double distanceMeters;
  final double durationSeconds;
  final String maneuverType;
  final String maneuverModifier;
  final DriverLocation maneuverLocation;
  final List<NavigationLaneGuidance> laneGuidance;
  final String? voiceInstruction;

  bool get hasLaneGuidance => laneGuidance.isNotEmpty;
}
