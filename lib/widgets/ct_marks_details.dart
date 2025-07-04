import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ct_mark_entry.dart';

class CtMarksDetails extends StatelessWidget {
  final Map<String, dynamic> data;
  const CtMarksDetails({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final courses = data['courses'] as Map<String, dynamic>;
    final List<CtMarkEntry> entries = [];

    courses.forEach((course, exams) {
      for (int i = 0; i < (exams as List).length; i++) {
        final pair = exams[i] as List;
        final percent = (pair[0] / pair[1]) * 100;
        entries.add(
          CtMarkEntry(
            course: course,
            exam: i + 1,
            obtained: pair[0],
            total: pair[1],
            percent: percent,
          ),
        );
      }
    });

    entries.sort((a, b) {
      int cmp = a.course.compareTo(b.course);
      if (cmp != 0) return cmp;
      return a.exam.compareTo(b.exam);
    });

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _cell("Course", bold: true),
              _cell("CT", bold: true),
              _cell("Score", bold: true),
              _cell("Percent", bold: true),
            ],
          ),
          const Divider(color: Colors.white24, thickness: 0.7),
          ...entries.map(
            (e) => Row(
              children: [
                _cell(e.course),
                _cell("CT${e.exam}"),
                _cell("${e.obtained}/${e.total}"),
                _cell("${e.percent.toStringAsFixed(1)}%"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool bold = false}) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
