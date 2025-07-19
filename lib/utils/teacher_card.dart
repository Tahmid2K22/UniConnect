import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherCard extends StatelessWidget {
  final Map<String, dynamic> teacher;
  final VoidCallback onTap;
  final bool isGrid;

  const TeacherCard({
    super.key,
    required this.teacher,
    required this.onTap,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Colors.white.withValues(alpha: 0.04);
    if (isGrid) {
      // Grid style: avatar on top, text below
      return Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(teacher['profile_pic']),
                  radius: 50,
                  backgroundColor: Colors.white10,
                ),
                const SizedBox(height: 12),
                Text(
                  teacher['name'],
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${teacher['department']} | ${teacher['university']}',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // List style: avatar left, text right
      return Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(teacher['profile_pic']),
                  radius: 45,
                  backgroundColor: Colors.white10,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher['name'],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        teacher['department'],
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        teacher['university'],
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
