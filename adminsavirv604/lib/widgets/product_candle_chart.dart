import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ProductCandleChart extends StatelessWidget {
  final List<CandleData> data;
  final String title;

  const ProductCandleChart({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF9800);
    const orangeDark = Color(0xFFF57C00);
    const orangeLight = Color(0xFFFFB74D);
    return Container(
      decoration: BoxDecoration(
        color: orangeLight.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: orange.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.candlestick_chart, color: orangeDark, size: 28),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                    color: orangeDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 260,
            child: SfCartesianChart(
              backgroundColor: Colors.transparent,
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                labelStyle:
                    TextStyle(color: orangeDark, fontWeight: FontWeight.w600),
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: TextStyle(color: orangeDark.withOpacity(0.7)),
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                majorGridLines: MajorGridLines(
                  color: orangeLight.withOpacity(0.2),
                  width: 1,
                  dashArray: const [4, 4],
                ),
              ),
              tooltipBehavior: TooltipBehavior(
                  enable: true,
                  color: orange,
                  textStyle: const TextStyle(color: Colors.white)),
              series: <CandleSeries<CandleData, String>>[
                CandleSeries<CandleData, String>(
                  dataSource: data,
                  xValueMapper: (CandleData d, _) => d.label,
                  lowValueMapper: (CandleData d, _) => d.low,
                  highValueMapper: (CandleData d, _) => d.high,
                  openValueMapper: (CandleData d, _) => d.open,
                  closeValueMapper: (CandleData d, _) => d.close,
                  bearColor: orange,
                  bullColor: orangeDark,
                  width: 0.7,
                  enableSolidCandles: true,
                  borderWidth: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CandleData {
  final String label;
  final double open;
  final double high;
  final double low;
  final double close;

  CandleData({
    required this.label,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });
}
