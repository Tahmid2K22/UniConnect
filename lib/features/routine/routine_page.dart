import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'collect_data.dart';
import 'dynamic_routine_page.dart';
import 'static_routine.dart';
import 'assignment.dart';
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

  Future<void> _loadData() async {
    try {
      final results = await CollectData.collectAllData();
      if (!mounted) return;

      setState(() {
        final sheet1 = results['sheet1'] ?? [];
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
        bottomNavigationBar: _buildNavBar(),
      ),
    );
  }

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
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                  foregroundColor: Colors.cyanAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text("TRY AGAIN"),
                onPressed: _loadData,
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(opacity: _fadeAnimation, child: pages[_page]);
  }

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
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.cyanAccent : Colors.white70,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
