import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/teacher_card.dart';

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
                return TeacherCard(
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
                  child: TeacherCard(
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
