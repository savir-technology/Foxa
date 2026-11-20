import 'package:flutter/material.dart';

class MarketCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? metric;
  final double? progress;
  final Color? accentColor;
  final VoidCallback? onTap;

  const MarketCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.metric,
    this.progress,
    this.accentColor,
    this.onTap,
  });

  @override
  State<MarketCard> createState() => _MarketCardState();
}

class _MarketCardState extends State<MarketCard>
    with SingleTickerProviderStateMixin {
  bool _hover = false;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = widget.accentColor ?? theme.colorScheme.primary;
    final surface = theme.cardColor;
    final divider = theme.dividerColor;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hover = true);
        _animCtrl.forward();
      },
      onExit: (_) {
        setState(() => _hover = false);
        _animCtrl.reverse();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: _hover ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          builder: (context, hoverVal, _) {
            return Transform.translate(
              offset: Offset(0, _hover ? -4 : 0), // translateY(-4px) on hover
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 18 + (hoverVal * 6),
                      offset: Offset(0, 8 + (hoverVal * 3)),
                    ),
                    if (_hover)
                      BoxShadow(
                        color: primary.withValues(alpha: 0.12),
                        blurRadius: 28,
                        spreadRadius: 1,
                      ),
                  ],
                  border: Border.all(
                    color: divider,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.10 + hoverVal * 0.08),
                                blurRadius: 14 + hoverVal * 6,
                                spreadRadius: 0.5 + hoverVal * 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            color: primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color ??
                                      const Color(0xFF1E1E1E),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle ?? 'Metric',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.72) ??
                                      const Color(0xFF6C7A89),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.metric != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.metric!,
                        style: TextStyle(
                          color: primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    if (widget.progress != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (widget.progress ?? 0).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: divider.withValues(alpha: 0.40),
                          valueColor: AlwaysStoppedAnimation<Color>(primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${((widget.progress ?? 0) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
