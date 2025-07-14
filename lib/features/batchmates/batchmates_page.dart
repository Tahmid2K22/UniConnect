import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uni_connect/firebase/firestore/database.dart';
import 'batchmate_details_page.dart';
import 'package:uni_connect/features/navigation/side_navigation.dart';
import '../../widgets/get_profile_pic.dart';

class BatchmatesPage extends StatefulWidget {
  const BatchmatesPage({super.key});

  @override
  State<BatchmatesPage> createState() => _BatchmatesPageState();
}

class _BatchmatesPageState extends State<BatchmatesPage> {
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
            'Batchmates',
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
                  delegate: BatchmateSearchDelegate(
                    fetchBatchmatesFromFirestore,
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
            future: fetchBatchmatesFromFirestore(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final batchmates = snapshot.data!;
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
                        itemCount: batchmates.length,
                        itemBuilder: (context, index) {
                          final mate = batchmates[index];
                          return _BatchmateCard(
                            mate: mate,
                            onTap: () => _openDetails(context, mate),
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
                  itemCount: batchmates.length,
                  itemBuilder: (context, index) {
                    final mate = batchmates[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _BatchmateCard(
                        mate: mate,
                        onTap: () => _openDetails(context, mate),
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

  void _openDetails(BuildContext context, Map<String, dynamic> mate) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BatchmateDetailsPage(mate: mate)),
    );
  }
}

class _BatchmateCard extends StatelessWidget {
  final Map<String, dynamic> mate;
  final VoidCallback onTap;
  final bool isGrid;

  const _BatchmateCard({
    required this.mate,
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
                  backgroundImage: getProfileImageProvider(mate['profile_pic']),
                  radius: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  mate['name'],
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${mate['department']} | ${mate['roll']}',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mate['university'],
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 12,
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
                  backgroundImage: getProfileImageProvider(mate['profile_pic']),
                  radius: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mate['name'],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${mate['department']} | ${mate['roll']}',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mate['university'],
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
                return _BatchmateCard(
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
                  child: _BatchmateCard(
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
