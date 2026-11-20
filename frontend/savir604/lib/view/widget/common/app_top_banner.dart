import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppTopBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData leadingIcon;
  final VoidCallback? onLeadingTap;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  final Widget? child;

  const AppTopBanner({
    super.key,
    required this.title,
    this.subtitle,
    required this.leadingIcon,
    this.onLeadingTap,
    this.trailingIcon,
    this.onTrailingTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final titleText = title.trim().tr;
    final subtitleText = subtitle?.trim().tr ?? '';
    final hasSubtitle = subtitleText.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.85 : 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -18,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: isDark ? 0.14 : 0.08),
              ),
            ),
          ),
          Positioned(
            left: -24,
            bottom: -28,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.secondary.withValues(alpha: isDark ? 0.10 : 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _BannerButton(
                    icon: leadingIcon,
                    onTap: onLeadingTap,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        if (hasSubtitle) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitleText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.68),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailingIcon != null) const SizedBox(width: 12),
                  if (trailingIcon != null)
                    _BannerButton(
                      icon: trailingIcon!,
                      onTap: onTrailingTap,
                    ),
                ],
              ),
              if (child != null) ...[
                const SizedBox(height: 14),
                child!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _BannerButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isBack = icon == Icons.arrow_back_rounded ||
        icon == Icons.arrow_back_ios_new_rounded;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: isBack ? 44 : 40,
        height: isBack ? 44 : 40,
        decoration: BoxDecoration(
          color:
              isBack ? theme.cardColor : colors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(isBack ? 16 : 14),
          border: Border.all(
            color: isBack
                ? theme.dividerColor.withValues(alpha: 0.70)
                : colors.primary.withValues(alpha: 0.08),
          ),
          boxShadow: isBack
              ? [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isBack ? colors.onSurface : colors.primary,
          size: isBack ? 21 : 22,
        ),
      ),
    );
  }
}

class AppTopBannerMetric extends StatelessWidget {
  final String value;
  final String label;

  const AppTopBannerMetric({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.primary.withValues(alpha: isDark ? 0.20 : 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }
}
