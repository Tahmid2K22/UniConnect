import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/batchmate_card.dart';

/// Custom SearchDelegate for batchmates
class BatchmateSearchDelegate extends SearchDelegate {
  final Future<List<Map<String, dynamic>>> Function() loadBatchmates;
  final bool isGrid;
  final void Function(BuildContext, Map<String, dynamic>) openDetails;

  BatchmateSearchDelegate(this.loadBatchmates, this.isGrid, this.openDetails);

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
  String? get searchFieldLabel => 'Search by name or roll';

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
        future: loadBatchmates(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Container();
          final queryLower = query.toLowerCase();
          final results = snapshot.data!.where((mate) {
            final name = mate['name'].toString().toLowerCase();
            final roll = mate['roll'].toString().toLowerCase();
            return name.contains(queryLower) || roll.contains(queryLower);
          }).toList();

          if (results.isEmpty) {
            return Center(
              child: Text(
                'No batchmate found.',
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            );
          }

          results.sort((a, b) {
            final aRoll = int.tryParse(a['roll'].toString());
            final bRoll = int.tryParse(b['roll'].toString());
            if (aRoll != null && bRoll != null) {
              return aRoll.compareTo(bRoll);
            } else {
              return a['roll'].toString().compareTo(b['roll'].toString());
            }
          });

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
                final mate = results[index];
                return BatchmateCard(
                  mate: mate,
                  onTap: () {
                    close(context, mate);
                    openDetails(context, mate);
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
                final mate = results[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BatchmateCard(
                    mate: mate,
                    onTap: () {
                      close(context, mate);
                      openDetails(context, mate);
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
