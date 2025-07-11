import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:uni_connect/features/navigation/side_navigation.dart';
import 'package:uni_connect/widgets/cgpa_chart.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? userData;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    loadProfile();
    _loadProfileImagePath();
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final backgroundGradient = const LinearGradient(
      colors: [Color(0xFF1A144B), Color(0xFF2B175C), Color(0xFF181A2A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

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
        body: Container(
          decoration: BoxDecoration(gradient: backgroundGradient),
          width: double.infinity,
          height: double.infinity,
          child: userData == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 36,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Picture
                        GestureDetector(
                          onTap: _onProfilePicTap,
                          child: CircleAvatar(
                            radius: 64,
                            backgroundImage: _profileImagePath != null
                                ? FileImage(File(_profileImagePath!))
                                : AssetImage('assets/profile/profile.jpg')
                                      as ImageProvider,
                            backgroundColor: Colors.cyanAccent.withValues(
                              alpha: 0.18,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                        // Name
                        Text(
                          userData!['name'],
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 34, // Bigger name text
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Institution
                        Text(
                          userData!['institution'],
                          style: GoogleFonts.poppins(
                            color: Colors.cyanAccent,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Info Card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 22,
                            horizontal: 24,
                          ),
                          margin: const EdgeInsets.only(bottom: 28),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.cyanAccent.withValues(alpha: 0.11),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ProfileInfoRow(
                                icon: Icons.school,
                                label: 'Department',
                                value: userData!['department'],
                              ),
                              const SizedBox(height: 14),
                              _ProfileInfoRow(
                                icon: Icons.confirmation_number_rounded,
                                label: 'Roll Number',
                                value: userData!['roll_number'],
                              ),
                              const SizedBox(height: 14),
                              _ProfileInfoRow(
                                icon: Icons.calendar_today_rounded,
                                label: 'Year',
                                value: userData!['current_year'].toString(),
                              ),
                              const SizedBox(height: 14),
                              _ProfileInfoRow(
                                icon: Icons.calendar_view_month_rounded,
                                label: 'Semester',
                                value: userData!['current_semester'].toString(),
                              ),
                            ],
                          ),
                        ),
                        // CGPA Chart + Average
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: CgpaChart(cgpaList: userData!['cgpa_list']),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // Load User Data Start ----------------------------------------------------------------------------------

  Future<void> loadProfile() async {
    final jsonString = await rootBundle.loadString(
      'assets/user_profile_demo.json',
    );
    setState(() {
      userData = json.decode(jsonString);
    });
  }

  void _loadProfileImagePath() {
    final box = Hive.box('profileBox');
    setState(() {
      _profileImagePath = box.get('profileImagePath');
    });
  }

  // Load User Data End ----------------------------------------------------------------------------------

  // Change profile pic
  Future<void> _onProfilePicTap() async {
    final shouldChange = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF201B4D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Change Profile Picture?',
          style: GoogleFonts.poppins(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          'Do you want to select a new profile picture?',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldChange != true) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(
        picked.path,
      ).copy('${appDir.path}/$fileName');

      if (!mounted) return;
      setState(() {
        _profileImagePath = savedImage.path;
      });

      if (Hive.isBoxOpen('profileBox')) {
        Hive.box('profileBox').put('profileImagePath', savedImage.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change profile picture.')),
      );
    }
  }
}

// User profile utility
class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 28),
        const SizedBox(width: 14),
        Text(
          '$label:',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
