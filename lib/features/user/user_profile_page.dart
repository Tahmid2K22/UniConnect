import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uni_connect/features/navigation/side_navigation.dart';
import 'avg_cgpa_animation.dart';

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

  Future<void> loadProfile() async {
    final jsonString = await rootBundle.loadString(
      'assets/user_profile_demo.json',
    );
    setState(() {
      userData = json.decode(jsonString);
    });
  }

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
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/background4.png'),
              fit: BoxFit.cover,
            ),
          ),
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
                        backgroundColor: Colors.cyanAccent.withValues(
                          alpha: 0.2,
                        ),
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
                      // Institution, Dept, Roll - LARGER TEXT
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
                      // Year and Semester - LARGER TEXT
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
                        child: _buildCgpaChart(userData!['cgpa_list']),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCgpaChart(List cgpaList) {
    final double avgCgpa = cgpaList.isNotEmpty
        ? cgpaList.reduce((a, b) => a + b) / cgpaList.length
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'CGPA Progress',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 0.5, // Show 2.0, 2.5, 3.0, etc.
                    getTitlesWidget: (value, meta) {
                      if (value % 0.5 == 0) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 == 0 &&
                          value >= 0 &&
                          value < cgpaList.length) {
                        return Text(
                          'S${value.toInt() + 1}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),

                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              minY: 2.0, // Start from 2.0
              maxY: 4.0,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    cgpaList.length,
                    (i) =>
                        FlSpot(i.toDouble(), (cgpaList[i] as num).toDouble()),
                  ),
                  isCurved: true,
                  color: Colors.cyanAccent,
                  barWidth: 4,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedGradientCGPANumber(avgCgpa: avgCgpa),
      ],
    );
  }
}
