import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:uni_connect/features/navigation/side_navigation.dart';
import 'package:uni_connect/widgets/cgpa_chart.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // Load Data Start -------------------------------------------------------------------------------------------------------------------

  Future<void> loadProfile() async {
    final jsonString = await rootBundle.loadString(
      'assets/user_profile_demo.json',
    );
    setState(() {
      userData = json.decode(jsonString);
    });
  }

  // Load Data End -------------------------------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx < -10) {
          scaffoldKey.currentState?.openEndDrawer();
        }
      },
      child: Scaffold(
        key: scaffoldKey,
        endDrawer: const SideNavigation(),
        backgroundColor: const Color(0xFF0E0E2C),
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: userData == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Profile Pic
                      CircleAvatar(
                        radius: 54,
                        backgroundImage: AssetImage(
                          'assets/profile/profile.jpg',
                        ),
                        backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                      ),
                      const SizedBox(height: 18),
                      // Name
                      Text(
                        userData!['name'],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Institution, Dept, Roll
                      Text(
                        userData!['institution'],
                        style: GoogleFonts.poppins(
                          color: Colors.cyanAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dept. of ${userData!['department']}',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Roll: ${userData!['roll_number']}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Year and Semester
                      Text(
                        'Year ${userData!['current_year']}, Semester ${userData!['current_semester']}',
                        style: GoogleFonts.poppins(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // CGPA Chart + Average
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: CgpaChart(cgpaList: userData!['cgpa_list']),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
