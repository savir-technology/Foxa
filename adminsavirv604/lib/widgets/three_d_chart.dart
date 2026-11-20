import 'dart:math';
import 'package:flutter/material.dart';

class ThreeDChart extends StatefulWidget {
  final List<double> values;
  const ThreeDChart({super.key, required this.values});

  @override
  State<ThreeDChart> createState() => _ThreeDChartState();
}

class _ThreeDChartState extends State<ThreeDChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(double.infinity, 160),
          painter: _ThreeDPainter(
              values: widget.values,
              progress: Curves.easeOut.transform(_ctrl.value),
              primary: Theme.of(context).primaryColor),
        );
      },
    );
  }
}

class _ThreeDPainter extends CustomPainter {
  final List<double> values;
  final double progress;
  final Color primary;

  _ThreeDPainter(
      {required this.values, required this.progress, required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final count = values.length;
    const spacing = 12.0;
    final barW = (w - (count + 1) * spacing) / count;
    final maxV = values.reduce(max);

    for (int i = 0; i < count; i++) {
      final v = values[i] / maxV;
      final targetH = v * (h * 0.7) * progress;
      final x = spacing + i * (barW + spacing);
      final y = h - targetH - 20;

      // draw front face
      paint.color = primary.withOpacity(0.95 - i * 0.06);
      final front = Rect.fromLTWH(x, y, barW, targetH);
      canvas.drawRRect(
          RRect.fromRectAndRadius(front, const Radius.circular(6)), paint);

      // draw top face (pseudo-3D)
      final path = Path();
      path.moveTo(x, y);
      path.lineTo(x + 8, y - 8);
      path.lineTo(x + barW + 8, y - 8);
      path.lineTo(x + barW, y);
      path.close();
      paint.color = primary.withOpacity(0.7 - i * 0.04);
      canvas.drawPath(path, paint);

      // draw side face
      final side = Path();
      side.moveTo(x + barW, y);
      side.lineTo(x + barW + 8, y - 8);
      side.lineTo(x + barW + 8, y - 8 + targetH);
      side.lineTo(x + barW, y + targetH);
      side.close();
      paint.color = Colors.black.withOpacity(0.25 + i * 0.02);
      canvas.drawPath(side, paint);
    }

    // subtle grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final yy = 20 + i * (h - 40) / 3;
      canvas.drawLine(Offset(0, yy), Offset(w, yy), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ThreeDPainter old) =>
      old.progress != progress || old.values != values;
}
