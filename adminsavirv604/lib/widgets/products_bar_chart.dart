import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProductsBarChart extends StatelessWidget {
  final List<BarChartGroupData> data;
  final String title;

  const ProductsBarChart({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              barGroups: data,
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(
                leftTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: true)),
                bottomTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: true)),
              ),
              gridData: const FlGridData(show: false),
            ),
          ),
        ),
      ],
    );
  }
}
