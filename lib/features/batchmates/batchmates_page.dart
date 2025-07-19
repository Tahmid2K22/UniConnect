import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:uni_connect/firebase/firestore/database.dart';

import 'batchmate_details_page.dart';

import 'package:uni_connect/features/navigation/side_navigation.dart';

import '../../utils/batchmate_card.dart';
import '../../widgets/batchmate_search.dart';

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
        body: RefreshIndicator(
          color: Colors.cyanAccent,
          backgroundColor: const Color(0xFF181A2A),
          onRefresh: () async {
            await reloadBatchmates();
            setState(() {});
          },
          child: Container(
            decoration: BoxDecoration(gradient: backgroundGradient),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchBatchmatesFromFirestore(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final batchmates = List<Map<String, dynamic>>.from(
                  snapshot.data!,
                );
                batchmates.sort((a, b) {
                  final aRoll = int.tryParse(a['roll'].toString());
                  final bRoll = int.tryParse(b['roll'].toString());
                  if (aRoll != null && bRoll != null) {
                    return aRoll.compareTo(bRoll);
                  } else {
                    return a['roll'].toString().compareTo(b['roll'].toString());
                  }
                });

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
                            return BatchmateCard(
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
                        child: BatchmateCard(
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
