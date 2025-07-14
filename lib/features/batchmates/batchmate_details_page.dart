import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../widgets/get_profile_pic.dart';

class BatchmateDetailsPage extends StatelessWidget {
  final Map<String, dynamic> mate;
  const BatchmateDetailsPage({required this.mate, super.key});

  @override
  Widget build(BuildContext context) {
    final bgGradient = const LinearGradient(
      colors: [Color(0xFF1A144B), Color(0xFF2B175C), Color(0xFF181A2A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF181A2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181A2A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        title: Text(
          mate['name'],
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundImage: getProfileImageProvider(
                      mate['profile_pic'],
                    ),
                    radius: 56,
                  ),

                  const SizedBox(height: 20),
                  Text(
                    mate['name'],
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${mate['university']} | ${mate['department']}',
                    style: GoogleFonts.poppins(
                      color: Colors.cyanAccent.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Roll: ${mate['roll']}',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _InfoRow(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: mate['email'],
                    onTap: () => _launchUrl('mailto:${mate['email']}'),
                  ),
                  _InfoRow(
                    icon: Icons.bloodtype,
                    label: 'Blood G.',
                    value: mate['blood_group'],
                  ),
                  _InfoRow(
                    icon: Icons.phone_rounded,
                    label: 'Phone',
                    value: mate['phone'],
                    trailing: IconButton(
                      icon: Icon(
                        Icons.call,
                        color: Colors.greenAccent,
                        size: 22,
                      ),
                      tooltip: 'Call',
                      onPressed: () => _callNumber(mate['phone']),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.10),
                    thickness: 1.1,
                    height: 32,
                  ),
                  Text(
                    'Social Profiles',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialIconButton(
                        icon: FontAwesomeIcons.github,
                        color: Colors.white,
                        tooltip: 'GitHub',
                        onPressed: () =>
                            _launchSocialUrl(context, mate['github'], 'GitHub'),
                      ),
                      const SizedBox(width: 18),
                      _SocialIconButton(
                        icon: FontAwesomeIcons.facebook,
                        color: Colors.blueAccent,
                        tooltip: 'Facebook',
                        onPressed: () => _launchSocialUrl(
                          context,
                          mate['facebook'],
                          'Facebook',
                        ),
                      ),
                      const SizedBox(width: 18),
                      _SocialIconButton(
                        icon: FontAwesomeIcons.linkedin,
                        color: Colors.blue[700]!,
                        tooltip: 'LinkedIn',
                        onPressed: () => _launchSocialUrl(
                          context,
                          mate['linkedin'],
                          'LinkedIn',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _launchSocialUrl(
    BuildContext context,
    String? url,
    String platform,
  ) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$platform account not found'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    // Ensure URL has a scheme
    final formattedUrl = url.startsWith('http://') || url.startsWith('https://')
        ? url
        : 'https://$url';
    final uri = Uri.parse(formattedUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open $platform'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: Colors.cyanAccent, size: 22),
            const SizedBox(width: 14),
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _SocialIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: FaIcon(icon, color: color, size: 28),
      tooltip: tooltip,
      onPressed: onPressed,
      splashRadius: 24,
    );
  }
}
