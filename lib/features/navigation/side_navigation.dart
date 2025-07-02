import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

Future<Map<String, dynamic>> loadProfile() async {
  final String jsonString = await rootBundle.loadString(
    'assets/user_profile_demo.json',
  );
  return json.decode(jsonString);
}

class SideNavigation extends StatefulWidget {
  const SideNavigation({super.key});

  @override
  State<SideNavigation> createState() => _SideNavigationState();
}

class _SideNavigationState extends State<SideNavigation> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final profilePic = CircleAvatar(
      radius: 32,
      backgroundImage: AssetImage('assets/profile/profile.jpg'),
    );

    final navItems = [
      {"icon": Icons.home, "label": "Home", "route": "/frontpage"},
      {"icon": Icons.chat, "label": "Chatbot", "route": "/chat"},
      {"icon": Icons.check_circle, "label": "Todo", "route": "/todo"},
      {"icon": Icons.feed, "label": "Resources", "route": "/resources"},
      {"icon": Icons.people, "label": "Batchmates", "route": "/batchmates"},
      {"icon": Icons.school, "label": "Teacher's Info", "route": "/teachers"},
      {"icon": Icons.schedule, "label": "Routine", "route": "/routine"},
      {"icon": Icons.analytics, "label": "Analytics", "route": "/analytics"},
    ];

    final settingsButton = Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: IconButton(
          icon: Icon(Icons.settings, color: Colors.white70, size: 28),
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, "/settings");
          },
          splashRadius: 28,
        ),
      ),
    );

    return Drawer(
      backgroundColor: const Color(0xFF121232),
      child: SafeArea(
        child: Column(
          children: [
            // Profile Section
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/profile");
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Row(
                        children: [
                          profilePic,
                          SizedBox(width: 14),
                          Expanded(child: CircularProgressIndicator()),
                        ],
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      final profile = snapshot.data!;
                      return Row(
                        children: [
                          profilePic,
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile['name'],
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  profile['institution'],
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${profile['department']} Dept.',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Roll: ${profile['roll_number']}',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
            // Navigation grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                child: LayoutGrid(
                  columnSizes: [1.fr, 1.fr],
                  rowSizes: [1.fr, 1.fr, 1.fr, 1.fr],
                  rowGap: 18,
                  columnGap: 18,
                  children: List.generate(
                    navItems.length,
                    (i) => _SidebarButton(
                      icon: navItems[i]['icon'] as IconData,
                      label: navItems[i]['label'] as String,
                      route: navItems[i]['route'] as String,
                    ),
                  ),
                ),
              ),
            ),
            // Settings button at bottom right
            settingsButton,
          ],
        ),
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Material(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.cyanAccent, size: 28),
                SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
