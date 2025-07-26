import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:provider/provider.dart';
import 'package:uni_connect/utils/font_scale.dart';

import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121232),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // About Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1C35),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About UniConnect',
                  style: GoogleFonts.poppins(
                    color: Colors.cyanAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version: 1.0.0',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Contributors:',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _buildContributor('Tahmid Chowdhury Mahin'),
                _buildContributor('Rafsan Riasat'),
                _buildContributor('Isaac Aneek'),
                _buildContributor('Utsa Roy'),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: _launchGitHub,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.blue, Colors.purple],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.4),
                            blurRadius: 15,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.code, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'View on GitHub',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Font size selector
          Padding(
            padding: const EdgeInsets.only(top: 32.0, bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Font Size",
                  style: GoogleFonts.poppins(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 14),
                Consumer<FontScaleProvider>(
                  builder: (context, fontProvider, _) {
                    double scale = fontProvider.fontScale;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _FontSizeOption(
                          label: "Small",
                          scale: 0.8,
                          selected: scale < 0.85,
                          onTap: () => fontProvider.setSmall(),
                        ),
                        _FontSizeOption(
                          label: "Medium",
                          scale: 0.9,
                          selected: scale >= 0.85 && scale < 0.95,
                          onTap: () => fontProvider.setMedium(),
                        ),
                        _FontSizeOption(
                          label: "Large",
                          scale: 1.0,
                          selected: scale >= 0.95,
                          onTap: () => fontProvider.setLarge(),
                        ),
                      ].map((w) => Expanded(child: w)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Logout Button
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.95, end: 1.0),
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: GestureDetector(
                    onTap: () => _showLogoutDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Colors.pinkAccent, Colors.deepPurpleAccent],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pinkAccent.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 1,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.logout, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Logout button
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B1C35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  // gihub launcher for UniConnect
  void _launchGitHub() async {
    final Uri url = Uri.parse(
      'https://github.com/Tahmid2K22/UniConnect/tree/main',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch GitHub repo.');
    }
  }

  // Contributors utility
  Widget _buildContributor(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.person_rounded, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            name,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _FontSizeOption extends StatelessWidget {
  final String label;
  final double scale;
  final bool selected;
  final VoidCallback onTap;

  const _FontSizeOption({
    required this.label,
    required this.scale,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.cyanAccent.withValues(alpha: 0.20)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? Colors.cyanAccent : Colors.white24,
            width: selected ? 2.0 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: Offset(0, 0),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: selected ? Colors.cyanAccent : Colors.white70,
              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              fontSize: scale * 17, // visually slightly larger
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
