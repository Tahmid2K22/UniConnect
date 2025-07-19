import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:uni_connect/firebase/firestore/database.dart';
import 'teacher_details_page.dart';
import 'package:uni_connect/features/navigation/side_navigation.dart';

import '../../utils/teacher_card.dart';
import '../../widgets/teacher_search.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  bool showGrid = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- Title precedence map (lower is higher priority) ---
  static const Map<String, int> _titlePriority = {
    'Head': 0,
    'Professor': 1,
    'Associate Professor': 2,
    'Assistant Professor': 3,
    'Lecturer': 4,
    // others: 5+
  };

  // Sort list by title precedence, then alphabetically
  List<Map<String, dynamic>> _sortTeachers(
    List<Map<String, dynamic>> teachers,
  ) {
    teachers.sort((a, b) {
      final titleA = (a['title'] ?? '').toString();
      final titleB = (b['title'] ?? '').toString();
      final priA = _titlePriority[titleA] ?? 100;
      final priB = _titlePriority[titleB] ?? 100;
      // First by precedence
      if (priA != priB) return priA.compareTo(priB);
      // Then alphabetically by title
      return titleA.compareTo(titleB);
    });
    return teachers;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundGradient = LinearGradient(
      colors: [Color(0xFF1A144B), Color(0xFF2B175C), Color(0xFF181A2A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx < -10) {
          _scaffoldKey.currentState?.openEndDrawer();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: const SideNavigation(),
        backgroundColor: const Color(0xFF181A2A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Teachers',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: Colors.cyanAccent),
              tooltip: 'Search',
              onPressed: () async {
                final result = await showSearch(
                  context: context,
                  delegate: TeacherSearchDelegate(
                    fetchTeachersFromFirestore,
                    showGrid,
                    _openDetails,
                  ),
                );
                if (result != null && result is Map<String, dynamic>) {
                  _openDetails(context, result);
                }
              },
            ),
            IconButton(
              icon: Icon(
                showGrid ? Icons.list : Icons.grid_view,
                color: Colors.cyanAccent,
              ),
              tooltip: showGrid ? 'Show List' : 'Show Grid',
              onPressed: () => setState(() => showGrid = !showGrid),
            ),
          ],
        ),
        body: RefreshIndicator(
          color: Colors.cyanAccent,
          backgroundColor: const Color(0xFF181A2A),
          onRefresh: () async {
            await reloadTeachers();
            setState(() {}); // rebuild to show fresh data
          },
          child: Container(
            decoration: BoxDecoration(gradient: backgroundGradient),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchTeachersFromFirestore(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                // --- SORT THE TEACHERS BY TITLE PRECEDENCE BEFORE DISPLAY ---
                final teachers = _sortTeachers(
                  List<Map<String, dynamic>>.from(snapshot.data!),
                );
                if (showGrid) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight,
                        ),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 20,
                                crossAxisSpacing: 20,
                                childAspectRatio: 0.78,
                              ),
                          itemCount: teachers.length,
                          itemBuilder: (context, index) {
                            final teacher = teachers[index];
                            return TeacherCard(
                              teacher: teacher,
                              onTap: () => _openDetails(context, teacher),
                              isGrid: true,
                            );
                          },
                        ),
                      );
                    },
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: teachers.length,
                    itemBuilder: (context, index) {
                      final teacher = teachers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TeacherCard(
                          teacher: teacher,
                          onTap: () => _openDetails(context, teacher),
                          isGrid: false,
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, Map<String, dynamic> teacher) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TeacherDetailsPage(teacher: teacher)),
    );
  }
}
