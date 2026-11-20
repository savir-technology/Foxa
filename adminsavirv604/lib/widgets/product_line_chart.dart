import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProductLineChart extends StatefulWidget {
  final List<FlSpot> productData;
  final List<FlSpot> expenseData;
  final List<String> labels;
  final String title;
  final double height;

  const ProductLineChart({
    super.key,
    required this.productData,
    required this.expenseData,
    required this.labels,
    this.title = '',
    this.height = 260,
  });

  @override
  State<ProductLineChart> createState() => _ProductLineChartState();
}

class _ProductLineChartState extends State<ProductLineChart> {
  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF9800);
    const orangeDark = Color(0xFFF57C00);
    const orangeLight = Color(0xFFFFB74D);

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 46, 39, 39),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: orange.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // العنوان
          Row(
            children: [
              const Icon(Icons.trending_up, color: orangeDark, size: 24),
              const SizedBox(width: 10),
              Text(
                widget.title.isNotEmpty ? widget.title : "تحليل الاتجاه",
                style: const TextStyle(
                  color: orangeDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // الرسم البياني
          SizedBox(
            height: widget.height,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: orangeLight.withValues(alpha: 0.12),
                    strokeWidth: 0.8,
                    dashArray: [4, 4],
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: orangeLight.withValues(alpha: 0.08),
                    strokeWidth: 0.8,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: orangeDark.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
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
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < widget.labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.labels[idx],
                              style: TextStyle(
                                color: orangeDark.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: orangeLight.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                minX: 0,
                maxX: (widget.labels.length - 1).toDouble().clamp(0, 20),
                minY: 0,
                maxY: _getMaxY(),
                lineBarsData: [
                  // خط المنتجات
                  LineChartBarData(
                    spots: widget.productData,
                    isCurved: true,
                    color: orange,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: orange,
                        strokeWidth: 1.5,
                        strokeColor: const Color.fromARGB(255, 92, 77, 77),
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: orange.withValues(alpha: 0.08),
                    ),
                  ),
                  // خط المصاريف
                  LineChartBarData(
                    spots: widget.expenseData,
                    isCurved: true,
                    color: orangeDark,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: orangeDark,
                        strokeWidth: 1.5,
                        strokeColor: const Color.fromARGB(255, 73, 61, 61),
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: orangeDark.withValues(alpha: 0.08),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final label = spot.barIndex == 0 ? 'منتج' : 'مصروف';
                        return LineTooltipItem(
                          '$label: ${spot.y.toStringAsFixed(1)}',
                          const TextStyle(
                            color: Color.fromARGB(255, 58, 52, 52),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),

          // المفتاح
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(orange, 'منتجات'),
              const SizedBox(width: 24),
              _buildLegendItem(orangeDark, 'مصاريف'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  double _getMaxY() {
    final allValues = [...widget.productData, ...widget.expenseData]
        .map((spot) => spot.y)
        .toList();
    if (allValues.isEmpty) return 100;
    final max = allValues.reduce((a, b) => a > b ? a : b);
    return (max * 1.15).ceilToDouble();
  }
}
