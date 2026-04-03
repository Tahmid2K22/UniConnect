import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/ct_comparison_entry.dart';

class CtComparisonChart extends StatelessWidget {
  final List<CtComparisonEntry> entries;
  const CtComparisonChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    try {
      return _buildChart(context);
    } catch (e) {
      return _buildFallback(context, error: e);
    }
  }

  Widget _buildChart(BuildContext context) {
    final xLabels = entries.map((e) => '${e.course} CT${e.ctNumber}').toList();

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              maxY: 100,
              minY: 0,
              groupsSpace: 16,
              barGroups: List.generate(entries.length, (i) {
                final entry = entries[i];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: entry.userPercent,
                      color: Colors.cyanAccent,
                      width: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    BarChartRodData(
                      toY: entry.avgPercent,
                      color: Colors.blueAccent,
                      width: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 20,
                    getTitlesWidget: (value, meta) {
                      if (value % 20 == 0) {
                        return Text(
                          '${value.toInt()}%',
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
                    showTitles: false,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < xLabels.length) {
                        return RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            xLabels[value.toInt()],
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: true),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.cyanAccent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              "You",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(width: 16),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              "Batch average",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFallback(BuildContext context, {Object? error}) {
    return Container(
      height: 260,
      alignment: Alignment.center,
      color: Colors.black26,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.redAccent, size: 40),
          const SizedBox(height: 12),
          const Text(
            "Whoops! Something went wrong.\nPlease reload the page.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          // Uncomment for debugging:
          // if (error != null) Text(error.toString(), style: TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ),
    );
  }
}
