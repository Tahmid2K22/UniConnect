import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uni_connect/features/web/web_layout.dart';
import 'package:uni_connect/utils/glass_card.dart';
import 'package:uni_connect/firebase/firestore/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img_lib;

class WebProfilePage extends StatefulWidget {
  const WebProfilePage({super.key});

  @override
  State<WebProfilePage> createState() => _WebProfilePageState();
}

class _WebProfilePageState extends State<WebProfilePage> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  Uint8List? _newImageBytes;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await loadUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _newImageBytes = bytes;
      });

      // Save immediately or add a save button?
      // For now, let's simulate save on pick for simplicity or add a save button.
      // Let's add a save button in the UI if new image is picked.
    }
  }

  Future<void> _saveProfile() async {
    if (_newImageBytes == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return;

      // Show loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading profile picture...')),
      );

      // Resize and compress the image
      String base64Image = base64Encode(_newImageBytes!);

      try {
        // Import image package for resizing
        // This requires: import 'package:image/image.dart' as img;
        final img = await compute(_resizeImage, _newImageBytes!);
        if (img != null) {
          base64Image = base64Encode(img);
        }
      } catch (e) {
        debugPrint('Error resizing image: $e');
        // Continue with original if resize fails
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.email)
          .update({'profile_pic': base64Image});

      // Update cache
      updateCachedProfilePic(base64Image);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );

      setState(() {
        _newImageBytes = null;
      });

      // Reload profile
      await reloadUserProfile();
      _loadProfile();
    } catch (e) {
      debugPrint('Error saving profile picture: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile picture: $e')),
      );
    }
  }

  static Uint8List? _resizeImage(Uint8List bytes) {
    try {
      // This will be imported separately
      final image = img_lib.decodeImage(bytes);
      if (image != null) {
        final resized = img_lib.copyResize(image, width: 120);
        return Uint8List.fromList(img_lib.encodeJpg(resized, quality: 60));
      }
    } catch (e) {
      debugPrint('Image resize error: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return WebLayout(
      currentRoute: '/profile',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Picture Section
                          Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 80,
                                    backgroundColor: Colors.tealAccent[400],
                                    backgroundImage: _newImageBytes != null
                                        ? MemoryImage(_newImageBytes!)
                                        : (_userProfile != null &&
                                                  _userProfile!['profile_pic'] !=
                                                      null
                                              ? MemoryImage(
                                                  base64Decode(
                                                    _userProfile!['profile_pic'],
                                                  ),
                                                )
                                              : null),
                                    child:
                                        (_newImageBytes == null &&
                                            (_userProfile == null ||
                                                _userProfile!['profile_pic'] ==
                                                    null))
                                        ? const Icon(
                                            Icons.person,
                                            size: 80,
                                            color: Colors.black,
                                          )
                                        : null,
                                  ),
                                  InkWell(
                                    onTap: _pickImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.tealAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.black,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_newImageBytes != null) ...[
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.tealAccent[400],
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Save Photo'),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(width: 40),

                          // Profile Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userProfile?['name'] ?? 'Student Name',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _userProfile?['university'] ??
                                      'University Name',
                                  style: GoogleFonts.poppins(
                                    color: Colors.tealAccent[400],
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _ProfileDetailRow(
                                  label: 'Department',
                                  value: _userProfile?['department'] ?? 'N/A',
                                ),
                                _ProfileDetailRow(
                                  label: 'Roll Number',
                                  value: _userProfile?['roll'] ?? 'N/A',
                                ),
                                _ProfileDetailRow(
                                  label: 'Email',
                                  value: _userProfile?['email'] ?? 'N/A',
                                ),
                                _ProfileDetailRow(
                                  label: 'Phone',
                                  value: _userProfile?['phone'] ?? 'N/A',
                                ),
                                _ProfileDetailRow(
                                  label: 'Blood Group',
                                  value: _userProfile?['blood_group'] ?? 'N/A',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
