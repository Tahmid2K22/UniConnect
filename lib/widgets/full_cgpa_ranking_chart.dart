import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/batchmate_cgpa_entry.dart';

class FullCgpaRankingChart extends StatelessWidget {
  final List<BatchmateCgpaEntry> ranking;
  final String userRoll;

  const FullCgpaRankingChart({
    super.key,
    required this.ranking,
    required this.userRoll,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Sort by roll ascending:
    final sorted = [...ranking]..sort((a, b) => a.roll.compareTo(b.roll));
    // 2. Find user index in the sorted list:
    final userIdx = sorted.indexWhere((e) => e.roll == userRoll);
    // 3. Compute batch average using the sorted list:
    final avgAll =
        sorted.map((e) => e.avgCgpa!).fold<double>(0, (sum, x) => sum + x) /
        sorted.length;
    final userCgpa = userIdx >= 0 ? sorted[userIdx].avgCgpa! : null;
    final diff = userCgpa != null ? userCgpa - avgAll : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "CGPA by Roll Number",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      sorted.length,
                      (i) => FlSpot(i.toDouble(), sorted[i].avgCgpa!),
                    ),
                    isCurved: true,
                    color: Colors.cyanAccent,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, bar) => spot.x == userIdx,
                      getDotPainter: (spot, percent, bar, idx) =>
                          FlDotCirclePainter(
                            radius: 7,
                            color: Colors.blueAccent,
                            strokeWidth: 4,
                            strokeColor: Colors.cyanAccent,
                          ),
                    ),
                  ),
                ],
                minY: 2.0,
                maxY: 4.0,
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, meta) => Text(
                        v.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "Batch Average CGPA: ${avgAll.toStringAsFixed(2)}",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
          if (userCgpa != null)
            Text(
              diff >= 0
                  ? "You are +${diff.toStringAsFixed(2)} above average"
                  : "You are ${diff.toStringAsFixed(2)} below average",
              style: GoogleFonts.poppins(
                color: diff >= 0 ? Colors.greenAccent : Colors.redAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
