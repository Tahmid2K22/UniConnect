import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uni_connect/features/navigation/side_navigation.dart';
import 'package:uni_connect/features/todo/todo_task.dart';
import 'avg_cgpa_animation.dart';

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
        body: Container(
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
                  _sectionTitle("Monthly Task Completion"),
                  ValueListenableBuilder(
                    valueListenable: Hive.box<TodoTask>('todoBox').listenable(),
                    builder: (context, Box<TodoTask> box, _) {
                      final taskStats = getCompletionStatsLast30Days();
                      return Container(
                        height: 120,
                        margin: const EdgeInsets.only(bottom: 30),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: _glassCard(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: taskStats.map((count) {
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                height: 20.0 * count,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.cyan, Colors.blueAccent],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),

                  // CGPA Chart
                  if (userData != null) ...[
                    _sectionTitle("CGPA Progress"),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _buildCgpaChart(userData!['cgpa_list']),
                    ),
                    const SizedBox(height: 30),
                  ],

                  // CT Marks Histogram
                  _sectionTitle("CT Marks Histogram"),
                  ctMarksData == null
                      ? const Center(child: CircularProgressIndicator())
                      : _buildCtMarksHistogram(ctMarksData!),
                  const SizedBox(height: 24),

                  if (ctMarksData != null && ctMarksAverageData != null) ...[
                    _sectionTitle("Your CT Marks vs. Batch Average"),
                    _buildCtComparisonChart(ctMarksData!, ctMarksAverageData!),
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

                    _buildCtComparisonSummary(
                      getCtComparisonEntries(ctMarksData!, ctMarksAverageData!),
                    ),
                  ],

                  // CT Marks Details
                  if (ctMarksData != null) ...[
                    _sectionTitle("CT Marks Details"),
                    _buildCtMarksDetails(ctMarksData!),
                  ],

                  const SizedBox(height: 40),

                  if (batchmatesCgpaData != null && userData != null) ...[
                    _sectionTitle("Your CGPA Position in Batch"),
                    buildCgpaPositionBox(
                      getCgpaRanking(batchmatesCgpaData!),
                      userData!['roll_number'],
                      context,
                    ),
                    _sectionTitle("CGPA Distribution (All Batchmates)"),
                    buildCgpaPieChart(
                      getCgpaRanking(batchmatesCgpaData!),
                      userData!['roll_number'],
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
                        if (userPosition == null) return SizedBox.shrink();
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

  // 30-day completion stats (reuse from front page)
  List<int> getCompletionStatsLast30Days() {
    final box = Hive.box<TodoTask>('todoBox');
    final now = DateTime.now();
    List<int> stats = List.filled(30, 0);

    for (var task in box.values) {
      if (task.completedAt != null) {
        final daysAgo = now.difference(task.completedAt!).inDays;
        if (daysAgo >= 0 && daysAgo < 30) {
          stats[29 - daysAgo] += 1; // 0 = 30 days ago, 29 = today
        }
      }
    }
    return stats;
  }

  // CGPA Chart (reuse from user profile)
  Widget _buildCgpaChart(List cgpaList) {
    final double avgCgpa = cgpaList.isNotEmpty
        ? cgpaList.reduce((a, b) => a + b) / cgpaList.length
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 0.5,
                    getTitlesWidget: (value, meta) {
                      if (value % 0.5 == 0) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 == 0 &&
                          value >= 0 &&
                          value < cgpaList.length) {
                        return Text(
                          'S${value.toInt() + 1}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              minY: 2.0,
              maxY: 4.0,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    cgpaList.length,
                    (i) =>
                        FlSpot(i.toDouble(), (cgpaList[i] as num).toDouble()),
                  ),
                  isCurved: true,
                  color: Colors.cyanAccent,
                  barWidth: 4,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedGradientCGPANumber(avgCgpa: avgCgpa),
      ],
    );
  }

  // CT Marks Histogram

  Widget _buildCtMarksHistogram(Map<String, dynamic> data) {
    final courses = data['courses'] as Map<String, dynamic>;
    final List<_CtMarkEntry> entries = [];
    final List<Color> courseColors = [
      Colors.cyanAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.redAccent,
    ];

    int colorIndex = 0;
    final Map<String, Color> courseColorMap = {};

    courses.forEach((course, exams) {
      courseColorMap[course] = courseColors[colorIndex % courseColors.length];
      colorIndex++;
      for (int i = 0; i < (exams as List).length; i++) {
        final pair = exams[i] as List;
        final percent = (pair[0] / pair[1]) * 100;
        entries.add(
          _CtMarkEntry(
            course: course,
            exam: i + 1,
            obtained: pair[0],
            total: pair[1],
            percent: percent,
          ),
        );
      }
    });

    // Sort by course, then exam
    entries.sort((a, b) {
      int cmp = a.course.compareTo(b.course);
      if (cmp != 0) return cmp;
      return a.exam.compareTo(b.exam);
    });

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              minY: 0,
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 20,
                    getTitlesWidget: (value, meta) {
                      if (value % 20 == 0) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false, // No X-axis labels
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              barGroups: List.generate(entries.length, (i) {
                final entry = entries[i];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: entry.percent,
                      color: courseColorMap[entry.course],
                      width: 16,
                      borderRadius: BorderRadius.circular(6),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 100,
                        color: Colors.white.withAlpha(30),
                      ),
                    ),
                  ],
                );
              }),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) =>
                      Colors.black.withValues(alpha: 0.92),
                  tooltipBorderRadius: BorderRadius.circular(18),
                  tooltipMargin: 12,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final entry = entries[group.x.toInt()];
                    return BarTooltipItem(
                      '${entry.course} CT${entry.exam}\n',
                      GoogleFonts.poppins(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      children: [
                        TextSpan(
                          text: '${entry.obtained}/${entry.total}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 30, // Big and bold for visibility
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Legend
        Wrap(
          spacing: 12,
          children: courseColorMap.entries.map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: e.value,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  e.key,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // CT Marks Details Table
  Widget _buildCtMarksDetails(Map<String, dynamic> data) {
    final courses = data['courses'] as Map<String, dynamic>;
    final List<_CtMarkEntry> entries = [];

    courses.forEach((course, exams) {
      for (int i = 0; i < (exams as List).length; i++) {
        final pair = exams[i] as List;
        final percent = (pair[0] / pair[1]) * 100;
        entries.add(
          _CtMarkEntry(
            course: course,
            exam: i + 1,
            obtained: pair[0],
            total: pair[1],
            percent: percent,
          ),
        );
      }
    });

    // Sort by course, then exam
    entries.sort((a, b) {
      int cmp = a.course.compareTo(b.course);
      if (cmp != 0) return cmp;
      return a.exam.compareTo(b.exam);
    });

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: _glassCard(),
      child: Column(
        children: [
          Row(
            children: [
              _cell("Course", bold: true),
              _cell("CT", bold: true),
              _cell("Score", bold: true),
              _cell("Percent", bold: true),
            ],
          ),
          const Divider(color: Colors.white24, thickness: 0.7),
          ...entries.map(
            (e) => Row(
              children: [
                _cell(e.course),
                _cell("CT${e.exam}"),
                _cell("${e.obtained}/${e.total}"),
                _cell("${e.percent.toStringAsFixed(1)}%"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool bold = false}) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCtComparisonChart(
    Map<String, dynamic> userCtData,
    Map<String, dynamic> avgCtData,
  ) {
    final entries = getCtComparisonEntries(userCtData, avgCtData);
    final xLabels = entries.map((e) => '${e.course} CT${e.ctNumber}').toList();

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          maxY: 100,
          minY: 0,
          groupsSpace: 16,
          barGroups: List.generate(entries.length, (i) {
            final entry = entries[i];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entry.userPercent,
                  color: Colors.cyanAccent,
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: entry.avgPercent,
                  color: Colors.blueAccent,
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  if (value % 20 == 0) {
                    return Text(
                      '${value.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < xLabels.length) {
                    return RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        xLabels[value.toInt()],
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: true),
        ),
      ),
    );
  }

  Widget _buildCtComparisonSummary(List<_CtComparisonEntry> entries) {
    final userAvg =
        entries.map((e) => e.userPercent).reduce((a, b) => a + b) /
        entries.length;
    final avgAvg =
        entries.map((e) => e.avgPercent).reduce((a, b) => a + b) /
        entries.length;
    final diff = userAvg - avgAvg;
    final diffText = diff.abs().toStringAsFixed(1);
    final isBetter = diff > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        isBetter
            ? 'You scored $diffText% better than the batch average across all CTs.'
            : 'You scored $diffText% below the batch average across all CTs.',
        style: GoogleFonts.poppins(
          color: isBetter ? Colors.greenAccent : Colors.redAccent,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  BoxDecoration _glassCard() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(2, 4),
        ),
      ],
    );
  }

  List<_CtComparisonEntry> getCtComparisonEntries(
    Map<String, dynamic> userCtData,
    Map<String, dynamic> avgCtData,
  ) {
    final List<_CtComparisonEntry> entries = [];
    final userCourses = userCtData['courses'] as Map<String, dynamic>;
    final avgCourses = avgCtData['courses'] as Map<String, dynamic>;

    for (final course in userCourses.keys) {
      final userExams = userCourses[course] as List;
      final avgExams = avgCourses[course] as List;
      for (int i = 0; i < userExams.length; i++) {
        final userPair = userExams[i] as List;
        final avgPair = avgExams[i] as List;
        final userPercent = (userPair[0] / userPair[1]) * 100;
        final avgPercent = (avgPair[0] / avgPair[1]) * 100;
        entries.add(
          _CtComparisonEntry(
            course: course,
            ctNumber: i + 1,
            userPercent: userPercent,
            avgPercent: avgPercent,
          ),
        );
      }
    }
    return entries;
  }

  List<BatchmateCgpaEntry> getCgpaRanking(List<Map<String, dynamic>> data) {
    return data
        .where((e) => e['status'] == 'active')
        .map((e) {
          final cgpaList = (e['cgpa_list'] as List?)
              ?.map((v) => (v as num).toDouble())
              .toList();
          final avg = cgpaList != null && cgpaList.isNotEmpty
              ? cgpaList.reduce((a, b) => a + b) / cgpaList.length
              : null;
          return BatchmateCgpaEntry(
            roll: e['roll'],
            name: e['name'],
            status: e['status'],
            cgpaList: cgpaList,
            avgCgpa: avg,
          );
        })
        .where((e) => e.avgCgpa != null)
        .toList()
      ..sort((a, b) => b.avgCgpa!.compareTo(a.avgCgpa!));
  }

  int? getUserCgpaPosition(List<BatchmateCgpaEntry> ranking, String userRoll) {
    final idx = ranking.indexWhere((e) => e.roll == userRoll);
    return idx >= 0 ? idx + 1 : null;
  }

  // --- CGPA Position Box ---
  Widget buildCgpaPositionBox(
    List<BatchmateCgpaEntry> ranking,
    String userRoll,
    BuildContext context,
  ) {
    final idx = ranking.indexWhere((e) => e.roll == userRoll);
    if (idx == -1) return Container();

    BatchmateCgpaEntry? above = idx > 0 ? ranking[idx - 1] : null;
    BatchmateCgpaEntry user = ranking[idx];
    BatchmateCgpaEntry? below = idx < ranking.length - 1
        ? ranking[idx + 1]
        : null;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: buildFullCgpaRankingChart(ranking, userRoll),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (above != null) _cgpaPersonTile(above, highlight: false),
            _cgpaPersonTile(user, highlight: true),
            if (below != null) _cgpaPersonTile(below, highlight: false),
          ],
        ),
      ),
    );
  }

  Widget _cgpaPersonTile(BatchmateCgpaEntry entry, {required bool highlight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            color: highlight ? Colors.cyanAccent : Colors.white54,
            size: highlight ? 30 : 24,
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.name} (${entry.roll})',
            style: GoogleFonts.poppins(
              color: highlight ? Colors.cyanAccent : Colors.white70,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              fontSize: highlight ? 18 : 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            entry.avgCgpa!.toStringAsFixed(2),
            style: GoogleFonts.poppins(
              color: highlight ? Colors.cyanAccent : Colors.white70,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              fontSize: highlight ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  // --- Full CGPA Ranking Chart Dialog ---
  Widget buildFullCgpaRankingChart(
    List<BatchmateCgpaEntry> ranking,
    String userRoll,
  ) {
    // 1. Sort by roll ascending:
    final sorted = [...ranking]..sort((a, b) => a.roll.compareTo(b.roll));
    // 2. Find user index in the sorted list:
    final userIdx = sorted.indexWhere((e) => e.roll == userRoll);
    // 3. Compute batch average using the sorted list:
    final avgAll =
        sorted.map((e) => e.avgCgpa!).fold<double>(0, (sum, x) => sum + x) /
        sorted.length;
    final userCgpa = userIdx >= 0 ? sorted[userIdx].avgCgpa! : null;
    final diff = userCgpa != null ? userCgpa - avgAll : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "CGPA by Roll Number",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      sorted.length,
                      (i) => FlSpot(i.toDouble(), sorted[i].avgCgpa!),
                    ),
                    isCurved: true,
                    color: Colors.cyanAccent,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, bar) => spot.x == userIdx,
                      getDotPainter: (spot, percent, bar, idx) =>
                          FlDotCirclePainter(
                            radius: 7,
                            color: Colors.blueAccent,
                            strokeWidth: 4,
                            strokeColor: Colors.cyanAccent,
                          ),
                    ),
                  ),
                ],
                minY: 2.0,
                maxY: 4.0,
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, meta) => Text(
                        v.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "Batch Average CGPA: ${avgAll.toStringAsFixed(2)}",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
          if (userCgpa != null)
            Text(
              diff >= 0
                  ? "You are +${diff.toStringAsFixed(2)} above average"
                  : "You are ${diff.toStringAsFixed(2)} below average",
              style: GoogleFonts.poppins(
                color: diff >= 0 ? Colors.greenAccent : Colors.redAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  // --- CGPA Distribution Pie Chart ---
  Widget buildCgpaPieChart(List<BatchmateCgpaEntry> ranking, String userRoll) {
    final bins = [
      {'label': '<2.5', 'color': Colors.redAccent, 'count': 0},
      {'label': '2.5–3.0', 'color': Colors.orangeAccent, 'count': 0},
      {'label': '3.0–3.5', 'color': Colors.blueAccent, 'count': 0},
      {'label': '3.5–4.0', 'color': Colors.cyanAccent, 'count': 0},
    ];
    double? userCgpa;
    for (final e in ranking) {
      final cgpa = e.avgCgpa!;
      if (e.roll == userRoll) userCgpa = cgpa;
      if (cgpa < 2.5) {
        bins[0]['count'] = (bins[0]['count'] as int) + 1;
      } else if (cgpa < 3.0) {
        bins[1]['count'] = (bins[1]['count'] as int) + 1;
      } else if (cgpa < 3.5) {
        bins[2]['count'] = (bins[2]['count'] as int) + 1;
      } else {
        bins[3]['count'] = (bins[3]['count'] as int) + 1;
      }
    }

    int userBin = userCgpa == null
        ? -1
        : userCgpa < 2.5
        ? 0
        : userCgpa < 3.0
        ? 1
        : userCgpa < 3.5
        ? 2
        : 3;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: List.generate(bins.length, (i) {
                final isUser = i == userBin;
                return PieChartSectionData(
                  color: bins[i]['color'] as Color,
                  value: (bins[i]['count'] as int).toDouble(),
                  title: '${bins[i]['count']}',
                  radius: isUser ? 75 : 55,
                  titleStyle: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
                    fontSize: isUser ? 20 : 14,
                  ),
                  badgeWidget: isUser
                      ? Icon(Icons.person, color: Colors.white, size: 28)
                      : null,
                  badgePositionPercentageOffset: 1.2,
                );
              }),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 18,
          children: List.generate(bins.length, (i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: bins[i]['color'] as Color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  bins[i]['label'] as String,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            );
          }),
        ),
        if (userBin >= 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "You are in the ${bins[userBin]['label']} group.",
              style: GoogleFonts.poppins(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
      ],
    );
  }
}

// Helper class for CT marks
class _CtMarkEntry {
  final String course;
  final int exam;
  final num obtained;
  final num total;
  final double percent;
  _CtMarkEntry({
    required this.course,
    required this.exam,
    required this.obtained,
    required this.total,
    required this.percent,
  });
}

class _CtComparisonEntry {
  final String course;
  final int ctNumber;
  final double userPercent;
  final double avgPercent;

  _CtComparisonEntry({
    required this.course,
    required this.ctNumber,
    required this.userPercent,
    required this.avgPercent,
  });
}

class BatchmateCgpaEntry {
  final String roll;
  final String name;
  final String status;
  final List<double>? cgpaList;
  final double? avgCgpa;

  BatchmateCgpaEntry({
    required this.roll,
    required this.name,
    required this.status,
    this.cgpaList,
    this.avgCgpa,
  });
}
