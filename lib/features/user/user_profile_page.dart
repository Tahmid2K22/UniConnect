import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';

import 'package:hive/hive.dart';

import 'package:uni_connect/firebase/firestore/database.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:uni_connect/features/navigation/side_navigation.dart';

import 'package:uni_connect/utils/user_profile_utils.dart';
import 'package:uni_connect/widgets/cgpa_chart.dart';
import 'package:uni_connect/utils/glass_card.dart';

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
      colors: [
        Color.fromARGB(255, 11, 11, 34),
        Color.fromARGB(255, 11, 11, 34),
        Color.fromARGB(255, 11, 11, 34),
      ],
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
        backgroundColor: const Color.fromARGB(255, 11, 11, 34),
        body: RefreshIndicator(
          color: Colors.tealAccent[400]!,
          backgroundColor: const Color.fromARGB(255, 11, 11, 34),
          onRefresh: () async {
            final freshUser = await reloadUserProfile();
            setState(() {
              userData = freshUser;
            });
            // (optional) Show feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Profile refreshed from server!')),
            );
          },
          child: Container(
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
                          const SizedBox(height: 25),
                          GestureDetector(
                            onTap: _onProfilePicTap,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 64,
                                  backgroundImage: _profileImagePath != null
                                      ? FileImage(File(_profileImagePath!))
                                      : const AssetImage(
                                              'assets/profile/profile.jpg',
                                            )
                                            as ImageProvider,
                                  backgroundColor: Colors.tealAccent.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                                Container(
                                  width: 128,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            userData!['name'],
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userData!['university'],
                            style: GoogleFonts.poppins(
                              color: Colors.tealAccent[400]!,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 28),
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ProfileInfoRow(
                                  icon: Icons.school,
                                  label: 'Department',
                                  value: userData!['department'],
                                ),
                                ProfileInfoRow(
                                  icon: Icons.confirmation_number_rounded,
                                  label: 'Roll Number',
                                  value: userData!['roll'],
                                ),
                                ProfileInfoRow(
                                  icon: Icons.calendar_today_rounded,
                                  label: 'Year',
                                  value: userData!['current_year'].toString(),
                                ),
                                ProfileInfoRow(
                                  icon: Icons.calendar_view_month_rounded,
                                  label: 'Semester',
                                  value: userData!['current_semester']
                                      .toString(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          GlassCard(
                            child: CgpaChart(cgpaList: userData!['cgpa_list']),
                          ),
                          const SizedBox(height: 28),
                          const Center(
                            child: Text(
                              'Tap to update socials',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GlassCard(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SocialIconButton(
                                  icon: FontAwesomeIcons.facebookF,
                                  color: Colors.blueAccent,
                                  platform: 'facebook',
                                  userData: userData,
                                  onUpdate: (link) =>
                                      _updateSocialLink('facebook', link),
                                ),
                                const SizedBox(width: 30),
                                SocialIconButton(
                                  icon: FontAwesomeIcons.linkedinIn,
                                  color: Colors.blue,
                                  platform: 'linkedin',
                                  userData: userData,
                                  onUpdate: (link) =>
                                      _updateSocialLink('linkedin', link),
                                ),
                                const SizedBox(width: 30),
                                SocialIconButton(
                                  icon: FontAwesomeIcons.github,
                                  color: Colors.black87,
                                  platform: 'github',
                                  userData: userData,
                                  onUpdate: (link) =>
                                      _updateSocialLink('github', link),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Center(
                            child: Text(
                              'Tap to update number',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GlassCard(
                            child: GestureDetector(
                              onTap: () async {
                                final shouldEdit = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF201B4D),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    title: Text(
                                      'Update Phone Number',
                                      style: GoogleFonts.poppins(
                                        color: Colors.tealAccent[400]!,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    content: Text(
                                      'Do you want to update your phone number?',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(
                                          'Cancel',
                                          style: GoogleFonts.poppins(
                                            color: Colors.tealAccent[400]!,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.tealAccent[400]!,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(
                                          'Update',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (shouldEdit == true) {
                                  _editPhoneNumber();
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone,
                                    color: Colors.tealAccent[400]!,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Contact',
                                        style: GoogleFonts.poppins(
                                          color: Colors.tealAccent[400]!,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        userData?['phone'] ?? 'No number set',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // Load User Data Start ----------------------------------------------------------------------------------

  Future<void> loadProfile() async {
    userData = await loadUserProfile();
    setState(() {});
  }

  void _loadProfileImagePath() {
    _profileImagePath = loadLocalProfileImagePath();
    setState(() {});
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
            color: Colors.tealAccent[400]!,
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
                color: Colors.tealAccent[400]!,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent[400]!,
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

      await updateProfilePic(savedImage.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change profile picture.')),
      );
    }
  }

  // Call this after user changes their profile picture
  Future<void> updateProfilePic(String localPath) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    final file = File(localPath);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;
    final resized = img.copyResize(image, width: 120, height: 120); // Low-res
    final jpg = img.encodeJpg(resized, quality: 60);
    final base64Str = base64Encode(jpg);

    await FirebaseFirestore.instance
        .collection('students')
        .doc(user.email)
        .update({'profile_pic': base64Str});

    updateCachedProfilePic(base64Str);
    updateCachedProfileImagePath(localPath);
  }

  Future<void> _updateSocialLink(String field, String link) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    await FirebaseFirestore.instance
        .collection('students')
        .doc(user.email)
        .update({field: link});

    // Update local cache and UI
    userData?[field] = link;
    if (Hive.isBoxOpen('userBox')) {
      Hive.box('userBox').put(user.email, userData);
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${field[0].toUpperCase()}${field.substring(1)} link updated!',
        ),
      ),
    );
  }

  Future<void> _editPhoneNumber() async {
    final controller = TextEditingController(text: userData?['phone'] ?? '');
    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF201B4D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Enter new phone number',
          style: GoogleFonts.poppins(
            color: Colors.tealAccent[400]!,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Phone number',
            hintStyle: GoogleFonts.poppins(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.tealAccent[400]!),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent[400]!,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (updated != null &&
        updated.isNotEmpty &&
        updated != userData?['phone']) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(user.email)
            .update({'phone': updated});
        userData?['phone'] = updated;
        if (Hive.isBoxOpen('userBox')) {
          Hive.box('userBox').put(user.email, userData);
        }
        setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Phone number updated!')));
      }
    }
  }
}
