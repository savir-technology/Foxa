import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProductBarChart extends StatelessWidget {
  final List<BarChartGroupData> data;
  final String title;
  final List<String> labels;
  final double height;
  const ProductBarChart({
    super.key,
    required List<BarChartGroupData> barGroups,
    List<String>? barLabels,
    this.title = '',
    this.height = 260,
  })  : data = barGroups,
        labels = barLabels ?? const [];

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF9800);
    const orangeDark = Color(0xFFF57C00);
    const orangeLight = Color(0xFFFFB74D);
    const barGradients = [
      [orange, orangeLight],
      [orangeDark, orange],
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: orange.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: orangeDark, size: 30),
              const SizedBox(width: 12),
              Text(
                title.isNotEmpty ? title : "Bar Chart",
                style: const TextStyle(
                  color: orangeDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: height,
            child: BarChart(
              BarChartData(
                barGroups: data,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: orangeLight.withValues(alpha: 0.18),
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: orangeDark.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              labels[idx],
                              style: const TextStyle(
                                color: orangeDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => orangeDark,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = (group.x.toInt() < labels.length)
                          ? labels[group.x.toInt()]
                          : '';
                      final isProduct = rodIndex == 0;
                      return BarTooltipItem(
                        '${isProduct ? 'منتج: ' : 'مصروف: '}$label\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: rod.toY.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 18,
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: barGradients[0],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "منتج",
                style: TextStyle(
                  color: orangeDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 18),
              Container(
                width: 18,
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: barGradients[1],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "مصروف",
                style: TextStyle(
                  color: orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
