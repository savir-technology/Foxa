import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppPillButton extends StatelessWidget {
  const AppPillButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.height = 54,
    this.backgroundColor,
    this.foregroundColor,
    this.expanded = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.primary;
    final fg = foregroundColor ?? theme.colorScheme.onPrimary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final child = SizedBox(
          height: height,
          width: expanded && constraints.hasBoundedWidth
              ? double.infinity
              : null,
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: fg, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        label.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        if (constraints.hasBoundedWidth) {
          return child;
        }
        return child;
      },
    );
  }
}

class AppPillIconButton extends StatelessWidget {
  const AppPillIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: theme.dividerColor),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onSurface,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class AppPillDock extends StatelessWidget {
  const AppPillDock({
    super.key,
    this.leading,
    required this.center,
    this.trailing,
  });

  final Widget? leading;
  final Widget center;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedWidth = constraints.hasBoundedWidth;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF181818) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            mainAxisSize: hasBoundedWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                child: Center(child: leading ?? const SizedBox()),
              ),
              const SizedBox(width: 10),
              if (hasBoundedWidth)
                Expanded(child: center)
              else
                Flexible(fit: FlexFit.loose, child: center),
              const SizedBox(width: 10),
              SizedBox(
                width: 56,
                child: Center(child: trailing ?? const SizedBox()),
              ),
            ],
          ),
        );
      },
    );
  }
}
