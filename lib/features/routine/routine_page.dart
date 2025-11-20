import 'package:flutter/material.dart';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'static_routine.dart';
import 'assignment.dart';
import 'collect_data.dart';
import 'dynamic_routine_page.dart';

import 'package:uni_connect/features/navigation/side_navigation.dart';
import 'package:flutter/foundation.dart';
import 'package:uni_connect/features/web/web_layout.dart';

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
  //late Animation<double> _fadeAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Cache page widgets to avoid rebuilding on every tab switch
  Widget? _cachedSchedulePage;
  Widget? _cachedTimetablePage;
  Widget? _cachedAssignmentPage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // _fadeAnimation = CurvedAnimation(
    //   parent: _controller,
    //   curve: Curves.easeInOut,
    // );
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (!kIsWeb && details.delta.dx < -10) {
          _scaffoldKey.currentState?.openEndDrawer();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: kIsWeb ? null : const SideNavigation(),
        backgroundColor: kIsWeb ? Colors.transparent : const Color(0xFF0F3460),
        body: Column(
          children: [
            if (kIsWeb)
              Container(
                margin: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildWebTab("Schedule", 0),
                    _buildWebTab("Timetable", 1),
                    _buildWebTab("Assignments", 2),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadData(forceRefresh: true),
                color: Colors.cyanAccent,
                backgroundColor: const Color(0xFF1A1A2E),
                child: _buildBody(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: kIsWeb ? null : _buildNavBar(),
        floatingActionButton: _buildRefreshFAB(),
      ),
    );

    if (kIsWeb) {
      return WebLayout(currentRoute: '/routine', child: content);
    }
    return content;
  }

  Widget _buildWebTab(String label, int index) {
    final isActive = _page == index;
    return InkWell(
      onTap: () {
        if (!_isLoading) setState(() => _page = index);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.cyanAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
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
        results = await CollectData.collectAllData();
        await RoutineCache.saveRoutine(results);
      }

      if (!mounted) return;

      final sheet1 = results['sheet1'] ?? [];
      final sheet2 = results['sheet2'] ?? [];
      final sheet3 = results['sheet3'] ?? [];

      // Cache pages to avoid rebuilding heavy widgets on tab switch
      _cachedSchedulePage = Routine(
        key: const ValueKey('schedule'),
        sectionAData: sheet1,
        sectionBData: sheet2,
      );
      _cachedTimetablePage = RoutineTableView(
        key: const ValueKey('timetable'),
        sectionA: sheet1,
        sectionB: sheet2,
      );
      _cachedAssignmentPage = AssignmentPage(
        key: const ValueKey('assignments'),
        assignments: sheet3,
      );

      setState(() {
        pages = [
          _cachedSchedulePage!,
          _cachedTimetablePage!,
          _cachedAssignmentPage!,
        ];
        _isLoading = false;
      });

      _controller.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  //Load Routine Data End -------------------------------------------------------------------------------------------

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
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
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
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _loadData(forceRefresh: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: const Color(0xFF0F3460),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Use IndexedStack to keep all pages in memory but only show current one
    // This prevents rebuilding heavy widgets on tab switch
    return IndexedStack(index: _page, children: pages);
  }

  // Floating Action Button for refresh
  Widget? _buildRefreshFAB() {
    if (_isLoading) return null;

    return FloatingActionButton(
      onPressed: () => _loadData(forceRefresh: true),
      backgroundColor: Colors.cyanAccent.withValues(alpha: 0.9),
      foregroundColor: const Color(0xFF0F3460),
      tooltip: 'Refresh routine',
      child: const Icon(Icons.refresh),
    );
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
      animationDuration: const Duration(milliseconds: 300),
      animationCurve: Curves.easeInOut,
      onTap: (index) {
        if (index != _page && !_isLoading) {
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
