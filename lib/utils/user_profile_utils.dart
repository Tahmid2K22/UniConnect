import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// User profile utility
class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.tealAccent[400]!, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SocialIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String platform;
  final Map<String, dynamic>? userData;
  final Function(String link) onUpdate;

  const SocialIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.platform,
    required this.userData,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final url = userData?[platform] ?? '';
    return IconButton(
      icon: FaIcon(icon, color: color, size: 32),
      tooltip: 'Edit $platform link',
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => _EditLinkDialog(
            platform: platform,
            initialValue: url,
            onConfirm: onUpdate,
          ),
        );
      },
    );
  }
}

class _EditLinkDialog extends StatefulWidget {
  final String platform;
  final String initialValue;
  final Function(String) onConfirm;

  const _EditLinkDialog({
    required this.platform,
    required this.initialValue,
    required this.onConfirm,
  });

  @override
  State<_EditLinkDialog> createState() => _EditLinkDialogState();
}

class _EditLinkDialogState extends State<_EditLinkDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String platformTitle =
        widget.platform[0].toUpperCase() + widget.platform.substring(1);
    return AlertDialog(
      backgroundColor: const Color(0xFF201B4D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        'Edit your $platformTitle link',
        style: GoogleFonts.poppins(
          color: Colors.tealAccent[400]!,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: TextField(
        controller: _controller,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Paste or enter your link...',
          hintStyle: GoogleFonts.poppins(color: Colors.white54),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
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
          onPressed: () {
            widget.onConfirm(_controller.text.trim());
            Navigator.pop(context);
          },
          child: Text(
            'Update',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}