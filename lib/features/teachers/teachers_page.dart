import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:uni_connect/firebase/firestore/database.dart';
import 'teacher_details_page.dart';

import 'package:uni_connect/features/navigation/side_navigation.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  bool showGrid = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
        body: Container(
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchTeachersFromFirestore(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final teachers = snapshot.data!;
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
                          return _TeacherCard(
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
                      child: _TeacherCard(
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
    );
  }

  void _openDetails(BuildContext context, Map<String, dynamic> teacher) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TeacherDetailsPage(teacher: teacher)),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final Map<String, dynamic> teacher;
  final VoidCallback onTap;
  final bool isGrid;

  const _TeacherCard({
    required this.teacher,
    required this.onTap,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Colors.white.withValues(alpha: 0.04);
    if (isGrid) {
      // Grid style: avatar on top, text below
      return Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(teacher['profile_pic']),
                  radius: 56,
                  backgroundColor: Colors.white10,
                ),
                const SizedBox(height: 12),
                Text(
                  teacher['name'],
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${teacher['department']} | ${teacher['university']}',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // List style: avatar left, text right
      return Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(teacher['profile_pic']),
                  radius: 56,
                  backgroundColor: Colors.white10,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher['name'],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        teacher['department'],
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        teacher['university'],
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

/// Custom SearchDelegate for teachers
class TeacherSearchDelegate extends SearchDelegate {
  final Future<List<Map<String, dynamic>>> Function() loadTeachers;
  final bool isGrid;
  final void Function(BuildContext, Map<String, dynamic>) openDetails;

  TeacherSearchDelegate(this.loadTeachers, this.isGrid, this.openDetails);

  @override
  TextStyle? get searchFieldStyle => GoogleFonts.poppins(
    color: Colors.white,
    fontSize: 17,
    fontWeight: FontWeight.w500,
  );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF181A2A),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.cyanAccent,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: GoogleFonts.poppins(color: Colors.white54),
        border: InputBorder.none,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.poppins(color: Colors.white),
        bodyLarge: GoogleFonts.poppins(color: Colors.white),
        bodyMedium: GoogleFonts.poppins(color: Colors.white),
        bodySmall: GoogleFonts.poppins(color: Colors.white70),
      ),
      colorScheme: base.colorScheme.copyWith(
        surface: const Color(0xFF181A2A),
        primary: Colors.cyanAccent,
        onPrimary: Colors.cyanAccent,
      ),
    );
  }

  @override
  String? get searchFieldLabel => 'Search by name or dept';

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A144B), Color(0xFF2B175C), Color(0xFF181A2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: loadTeachers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Container();
          final queryLower = query.toLowerCase();
          final results = snapshot.data!.where((teacher) {
            final name = teacher['name'].toString().toLowerCase();
            final dept = teacher['department'].toString().toLowerCase();
            return name.contains(queryLower) || dept.contains(queryLower);
          }).toList();

          if (results.isEmpty) {
            return Center(
              child: Text(
                'No teacher found.',
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            );
          }

          if (isGrid) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.78,
              ),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final teacher = results[index];
                return _TeacherCard(
                  teacher: teacher,
                  onTap: () {
                    close(context, teacher);
                    openDetails(context, teacher);
                  },
                  isGrid: true,
                );
              },
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final teacher = results[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TeacherCard(
                    teacher: teacher,
                    onTap: () {
                      close(context, teacher);
                      openDetails(context, teacher);
                    },
                    isGrid: false,
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon: Icon(Icons.clear, color: Colors.cyanAccent),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: Icon(Icons.arrow_back, color: Colors.cyanAccent, size: 26),
    onPressed: () => close(context, null),
  );
}
