import 'package:flutter/material.dart';
import 'package:tks/core/widgets/navigation_glass_card.dart';

class TripBottomPanel extends StatelessWidget {
  const TripBottomPanel({
    super.key,
    required this.eta,
    required this.remainingDistanceMeters,
    required this.passengerName,
    required this.tripStatus,
    required this.destinationLabel,
    required this.isArabic,
    required this.isFollowingDriver,
    required this.onOverviewTap,
    required this.onRecenterTap,
  });

  final Duration eta;
  final double remainingDistanceMeters;
  final String passengerName;
  final String tripStatus;
  final String? destinationLabel;
  final bool isArabic;
  final bool isFollowingDriver;
  final VoidCallback onOverviewTap;
  final VoidCallback onRecenterTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationGlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  title: isArabic ? 'الوصول' : 'ETA',
                  value: _formatEta(eta, isArabic),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  title: isArabic ? 'المسافة' : 'Distance',
                  value: _formatDistance(remainingDistanceMeters, isArabic),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF161616),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: isArabic
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      passengerName,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destinationLabel?.trim().isNotEmpty == true
                          ? destinationLabel!
                          : tripStatus,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(label: tripStatus),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOverviewTap,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: Color(0xFFE1E1E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.route_outlined),
                  label: Text(isArabic ? 'عرض المسار' : 'Overview'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRecenterTap,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    backgroundColor: isFollowingDriver
                        ? const Color(0xFF161616)
                        : const Color(0xFF3A3A3A),
                  ),
                  icon: const Icon(Icons.gps_fixed_rounded),
                  label: Text(isArabic ? 'تمركز' : 'Recenter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6D6D6D),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A1A1A),
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF161616),
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

String _formatEta(Duration eta, bool isArabic) {
  if (eta.inMinutes < 1) {
    return isArabic ? 'الآن' : 'Now';
  }
  final hours = eta.inHours;
  final minutes = eta.inMinutes.remainder(60);
  if (hours > 0) {
    return isArabic ? '$hoursس $minutesد' : '${hours}h ${minutes}m';
  }
  return isArabic ? '${eta.inMinutes} دقيقة' : '${eta.inMinutes} min';
}

String _formatDistance(double meters, bool isArabic) {
  if (meters >= 1000) {
    final value = (meters / 1000).toStringAsFixed(1);
    return isArabic ? '$value كم' : '$value km';
  }
  return isArabic ? '${meters.round()} م' : '${meters.round()} m';
}
