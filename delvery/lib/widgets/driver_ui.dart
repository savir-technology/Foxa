import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DriverUi {
  static Color get background =>
      isDark ? const Color(0xFF101312) : const Color(0xFFFFFFFF);
  static Color get surface => isDark ? const Color(0xFF171A18) : Colors.white;
  static Color get surfaceSoft =>
      isDark ? const Color(0xFF211C19) : const Color(0xFFFFF8F3);
  static Color get surfaceWarm =>
      isDark ? const Color(0xFF1B1E1B) : const Color(0xFFF8F9F6);
  static Color get line =>
      isDark ? const Color(0xFF2A2F2B) : const Color(0xFFEEEEEE);
  static const Color primary = Color(0xFFFF6500);
  static Color get primarySoft =>
      isDark ? const Color(0xFF4A2412) : const Color(0xFFFFF0E6);
  static const Color primaryMuted = Color(0xFFE34F00);
  static Color get text =>
      isDark ? const Color(0xFFF5F5F5) : const Color(0xFF171717);
  static Color get mutedText =>
      isDark ? const Color(0xFFB2B2B2) : const Color(0xFF6D6D6D);
  static const Color danger = Color(0xFFD64545);
  static Color get dangerSoft =>
      isDark ? const Color(0xFF3A1D1D) : const Color(0xFFF9E6E6);
  static Color get warningSoft =>
      isDark ? const Color(0xFF3A2E18) : const Color(0xFFF8F1DF);

  static bool get isDark => Get.isDarkMode;

  static Color get backgroundAdaptive =>
      isDark ? const Color(0xFF101312) : background;
  static Color get surfaceAdaptive =>
      isDark ? const Color(0xFF171A18) : surface;
  static Color get surfaceSoftAdaptive =>
      isDark ? const Color(0xFF211C19) : surfaceSoft;
  static Color get surfaceWarmAdaptive =>
      isDark ? const Color(0xFF1B1E1B) : surfaceWarm;
  static Color get lineAdaptive => isDark ? const Color(0xFF2A2F2B) : line;
  static Color get primarySoftAdaptive =>
      isDark ? const Color(0xFF4A2412) : primarySoft;
  static Color get dangerSoftAdaptive =>
      isDark ? const Color(0xFF3A1D1D) : dangerSoft;
  static Color get warningSoftAdaptive =>
      isDark ? const Color(0xFF3A2E18) : warningSoft;
  static Color get textAdaptive => isDark ? const Color(0xFFF5F5F5) : text;
  static Color get mutedTextAdaptive =>
      isDark ? const Color(0xFFB2B2B2) : mutedText;
}

class DriverBrandMark extends StatelessWidget {
  const DriverBrandMark({
    super.key,
    this.compact = false,
    this.showSubtitle = true,
  });

  final bool compact;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 38.0 : 50.0;
    final titleSize = compact ? 15.5 : 20.0;
    final subtitleSpacing = compact ? 4.0 : 6.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                color: DriverUi.surfaceAdaptive,
                borderRadius: BorderRadius.circular(compact ? 16 : 20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: compact ? 9 : 13,
                    right: compact ? 9 : 13,
                    bottom: compact ? 9 : 12,
                    child: Container(
                      height: compact ? 3.5 : 4.5,
                      decoration: BoxDecoration(
                        color: DriverUi.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.delivery_dining_rounded,
                    size: compact ? 24 : 32,
                    color: DriverUi.primary,
                  ),
                ],
              ),
            ),
            SizedBox(width: compact ? 10 : 11),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'FOXA ',
                    style: GoogleFonts.montserrat(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w900,
                      color: DriverUi.textAdaptive,
                      height: 1,
                      letterSpacing: -0.4,
                    ),
                  ),
                  TextSpan(
                    text: '',
                    style: GoogleFonts.montserrat(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w900,
                      color: DriverUi.primary,
                      height: 1,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: subtitleSpacing),
        Text(
          'DRIVER',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: compact ? 9.0 : 10.5,
            fontWeight: FontWeight.w800,
            color: DriverUi.primary,
            letterSpacing: compact ? 3.5 : 4.0,
            height: 1,
          ),
        ),
        if (showSubtitle) const SizedBox(height: 2),
      ],
    );
  }
}

