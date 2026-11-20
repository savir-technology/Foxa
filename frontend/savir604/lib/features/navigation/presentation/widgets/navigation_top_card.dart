import 'package:flutter/material.dart';
import 'package:tks/core/widgets/navigation_glass_card.dart';
import 'package:tks/features/navigation/domain/entities/navigation_progress_snapshot.dart';
import 'package:tks/features/navigation/presentation/widgets/lane_guidance_strip.dart';

class NavigationTopCard extends StatelessWidget {
  const NavigationTopCard({
    super.key,
    required this.progress,
    required this.isArabic,
  });

  final NavigationProgressSnapshot progress;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NavigationGlassCard(
      child: Column(
        crossAxisAlignment:
            isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ManeuverIcon(
                maneuverType: progress.maneuverType,
                maneuverModifier: progress.maneuverModifier,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: isArabic
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.nextStreetName.trim().isEmpty
                          ? (isArabic
                              ? 'استمر على المسار'
                              : 'Continue on route')
                          : progress.nextStreetName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress.nextInstruction.trim().isEmpty
                          ? (isArabic
                              ? 'التوجيه التالي سيظهر هنا'
                              : 'The next guidance step will appear here')
                          : progress.nextInstruction,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6D6D6D),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _formatDistance(progress.turnDistanceMeters, isArabic),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF161616),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isArabic ? 'للانعطاف التالي' : 'to next maneuver',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6D6D6D),
                  ),
                ),
              ),
            ],
          ),
          if (progress.hasLaneGuidance) ...[
            const SizedBox(height: 12),
            LaneGuidanceStrip(lanes: progress.laneGuidance, isArabic: isArabic),
          ],
        ],
      ),
    );
  }
}

class _ManeuverIcon extends StatelessWidget {
  const _ManeuverIcon({
    required this.maneuverType,
    required this.maneuverModifier,
  });

  final String maneuverType;
  final String maneuverModifier;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        _iconForManeuver(maneuverType, maneuverModifier),
        color: const Color(0xFF161616),
        size: 30,
      ),
    );
  }

  IconData _iconForManeuver(String type, String modifier) {
    final normalizedModifier = modifier.toLowerCase();
    final normalizedType = type.toLowerCase();

    if (normalizedType.contains('roundabout')) {
      return Icons.roundabout_right_rounded;
    }
    if (normalizedModifier.contains('left')) {
      return Icons.turn_left_rounded;
    }
    if (normalizedModifier.contains('right')) {
      return Icons.turn_right_rounded;
    }
    if (normalizedModifier.contains('straight')) {
      return Icons.straight_rounded;
    }
    if (normalizedModifier.contains('uturn')) {
      return Icons.u_turn_left_rounded;
    }
    return Icons.navigation_rounded;
  }
}

String _formatDistance(double meters, bool isArabic) {
  if (meters >= 1000) {
    final value = (meters / 1000).toStringAsFixed(1);
    return isArabic ? '$value كم' : '$value km';
  }
  return isArabic ? '${meters.round()} م' : '${meters.round()} m';
}
