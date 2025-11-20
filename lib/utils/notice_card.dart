import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uni_connect/utils/glass_card.dart';

// Notice Card for horizontal scroll
class NoticeCard extends StatelessWidget {
  final String title;
  final String desc;
  final String time;
  const NoticeCard({
    super.key,
    required this.title,
    required this.desc,
    required this.time,
  });
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(right: 6, left: 6),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
