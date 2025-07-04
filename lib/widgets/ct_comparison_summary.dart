import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ct_comparison_entry.dart';

class CtComparisonSummary extends StatelessWidget {
  final List<CtComparisonEntry> entries;
  const CtComparisonSummary({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final userAvg =
        entries.map((e) => e.userPercent).reduce((a, b) => a + b) /
        entries.length;
    final avgAvg =
        entries.map((e) => e.avgPercent).reduce((a, b) => a + b) /
        entries.length;
    final diff = userAvg - avgAvg;
    final diffText = diff.abs().toStringAsFixed(1);
    final isBetter = diff > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        isBetter
            ? 'You scored $diffText% better than the batch average across all CTs.'
            : 'You scored $diffText% below the batch average across all CTs.',
        style: GoogleFonts.poppins(
          color: isBetter ? Colors.greenAccent : Colors.redAccent,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
