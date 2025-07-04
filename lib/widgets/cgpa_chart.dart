import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'avg_cgpa_animation.dart';

class CgpaChart extends StatelessWidget {
  final List cgpaList;
  const CgpaChart({super.key, required this.cgpaList});

  @override
  Widget build(BuildContext context) {
    final double avgCgpa = cgpaList.isNotEmpty
        ? cgpaList.reduce((a, b) => a + b) / cgpaList.length
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 0.5,
                    getTitlesWidget: (value, meta) {
                      if (value % 0.5 == 0) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 == 0 &&
                          value >= 0 &&
                          value < cgpaList.length) {
                        return Text(
                          'S${value.toInt() + 1}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              minY: 2.0,
              maxY: 4.0,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    cgpaList.length,
                    (i) =>
                        FlSpot(i.toDouble(), (cgpaList[i] as num).toDouble()),
                  ),
                  isCurved: true,
                  color: Colors.cyanAccent,
                  barWidth: 4,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedGradientCGPANumber(avgCgpa: avgCgpa),
      ],
    );
  }
}
