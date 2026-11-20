import 'package:flutter/material.dart';

class DashboardCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const DashboardCard(
      {super.key,
      required this.icon,
      required this.title,
      this.subtitle,
      this.onTap});

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard>
    with SingleTickerProviderStateMixin {
  bool _hover = false;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final bg1 = Theme.of(context).cardColor;
    final bg2 = Theme.of(context).canvasColor;

    return MouseRegion(
        onEnter: (_) {
          setState(() => _hover = true);
          _ctrl.forward();
        },
        onExit: (_) {
          setState(() => _hover = false);
          _ctrl.reverse();
        },
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _hover ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 220),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(_hover ? -0.03 : 0)
                ..rotateY(_hover ? 0.03 : 0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [bg1.withOpacity(0.95), bg2.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.55),
                        blurRadius: _hover ? 24 : 12,
                        offset: const Offset(0, 12)),
                    if (_hover)
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.18),
                        blurRadius: 28,
                        spreadRadius: 1,
                      ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          primary.withOpacity(0.95),
                          primary.withOpacity(0.55)
                        ]),
                        boxShadow: [
                          BoxShadow(
                              color: primary.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 6))
                        ],
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(widget.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 6),
                            Text(widget.subtitle!,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 13)),
                          ]
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
