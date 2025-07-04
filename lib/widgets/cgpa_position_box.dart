import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/batchmate_cgpa_entry.dart';

class CgpaPositionBox extends StatelessWidget {
  final List<BatchmateCgpaEntry> ranking;
  final String userRoll;
  final Widget Function(
    List<BatchmateCgpaEntry> ranking,
    String userRoll,
    BuildContext context,
  )
  buildFullCgpaRankingChart;

  const CgpaPositionBox({
    super.key,
    required this.ranking,
    required this.userRoll,
    required this.buildFullCgpaRankingChart,
  });

  @override
  Widget build(BuildContext context) {
    final idx = ranking.indexWhere((e) => e.roll == userRoll);
    if (idx == -1) return Container();

    BatchmateCgpaEntry? above = idx > 0 ? ranking[idx - 1] : null;
    BatchmateCgpaEntry user = ranking[idx];
    BatchmateCgpaEntry? below = idx < ranking.length - 1
        ? ranking[idx + 1]
        : null;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: buildFullCgpaRankingChart(ranking, userRoll, context),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.cyanAccent.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (above != null) _cgpaPersonTile(above, highlight: false),
            _cgpaPersonTile(user, highlight: true),
            if (below != null) _cgpaPersonTile(below, highlight: false),
          ],
        ),
      ),
    );
  }

  Widget _cgpaPersonTile(BatchmateCgpaEntry entry, {required bool highlight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            color: highlight ? Colors.cyanAccent : Colors.white54,
            size: highlight ? 30 : 24,
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.name} (${entry.roll})',
            style: GoogleFonts.poppins(
              color: highlight ? Colors.cyanAccent : Colors.white70,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              fontSize: highlight ? 18 : 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            entry.avgCgpa!.toStringAsFixed(2),
            style: GoogleFonts.poppins(
              color: highlight ? Colors.cyanAccent : Colors.white70,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              fontSize: highlight ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
