import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/batchmate_cgpa_entry.dart';

class CgpaPieChart extends StatelessWidget {
  final List<BatchmateCgpaEntry> ranking;
  final String userRoll;
  const CgpaPieChart({
    super.key,
    required this.ranking,
    required this.userRoll,
  });

  @override
  Widget build(BuildContext context) {
    final bins = [
      {'label': '<2.5', 'color': Colors.redAccent, 'count': 0},
      {'label': '2.5–3.0', 'color': Colors.orangeAccent, 'count': 0},
      {'label': '3.0–3.5', 'color': Colors.blueAccent, 'count': 0},
      {'label': '3.5–4.0', 'color': Colors.cyanAccent, 'count': 0},
    ];
    double? userCgpa;
    for (final e in ranking) {
      final cgpa = e.avgCgpa!;
      if (e.roll == userRoll) userCgpa = cgpa;
      if (cgpa < 2.5) {
        bins[0]['count'] = (bins[0]['count'] as int) + 1;
      } else if (cgpa < 3.0) {
        bins[1]['count'] = (bins[1]['count'] as int) + 1;
      } else if (cgpa < 3.5) {
        bins[2]['count'] = (bins[2]['count'] as int) + 1;
      } else {
        bins[3]['count'] = (bins[3]['count'] as int) + 1;
      }
    }

    int userBin = userCgpa == null
        ? -1
        : userCgpa < 2.5
        ? 0
        : userCgpa < 3.0
        ? 1
        : userCgpa < 3.5
        ? 2
        : 3;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: List.generate(bins.length, (i) {
                final isUser = i == userBin;
                return PieChartSectionData(
                  color: bins[i]['color'] as Color,
                  value: (bins[i]['count'] as int).toDouble(),
                  title: '${bins[i]['count']}',
                  radius: isUser ? 75 : 55,
                  titleStyle: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
                    fontSize: isUser ? 20 : 14,
                  ),
                  badgeWidget: isUser
                      ? Icon(Icons.person, color: Colors.white, size: 28)
                      : null,
                  badgePositionPercentageOffset: 1.2,
                );
              }),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 18,
          children: List.generate(bins.length, (i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: bins[i]['color'] as Color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  bins[i]['label'] as String,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            );
          }),
        ),
        if (userBin >= 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "You are in the ${bins[userBin]['label']} group.",
              style: GoogleFonts.poppins(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
      ],
    );
  }
}
