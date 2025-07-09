import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uni_connect/features/navigation/side_navigation.dart';
import 'package:uni_connect/features/todo/todo_task.dart';
import 'package:uni_connect/widgets/section_title.dart';
import 'package:uni_connect/widgets/monthly_task_completion_graph.dart';
import 'package:uni_connect/widgets/cgpa_chart.dart';
import 'package:uni_connect/widgets/ct_marks_histogram.dart';
import 'package:uni_connect/widgets/ct_marks_details.dart';
import 'package:uni_connect/widgets/ct_comparison_chart.dart';
import 'package:uni_connect/widgets/cgpa_position_box.dart';
import 'package:uni_connect/widgets/full_cgpa_ranking_chart.dart';
import 'package:uni_connect/widgets/cgpa_pie_chart.dart';
import 'package:uni_connect/utils/ct_comparison_entries.dart';
import 'package:uni_connect/widgets/ct_comparison_summary.dart';
import 'package:uni_connect/utils/cgpa_ranking.dart';
import 'package:uni_connect/utils/user_cgpa_position.dart';

class UserAnalyticsPage extends StatefulWidget {
  const UserAnalyticsPage({super.key});

  @override
  State<UserAnalyticsPage> createState() => _UserAnalyticsPageState();
}

class _UserAnalyticsPageState extends State<UserAnalyticsPage> {
  Map<String, dynamic>? ctMarksData;
  Map<String, dynamic>? ctMarksAverageData;
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>>? batchmatesCgpaData;

  @override
  void initState() {
    super.initState();
    loadCtMarks();
    loadCtMarksAverage();
    loadProfile();
    loadBatchmatesCgpa();
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx < -10) {
          scaffoldKey.currentState?.openEndDrawer();
        }
      },
      child: Scaffold(
        key: scaffoldKey,
        endDrawer: const SideNavigation(),
        backgroundColor: const Color(0xFF0E0E2C),
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Analytics",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 30-day To-Do Completion Graph
                  const SectionTitle("Monthly Task Completion"),
                  ValueListenableBuilder(
                    valueListenable: Hive.box<TodoTask>('todoBox').listenable(),
                    builder: (context, Box<TodoTask> box, _) {
                      final taskStats = getCompletionStatsLast30Days();
                      return MonthlyTaskCompletionGraph(taskStats: taskStats);
                    },
                  ),

                  // CGPA Chart
                  if (userData != null) ...[
                    const SectionTitle("CGPA Progress"),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: CgpaChart(cgpaList: userData!['cgpa_list']),
                    ),
                    const SizedBox(height: 30),
                  ],

                  // CT Marks Histogram
                  const SectionTitle("CT Marks Histogram"),
                  ctMarksData == null
                      ? const Center(child: CircularProgressIndicator())
                      : CtMarksHistogram(data: ctMarksData!),
                  const SizedBox(height: 24),

                  // CT Comparison Chart and Summary
                  if (ctMarksData != null && ctMarksAverageData != null) ...[
                    const SectionTitle("Your CT Marks vs. Batch Average"),
                    CtComparisonChart(
                      entries: getCtComparisonEntries(
                        ctMarksData!,
                        ctMarksAverageData!,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Sky blue (You)
                          Row(
                            children: [
                              Container(
                                width: 18,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "You",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          // Dark blue (Average)
                          Row(
                            children: [
                              Container(
                                width: 18,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Average",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Summary
                    CtComparisonSummary(
                      entries: getCtComparisonEntries(
                        ctMarksData!,
                        ctMarksAverageData!,
                      ),
                    ),
                  ],

                  // CT Marks Details
                  if (ctMarksData != null) ...[
                    const SectionTitle("CT Marks Details"),
                    CtMarksDetails(data: ctMarksData!),
                  ],

                  const SizedBox(height: 40),

                  // CGPA Position and Distribution
                  if (batchmatesCgpaData != null && userData != null) ...[
                    const SectionTitle("Your CGPA Position in Batch"),
                    CgpaPositionBox(
                      ranking: getCgpaRanking(batchmatesCgpaData!),
                      userRoll: userData!['roll_number'],
                      buildFullCgpaRankingChart: (ranking, userRoll, context) =>
                          FullCgpaRankingChart(
                            ranking: ranking,
                            userRoll: userRoll,
                          ),
                    ),
                    const SectionTitle("CGPA Distribution (All Batchmates)"),
                    CgpaPieChart(
                      ranking: getCgpaRanking(batchmatesCgpaData!),
                      userRoll: userData!['roll_number'],
                    ),
                    Builder(
                      builder: (context) {
                        final ranking = getCgpaRanking(batchmatesCgpaData!);
                        final userRoll = userData!['roll_number'];
                        final userPosition = getUserCgpaPosition(
                          ranking,
                          userRoll,
                        );
                        final total = ranking.length;
                        if (userPosition == null) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            "Your CGPA position: $userPosition out of $total",
                            style: GoogleFonts.poppins(
                              color: const Color.fromARGB(255, 70, 255, 24),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Load Data Start -------------------------------------------------------------------------------------------------------------------

  Future<void> loadCtMarks() async {
    final jsonString = await rootBundle.loadString('assets/ct_marks_demo.json');
    setState(() {
      ctMarksData = json.decode(jsonString);
    });
  }

  Future<void> loadProfile() async {
    final jsonString = await rootBundle.loadString(
      'assets/user_profile_demo.json',
    );
    setState(() {
      userData = json.decode(jsonString);
    });
  }

  Future<void> loadCtMarksAverage() async {
    final jsonString = await rootBundle.loadString(
      'assets/avg_ct_marks_demo.json',
    );
    setState(() {
      ctMarksAverageData = json.decode(jsonString);
    });
  }

  Future<void> loadBatchmatesCgpa() async {
    final jsonString = await rootBundle.loadString(
      'assets/batchmate_cgpa_demo.json',
    );
    setState(() {
      batchmatesCgpaData = List<Map<String, dynamic>>.from(
        json.decode(jsonString),
      );
    });
  }

  // Load Data End -------------------------------------------------------------------------------------------------------------------

  // 30-day completion stats
  List<int> getCompletionStatsLast30Days() {
    final box = Hive.box<TodoTask>('todoBox');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // strip time
    List<int> stats = List.filled(30, 0);

    for (var task in box.values) {
      if (task.completedAt != null) {
        final completedDay = DateTime(
          task.completedAt!.year,
          task.completedAt!.month,
          task.completedAt!.day,
        );
        final daysAgo = today.difference(completedDay).inDays;
        if (daysAgo >= 0 && daysAgo < 30) {
          stats[29 - daysAgo] += 1;
        }
      }
    }
    return stats;
  }
}
