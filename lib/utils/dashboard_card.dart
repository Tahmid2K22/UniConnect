import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//Dashboard card
class DashboardCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String titleValue;
  final String subtitle;
  final Widget? trailingWidget;
  final VoidCallback onTap;

  const DashboardCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.titleValue,
    required this.subtitle,
    this.trailingWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          title,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleValue,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: trailingWidget,
        onTap: onTap,
      ),
    );
  }
}
