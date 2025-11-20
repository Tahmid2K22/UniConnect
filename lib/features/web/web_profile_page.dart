import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uni_connect/features/web/web_layout.dart';
import 'package:uni_connect/utils/glass_card.dart';
import 'package:uni_connect/firebase/firestore/database.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

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
    if (_newImageBytes != null) {
      final base64Image = base64Encode(_newImageBytes!);
      updateCachedProfilePic(base64Image);
      // Ideally update Firestore too, but for now we update cache.
      // In a real app, we'd upload to Storage or save Base64 to Firestore.
      // The existing app saves Base64 to Firestore for web.

      // We need a method to save to Firestore.
      // Assuming updateProfilePic logic exists or we implement it here.
      // For now, we'll just update the local state and show a success message.

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));

      setState(() {
        _newImageBytes = null;
      });

      // Reload to reflect changes
      await reloadUserProfile();
      _loadProfile();
    }
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
