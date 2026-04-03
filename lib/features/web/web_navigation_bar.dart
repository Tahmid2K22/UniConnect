import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uni_connect/firebase/firestore/database.dart';
import 'package:uni_connect/utils/guest_service.dart';
import 'dart:convert';

class WebNavigationBar extends StatelessWidget {
  final String currentRoute;

  const WebNavigationBar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1024;

        return Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0B0B22).withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Logo / Brand
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.tealAccent[400]!, Colors.blueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'UniConnect',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Navigation - Desktop or Mobile
              if (isMobile)
                // Mobile: Hamburger Menu
                Row(
                  children: [
                    _ProfileDropdown(),
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: const Color(0xFF1A144B),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) =>
                              _MobileMenu(currentRoute: currentRoute),
                        );
                      },
                    ),
                  ],
                )
              else
              // Desktop: Full Navigation
              ...[
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                          },
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _NavBarItem(
                                icon: Icons.dashboard_rounded,
                                label: 'Dashboard',
                                route: '/frontpage',
                                isActive: currentRoute == '/frontpage',
                              ),
                              _NavBarItem(
                                icon: Icons.calendar_month_rounded,
                                label: 'Calendar',
                                route: '/calendar',
                                isActive: currentRoute == '/calendar',
                              ),
                              _NavBarItem(
                                icon: Icons.analytics_rounded,
                                label: 'Analytics',
                                route: '/analytics',
                                isActive: currentRoute == '/analytics',
                              ),
                              _NavBarItem(
                                icon: Icons.people_alt_rounded,
                                label: 'Teachers',
                                route: '/teachers',
                                isActive: currentRoute == '/teachers',
                              ),
                              _NavBarItem(
                                icon: Icons.library_books_rounded,
                                label: 'Resources',
                                route: '/resources',
                                isActive: currentRoute == '/resources',
                              ),
                              _NavBarItem(
                                icon: Icons.people_outline_rounded,
                                label: 'Batchmates',
                                route: '/batchmates',
                                isActive: currentRoute == '/batchmates',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _ProfileDropdown(),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MobileMenu extends StatelessWidget {
  final String currentRoute;

  const _MobileMenu({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MobileMenuItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            route: '/frontpage',
            isActive: currentRoute == '/frontpage',
          ),
          _MobileMenuItem(
            icon: Icons.calendar_month_rounded,
            label: 'Calendar',
            route: '/calendar',
            isActive: currentRoute == '/calendar',
          ),
          _MobileMenuItem(
            icon: Icons.analytics_rounded,
            label: 'Analytics',
            route: '/analytics',
            isActive: currentRoute == '/analytics',
          ),
          _MobileMenuItem(
            icon: Icons.people_alt_rounded,
            label: 'Teachers',
            route: '/teachers',
            isActive: currentRoute == '/teachers',
          ),
          _MobileMenuItem(
            icon: Icons.library_books_rounded,
            label: 'Resources',
            route: '/resources',
            isActive: currentRoute == '/resources',
          ),
          _MobileMenuItem(
            icon: Icons.people_outline_rounded,
            label: 'Batchmates',
            route: '/batchmates',
            isActive: currentRoute == '/batchmates',
          ),
        ],
      ),
    );
  }
}

class _MobileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  const _MobileMenuItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? Colors.tealAccent[400] : Colors.white60,
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          color: isActive ? Colors.tealAccent[400] : Colors.white60,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (!isActive) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = Colors.tealAccent[400]!;

    return InkWell(
      onTap: () {
        if (!isActive) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.15) : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor.withValues(alpha: 0.4) : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? activeColor : Colors.white60,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isActive ? activeColor : Colors.white60,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDropdown extends StatefulWidget {
  const _ProfileDropdown();

  @override
  State<_ProfileDropdown> createState() => _ProfileDropdownState();
}

class _ProfileDropdownState extends State<_ProfileDropdown> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await loadUserProfile();
    if (mounted) {
      setState(() {
        _userData = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      color: const Color(0xFF1A144B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.tealAccent[400],
            backgroundImage:
                _userData != null && _userData!['profile_pic'] != null
                ? MemoryImage(base64Decode(_userData!['profile_pic']))
                : null,
            child: _userData == null || _userData!['profile_pic'] == null
                ? const Icon(Icons.person, size: 20, color: Colors.black)
                : null,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _userData?['name'] ?? 'Student',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _userData?['roll'] ?? '',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white54,
            size: 18,
          ),
        ],
      ),
      onSelected: (value) async {
        if (value == 'profile') {
          Navigator.pushNamed(context, '/profile');
        } else if (value == 'settings') {
          Navigator.pushNamed(context, '/settings');
        } else if (value == 'logout') {
          await GuestService.logoutGuest();
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person_outline, color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Text(
                'My Profile',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(
                Icons.settings_outlined,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text('Settings', style: GoogleFonts.poppins(color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Sign Out',
                style: GoogleFonts.poppins(color: Colors.redAccent),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
