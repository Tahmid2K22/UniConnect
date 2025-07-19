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
      {'label': '<2.5', 'color': const Color(0xFFFF6B6B), 'count': 0},
      {'label': '2.5–3.0', 'color': const Color(0xFFFFA36C), 'count': 0},
      {'label': '3.0–3.5', 'color': const Color(0xFF5DADE2), 'count': 0},
      {'label': '3.5–4.0', 'color': const Color(0xFF00E6E6), 'count': 0},
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
        const SizedBox(height: 10),
        SizedBox(
          height: 240,
          child: PieChart(
            PieChartData(
              startDegreeOffset: -90,
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 35,
              sections: List.generate(bins.length, (i) {
                final isUser = i == userBin;
                final count = (bins[i]['count'] as int).toDouble();
                return PieChartSectionData(
                  color: bins[i]['color'] as Color,
                  value: count,
                  title: count == 0 ? '' : '${count.toInt()}',
                  radius: isUser ? 70 : 55,
                  titleStyle: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: isUser ? FontWeight.bold : FontWeight.w500,
                    fontSize: isUser ? 18 : 13,
                  ),
                  badgeWidget: isUser
                      ? Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_pin_circle,
                            size: 26,
                            color: Colors.white,
                          ),
                        )
                      : null,
                  badgePositionPercentageOffset: 1.1,
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 20,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(bins.length, (i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: bins[i]['color'] as Color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  bins[i]['label'] as String,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13.5,
                  ),
                ),
              ],
            );
          }),
        ),
        if (userBin >= 0)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              "You are in the ${bins[userBin]['label']} group.",
              style: GoogleFonts.poppins(
                color: const Color(0xFF00FFC6),
                fontWeight: FontWeight.bold,
                fontSize: 15.5,
              ),
            ),
          ),
      ],
    );
  }
}
