import 'package:admin_tks/theme.dart';
import 'package:flutter/material.dart';

class DashboardBackground extends StatelessWidget {
  final Widget child;

  const DashboardBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFFFF8F3),
                Color(0xFFFFF0E6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SizedBox.expand(),
        ),
        Positioned(
          top: -120,
          right: -140,
          child: _SoftGlow(
            diameter: 280,
            tint: kPrimary.withValues(alpha: 0.05),
          ),
        ),
        Positioned(
          bottom: -110,
          left: -120,
          child: _SoftGlow(
            diameter: 260,
            tint: kSecondary.withValues(alpha: 0.05),
          ),
        ),
        child,
      ],
    );
  }
}

class _SoftGlow extends StatelessWidget {
  const _SoftGlow({
    required this.diameter,
    required this.tint,
  });

  final double diameter;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              tint,
              tint.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}
