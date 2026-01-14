import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Простий sparkline графік
class SimpleSparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double height;
  final double width;

  const SimpleSparkline({
    super.key,
    required this.data,
    required this.color,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        width: width,
        child: const Center(
          child: Text('Немає даних', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return SizedBox(
      height: height,
      width: width,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value);
              }).toList(),
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.1),
              ),
            ),
          ],
          minY: data.reduce((a, b) => a < b ? a : b) * 0.9,
          maxY: data.reduce((a, b) => a > b ? a : b) * 1.1,
        ),
      ),
    );
  }
}
