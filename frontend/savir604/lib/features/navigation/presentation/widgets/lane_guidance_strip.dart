import 'package:flutter/material.dart';
import 'package:tks/features/navigation/domain/entities/navigation_lane_guidance.dart';

class LaneGuidanceStrip extends StatelessWidget {
  const LaneGuidanceStrip({
    super.key,
    required this.lanes,
    required this.isArabic,
  });

  final List<NavigationLaneGuidance> lanes;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    if (lanes.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 34,
      child: ListView.separated(
        reverse: isArabic,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final lane = lanes[index];
          final label = lane.indications.join(' / ').toUpperCase();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: lane.isActive
                  ? const Color(0xFF161616)
                  : lane.isValid
                      ? const Color(0xFFE7E7E7)
                      : const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color:
                        lane.isActive ? Colors.white : const Color(0xFF666666),
                    fontWeight: FontWeight.w900,
                  ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: lanes.length,
      ),
    );
  }
}
