import 'package:flutter/material.dart';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'static_routine.dart';
import 'assignment.dart';
import 'collect_data.dart';
import 'dynamic_routine_page.dart';

import 'package:uni_connect/features/navigation/side_navigation.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  _RoutinePageState createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage>
    with SingleTickerProviderStateMixin {
  int _page = 0;
  bool _isLoading = true;
  String? _error;
  late List<Widget> pages;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx < -10) {
          _scaffoldKey.currentState?.openEndDrawer();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: const SideNavigation(),
        backgroundColor: const Color(0xFF0F3460),
        body: _buildBody(),
        bottomNavigationBar: GestureDetector(
          onDoubleTap: _showRefreshDialog,
          child: _buildNavBar(),
        ),
      ),
    );
  }

  //Load Routine Data Start -------------------------------------------------------------------------------------------

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic>? results;
      if (!forceRefresh) {
        results = await RoutineCache.loadRoutine();
      }
      if (results == null) {
        // No cache or user requested refresh
        results = await CollectData.collectAllData();
        await RoutineCache.saveRoutine(results);
      }

      if (!mounted) return;

      setState(() {
        final sheet1 = results!['sheet1'] ?? [];
        final sheet2 = results['sheet2'] ?? [];
        final sheet3 = results['sheet3'] ?? [];

        pages = [
          Routine(sectionAData: sheet1, sectionBData: sheet2),
          RoutineTableView(sectionA: sheet1, sectionB: sheet2),
          AssignmentPage(assignments: sheet3),
        ];
        _isLoading = false;
      });
      _controller.forward();
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  //Load Routine Data End -------------------------------------------------------------------------------------------

  //Double tap for refresh

  void _showRefreshDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.cyanAccent.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        title: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: [Color.fromARGB(255, 153, 200, 214), Color(0xFF00DBDE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: const Text(
            'Refresh Routine',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.1,
            ),
          ),
        ),
        content: const Text(
          'Do you want to refresh the routine data?',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.cyanAccent,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _loadData(forceRefresh: true);
            },
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  //Body utils
  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.cyanAccent,
              strokeWidth: 4,
            ),
            const SizedBox(height: 20),
            Text(
              "Loading your schedule...",
              style: TextStyle(
                color: Colors.cyanAccent.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.redAccent.withValues(alpha: 0.7),
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(opacity: _fadeAnimation, child: pages[_page]);
  }

  // Navbar utils
  Widget _buildNavBar() {
    return CurvedNavigationBar(
      index: _page,
      height: 60,
      items: [
        _buildNavItem(Icons.schedule, "Schedule", 0),
        _buildNavItem(Icons.table_chart, "Timetable", 1),
        _buildNavItem(Icons.assignment, "Assignments", 2),
      ],
      color: const Color(0xFF16213E),
      buttonBackgroundColor: const Color(0xFF0F3460),
      backgroundColor: Colors.transparent,
      animationDuration: const Duration(milliseconds: 400),
      animationCurve: Curves.easeInOutBack,
      onTap: (index) {
        if (index != _page) {
          setState(() => _page = index);
        }
      },
    );
  }

  //Navbar item utils

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _page == index;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 28,
          color: isActive ? Colors.cyanAccent : Colors.white70,
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: !isActive
              ? Text(
                  label,
                  key: ValueKey(label),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ],
    );
  }
}
