import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:uni_connect/firebase/firestore/database.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  late Future<List<Map<String, dynamic>>> _examsFuture;

  @override
  void initState() {
    super.initState();
    _examsFuture = fetchExamsFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E2C),
      appBar: AppBar(
        elevation: 10,
        backgroundColor: const Color(0xFF1A1A2E),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 255, 255, 255),
        ),
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: [
                Color.fromARGB(255, 255, 255, 255),
                Color.fromARGB(255, 255, 255, 255),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: const Text(
            'Exams',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: Colors.cyanAccent,
        backgroundColor: const Color(0xFF0E0E2C),
        onRefresh: () async {
          final freshExams =
              await reloadExams(); // replaces cache from Firestore
          setState(() {
            _examsFuture = Future.value(
              freshExams,
            ); // FutureBuilder sees new data
          });
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _examsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              );
            }
            final exams = snapshot.data!;
            if (exams.isEmpty) {
              return Center(
                child: Text(
                  "No upcoming exams.",
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              );
            }
            final DateTime now = DateTime.now();
            exams.sort((a, b) {
              DateTime dateA, dateB;
              try {
                dateA = DateTime.parse(a['data']['date'] ?? '');
              } catch (_) {
                dateA = DateTime(9999); // far future if parse fails
              }
              try {
                dateB = DateTime.parse(b['data']['date'] ?? '');
              } catch (_) {
                dateB = DateTime(9999);
              }
              final int diffA = dateA
                  .difference(DateTime(now.year, now.month, now.day))
                  .inDays;
              final int diffB = dateB
                  .difference(DateTime(now.year, now.month, now.day))
                  .inDays;

              // Upcoming exams (diff >= 0) come first (nearest first).
              // Passed exams (diff < 0) go to bottom (most recently passed first).
              if (diffA < 0 && diffB < 0) {
                return diffB.compareTo(diffA); // More recent (-1) is earlier
              } else if (diffA < 0) {
                return 1; // b comes first (because a is passed)
              } else if (diffB < 0) {
                return -1; // a comes first
              } else {
                return diffA.compareTo(diffB); // Earlier upcoming exam first
              }
            });

            return ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: exams.length,
              itemBuilder: (context, index) {
                final exam = exams[index]['data'] ?? {};

                // Parse the exam date
                final String? dateStr = exam['date'];
                DateTime examDate;
                if (dateStr == null) {
                  examDate = DateTime.now();
                } else {
                  try {
                    examDate = DateTime.parse(dateStr);
                  } catch (e) {
                    examDate = DateTime.now();
                  }
                }
                final DateTime now = DateTime.now();
                final int daysUntil = examDate
                    .difference(DateTime(now.year, now.month, now.day))
                    .inDays;

                // Dynamic color for days left
                Color daysColor;
                if (daysUntil < 0) {
                  daysColor = Colors.grey;
                } else if (daysUntil <= 1) {
                  daysColor = Colors.redAccent;
                } else if (daysUntil <= 3) {
                  daysColor = Colors.orange;
                } else {
                  daysColor = Colors.greenAccent;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.18),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam['title'] ?? "",
                              style: GoogleFonts.poppins(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${exam['date'] ?? ''}${exam['time'] != null ? ' • ${exam['time']}' : ''}",
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: daysColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          daysUntil < 0
                              ? 'Passed'
                              : daysUntil == 0
                              ? 'Today'
                              : '$daysUntil days left',
                          style: GoogleFonts.poppins(
                            color: Colors.black.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