class DriverHeaderBar extends StatelessWidget {
  const DriverHeaderBar({
    super.key,
    this.leadingIcon = Icons.notifications_none_rounded,
    this.trailingIcon = Icons.headset_mic_outlined,
    this.onLeadingTap,
    this.onTrailingTap,
    this.brandCompact = true,
  });

  final IconData leadingIcon;
  final IconData trailingIcon;
  final VoidCallback? onLeadingTap;
  final VoidCallback? onTrailingTap;
  final bool brandCompact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _RoundActionButton(icon: leadingIcon, onTap: onLeadingTap),
          ),
          Align(
            alignment: Alignment.center,
            child: DriverBrandMark(compact: brandCompact, showSubtitle: false),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _RoundActionButton(icon: trailingIcon, onTap: onTrailingTap),
          ),
        ],
      ),
    );
  }
}

class DriverPageHeader extends StatelessWidget {
  const DriverPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.alignment = TextAlign.center,
    this.titleColor,
    this.subtitleColor,
  });

  final String title;
  final String subtitle;
  final TextAlign alignment;
  final Color? titleColor;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: alignment,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: titleColor ?? DriverUi.primary,
            fontWeight: FontWeight.w800,
            height: 1.06,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: alignment,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: subtitleColor ?? DriverUi.mutedTextAdaptive,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class DriverCard extends StatelessWidget {
  const DriverCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.radius = 18,
    this.margin = EdgeInsets.zero,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final double radius;
  final EdgeInsets margin;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? DriverUi.surfaceAdaptive,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? DriverUi.lineAdaptive),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class DriverSectionTitle extends StatelessWidget {
  const DriverSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final actionLabelValue = actionLabel;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: DriverUi.textAdaptive,
            ),
          ),
        ),
        if (actionLabelValue != null)
          TextButton(onPressed: onActionTap, child: Text(actionLabelValue)),
      ],
    );
  }
}

class DriverInfoRow extends StatelessWidget {
  const DriverInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueStyle,
  });

  final String label;
  final String value;
  final IconData? icon;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            _MiniIcon(icon: icon!),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DriverUi.mutedTextAdaptive,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.start,
              style:
                  valueStyle ??
                  Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: DriverUi.textAdaptive,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class DriverPrimaryButton extends StatelessWidget {
  const DriverPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.minHeight = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: minHeight,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class DriverSecondaryButton extends StatelessWidget {
  const DriverSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 17),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? DriverUi.surfaceAdaptive,
          side: BorderSide(color: DriverUi.lineAdaptive),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class DriverActionPill extends StatelessWidget {
  const DriverActionPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? DriverUi.primary : DriverUi.primary;
    return ActionChip(
      label: Text(label),
      avatar: icon == null ? null : Icon(icon, size: 18, color: color),
      onPressed: onPressed,
      side: BorderSide(
        color: selected ? DriverUi.primary : DriverUi.lineAdaptive,
      ),
      backgroundColor: selected
          ? DriverUi.primarySoftAdaptive
          : DriverUi.surfaceAdaptive,
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class DriverEmptyStateCard extends StatelessWidget {
  const DriverEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return DriverCard(
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: DriverUi.primarySoftAdaptive,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: DriverUi.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: DriverUi.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: DriverUi.mutedTextAdaptive,
              height: 1.4,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            DriverPrimaryButton(
              label: actionLabel!,
              onPressed: onAction,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: DriverUi.surfaceAdaptive,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DriverUi.lineAdaptive),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap ?? () {},
        icon: Icon(icon, color: DriverUi.textAdaptive),
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  const _MiniIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: DriverUi.primarySoftAdaptive,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: DriverUi.primary),
    );
  }
}
