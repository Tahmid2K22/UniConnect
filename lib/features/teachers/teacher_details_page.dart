import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../utils/info_row.dart';

class TeacherDetailsPage extends StatelessWidget {
  final Map<String, dynamic> teacher;
  const TeacherDetailsPage({required this.teacher, super.key});

  @override
  Widget build(BuildContext context) {
    final bgGradient = const LinearGradient(
      colors: [Color(0xFF201B4D), Color(0xFF2B175C), Color(0xFF181A2A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Color(0xFF181A2A),
      appBar: AppBar(
        backgroundColor: Color(0xFF181A2A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        title: Text(
          teacher['name'],
          style: GoogleFonts.poppins(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                CircleAvatar(
                  backgroundImage: NetworkImage(teacher['profile_pic']),
                  radius: 56,
                  backgroundColor: Colors.white10,
                ),

                const SizedBox(height: 20),
                Text(
                  teacher['name'],
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${teacher['university']} | ${teacher['department']}',
                  style: GoogleFonts.poppins(
                    color: Colors.cyanAccent.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      InfoRow(
                        icon: Icons.mail_outline,
                        label: 'Email',
                        value: teacher['email'],
                        onTap: () => _launchEmail(teacher['email']),
                      ),
                      InfoRow(
                        icon: Icons.badge,
                        label: 'Title',
                        value: teacher['title'],
                      ),
                      InfoRow(
                        icon: Icons.phone_rounded,
                        label: 'Phone',
                        value: teacher['phone'],
                        trailing: IconButton(
                          icon: Icon(
                            Icons.call,
                            color: Colors.greenAccent,
                            size: 22,
                          ),
                          tooltip: 'Call',
                          onPressed: () => _callNumber(teacher['phone']),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
