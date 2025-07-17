import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:uni_connect/features/navigation/side_navigation.dart';
import 'package:uni_connect/features/todo/todo_task.dart';

import 'package:uni_connect/utils/section_title.dart';
import 'package:uni_connect/widgets/monthly_task_completion_graph.dart';
import 'package:uni_connect/widgets/cgpa_chart.dart';
import 'package:uni_connect/widgets/ct_marks_histogram.dart';
import 'package:uni_connect/widgets/ct_marks_details.dart';
import 'package:uni_connect/widgets/ct_comparison_chart.dart';
import 'package:uni_connect/widgets/cgpa_position_box.dart';
import 'package:uni_connect/widgets/full_cgpa_ranking_chart.dart';
import 'package:uni_connect/widgets/cgpa_pie_chart.dart';
import 'package:uni_connect/widgets/ct_comparison_summary.dart';

import 'package:uni_connect/utils/ct_comparison_entries.dart';
import 'package:uni_connect/utils/cgpa_ranking.dart';
import 'package:uni_connect/utils/user_cgpa_position.dart';

import 'package:hive/hive.dart';

import 'package:uni_connect/firebase/firestore/database.dart';

const String userCtMarksBox = 'userCtMarksBox';
const String batchAverageCtMarksBox = 'batchCtAverageBox';
const String userCtMarksKey = 'user';
const String batchCtMarksKey = 'average';
const String batchmatesCgpaBox = 'batchmatesCgpaBox';
const String batchmatesCgpaKey = 'cgpa';

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
    loadCachedBatchmatesCgpa().then((cached) {
      if (cached != null) {
        setState(() {
          batchmatesCgpaData = cached;
        });
      }
    });

    fetchBatchmatesFromFirestore().then((data) {
      final filtered = filterActiveBatchmates(data);
      final formatted = formatBatchAverage(
        calculateBatchAverageCtMarks(filtered),
      );
      print("📤 Saving fresh CT avg from Firestore...");
      cacheBatchAverageCtMarks(formatted);
      cacheBatchmatesCgpa(filtered);

      setState(() {
        batchmatesCgpaData = filtered;
        ctMarksAverageData = formatted;
      });
    });

    // (other initState logic unchanged)
    loadUserProfile().then((data) {
      setState(() {
        userData = data;
      });
      loadCtMarks();
    });

    // Load CT averages from cache
    loadCachedBatchCtMarks().then((cached) {
      if (cached != null) {
        setState(() {
          ctMarksAverageData = cached;
        });
      }
    });
  }

  // Function to save batchmates CGPA data to Hive
  Future<void> cacheBatchmatesCgpa(List<Map<String, dynamic>> data) async {
    final box = await Hive.openBox(batchmatesCgpaBox);
    // Since Hive supports primitives, save as List<Map> (converted using .toList())
    await box.put(batchmatesCgpaKey, data);
  }

  // Function to load batchmates CGPA data from Hive
  Future<List<Map<String, dynamic>>?> loadCachedBatchmatesCgpa() async {
    try {
      final box = await Hive.openBox(batchmatesCgpaBox);
      final raw = box.get(batchmatesCgpaKey);

      if (raw is List) {
        // Convert each entry to Map<String, dynamic>
        return raw.whereType<Map>().map<Map<String, dynamic>>((entry) {
          return Map<String, dynamic>.from(
            entry.map((k, v) => MapEntry('$k', v)),
          );
        }).toList();
      }
      return null;
    } catch (e) {
      print('Error loading batchmatesCgpa from Hive: $e');
      return null;
    }
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
        body: RefreshIndicator(
          color: Colors.cyanAccent,
          backgroundColor: const Color(0xFF0E0E2C),
          onRefresh: () async {
            final user = await reloadUserProfile();
            final batchmates = await reloadBatchmates();
            final parsed = parseCtMarksFromProfile(user);
            await cacheUserCtMarks(parsed);

            final filtered = filterActiveBatchmates(batchmates);
            await cacheBatchmatesCgpa(filtered);
            await cacheBatchAverageCtMarks(
              formatBatchAverage(calculateBatchAverageCtMarks(filtered)),
            );

            setState(() {
              userData = user;
              ctMarksData = parseCtMarksFromProfile(user);
              batchmatesCgpaData = filtered;
            });

            await loadCtMarksAverage();
          },
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 30,
                ),
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
                    const SectionTitle("Monthly Task Completion"),
                    ValueListenableBuilder(
                      valueListenable: Hive.box<TodoTask>(
                        'todoBox',
                      ).listenable(),
                      builder: (context, Box<TodoTask> box, _) {
                        final taskStats = getCompletionStatsLast30Days();
                        return MonthlyTaskCompletionGraph(taskStats: taskStats);
                      },
                    ),
                    if (userData != null) ...[
                      const SectionTitle("CGPA Progress"),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: CgpaChart(cgpaList: userData!['cgpa_list']),
                      ),
                      const SizedBox(height: 30),
                    ],
                    const SectionTitle("CT Marks Histogram"),
                    ctMarksData == null
                        ? const Center(child: CircularProgressIndicator())
                        : CtMarksHistogram(data: ctMarksData!),
                    const SizedBox(height: 24),
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
                      CtComparisonSummary(
                        entries: getCtComparisonEntries(
                          ctMarksData!,
                          ctMarksAverageData!,
                        ),
                      ),
                    ],
                    if (ctMarksData != null) ...[
                      const SectionTitle("CT Marks Details"),
                      CtMarksDetails(data: ctMarksData!),
                    ],
                    const SizedBox(height: 40),
                    if (batchmatesCgpaData != null && userData != null) ...[
                      const SectionTitle("Your CGPA Position in Batch"),
                      CgpaPositionBox(
                        ranking: getCgpaRanking(batchmatesCgpaData!),
                        userRoll: userData!['roll'],
                        buildFullCgpaRankingChart:
                            (ranking, userRoll, context) =>
                                FullCgpaRankingChart(
                                  ranking: ranking,
                                  userRoll: userRoll,
                                ),
                      ),
                      const SectionTitle("CGPA Distribution (All Batchmates)"),
                      CgpaPieChart(
                        ranking: getCgpaRanking(batchmatesCgpaData!),
                        userRoll: userData!['roll'],
                      ),
                      Builder(
                        builder: (context) {
                          final ranking = getCgpaRanking(batchmatesCgpaData!);
                          final userRoll = userData!['roll'];
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
      ),
    );
  }

  Future<void> loadCtMarks() async {
    // First try loading from cache
    final cached = await loadCachedUserCtMarks();
    if (cached != null) {
      setState(() {
        ctMarksData = cached;
      });
      return;
    }

    // If no cache, parse and then cache
    final profile = await loadUserProfile();
    final parsed = parseCtMarksFromProfile(profile);
    await cacheUserCtMarks(parsed);
    setState(() {
      ctMarksData = parsed;
    });
  }

  Future<void> loadCtMarksAverage() async {
    if (batchmatesCgpaData == null) return;

    final averages = calculateBatchAverageCtMarks(batchmatesCgpaData!);
    final formatted = formatBatchAverage(averages);

    await cacheBatchAverageCtMarks(formatted);

    setState(() {
      ctMarksAverageData = formatted;
    });
  }

  Map<String, dynamic> parseCtMarksFromProfile(
    Map<String, dynamic>? userProfile,
  ) {
    final ctMarksRaw = userProfile?['ct_marks'] as Map<String, dynamic>? ?? {};
    final Map<String, List<List<num>>> courses = {};

    for (final entry in ctMarksRaw.entries) {
      final key = entry.key;
      final value = entry.value;
      final match = RegExp(r'^(.+)_CT(\d+)_(\d+)$').firstMatch(key);

      if (match == null) continue;

      final courseName = match.group(1)!;
      final ctNumber = int.parse(match.group(2)!);
      final totalMark = num.parse(match.group(3)!);

      final obtained = (value as List).isNotEmpty ? value[0] as num : 0;

      if (!courses.containsKey(courseName)) {
        courses[courseName] = [];
      }
      while (courses[courseName]!.length < ctNumber) {
        courses[courseName]!.add([0, totalMark]);
      }
      courses[courseName]![ctNumber - 1] = [obtained, totalMark];
    }

    return {'courses': courses};
  }

  List<double> calculateBatchAverageCgpa(
    List<Map<String, dynamic>> batchmatesCgpaData,
  ) {
    if (batchmatesCgpaData.isEmpty) return [];
    final int semesters = batchmatesCgpaData.first['cgpa_list']?.length ?? 0;
    List<double> averages = List.filled(semesters, 0.0);
    List<int> counts = List.filled(semesters, 0);

    for (var student in batchmatesCgpaData) {
      final cgpas = List<double>.from(student['cgpa_list'] ?? []);
      for (int i = 0; i < cgpas.length; i++) {
        averages[i] += cgpas[i];
        counts[i]++;
      }
    }
    for (int i = 0; i < averages.length; i++) {
      averages[i] = counts[i] > 0 ? averages[i] / counts[i] : 0.0;
    }
    return averages;
  }

  List<Map<String, dynamic>> filterActiveBatchmates(
    List<Map<String, dynamic>> batchmates,
  ) {
    return batchmates.where((bm) => bm['status'] == 'active').toList();
  }

  Map<String, double> calculateBatchAverageCtMarks(
    List<Map<String, dynamic>> batchmates,
  ) {
    final Map<String, double> sums = {};
    final Map<String, int> counts = {};

    for (var student in batchmates) {
      final ctMarks = student['ct_marks'] as Map<String, dynamic>? ?? {};
      for (final entry in ctMarks.entries) {
        final String key = entry.key;
        final List marks = entry.value as List;
        if (marks.isNotEmpty && marks.length == 1 && marks[0] is num) {
          sums[key] = (sums[key] ?? 0) + (marks[0] as num).toDouble();
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }

    final Map<String, double> averages = {};
    for (final key in sums.keys) {
      averages[key] = sums[key]! / counts[key]!;
    }
    return averages;
  }

  Map<String, dynamic> formatBatchAverage(Map<String, double> averagesMap) {
    final Map<String, List<List<num>>> courses = {};
    final regExp = RegExp(r'^(.+)_CT(\d+)_(\d+)$');

    for (final entry in averagesMap.entries) {
      final match = regExp.firstMatch(entry.key);
      if (match == null) continue;

      final course = match.group(1)!;
      final ctNum = int.parse(match.group(2)!);
      final total = int.parse(match.group(3)!);

      courses.putIfAbsent(course, () => []);
      while (courses[course]!.length < ctNum) {
        courses[course]!.add([0, total]);
      }
      courses[course]![ctNum - 1] = [entry.value, total];
    }

    return {'courses': courses};
  }

  List<int> getCompletionStatsLast30Days() {
    final box = Hive.box<TodoTask>('todoBox');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
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

  Future<void> cacheUserCtMarks(Map<String, dynamic> formattedCtMarks) async {
    final box = await Hive.openBox(userCtMarksBox);
    await box.put(userCtMarksKey, formattedCtMarks);
  }

  Future<void> cacheBatchAverageCtMarks(
    Map<String, dynamic> formattedCtMarks,
  ) async {
    try {
      print("🟡 Attempting to save batch CT average to Hive...");
      final box = await Hive.openBox(batchAverageCtMarksBox);

      await box.put(batchCtMarksKey, formattedCtMarks);
      print("✅ Saved batch CT average to Hive:");
      print(formattedCtMarks);
    } catch (e) {
      print("❌ Error saving batch CT average: $e");
    }
  }

  Future<Map<String, dynamic>?> loadCachedUserCtMarks() async {
    print('Opening Hive box for user Ct marks...');
    final box = await Hive.openBox(userCtMarksBox);
    print('Hive box opened.');

    final raw = box.get(userCtMarksKey);
    print('Raw data from Hive: $raw');

    if (raw is Map && raw.containsKey('courses')) {
      final rawCourses = raw['courses'];
      if (rawCourses is Map) {
        final cleanedCourses = <String, List<List<num>>>{};
        for (var entry in rawCourses.entries) {
          final course = entry.key.toString();
          final rawList = entry.value;
          if (rawList is List) {
            final parsedList = rawList.map<List<num>>((e) {
              if (e is List && e.length == 2) {
                return [num.parse(e[0].toString()), num.parse(e[1].toString())];
              }
              return [0, 0];
            }).toList();
            cleanedCourses[course] = parsedList;
          }
        }
        print('Parsed cleanedCourses: $cleanedCourses');
        return {'courses': cleanedCourses};
      }
    }

    print('No cached CT marks found or invalid format');
    return null;
  }

  Future<Map<String, dynamic>?> loadCachedBatchCtMarks() async {
    try {
      final box = await Hive.openBox(batchAverageCtMarksBox);
      final raw = box.get(batchCtMarksKey);
      print("⏬ Raw from Hive: $raw");

      if (raw is Map && raw.containsKey('courses')) {
        final rawCourses = raw['courses'];
        if (rawCourses is Map) {
          final cleanedCourses = <String, List<List<num>>>{};

          for (var entry in rawCourses.entries) {
            final course = entry.key.toString();
            final rawList = entry.value;
            if (rawList is List) {
              final parsedList = rawList.map<List<num>>((e) {
                if (e is List && e.length == 2) {
                  return [
                    num.parse(e[0].toString()),
                    num.parse(e[1].toString()),
                  ];
                }
                return [0, 0];
              }).toList();
              cleanedCourses[course] = parsedList;
            }
          }

          print("✅ Cleaned loaded CT average: $cleanedCourses");
          return {'courses': cleanedCourses};
        }
      }

      print("❌ Failed to parse CT average from Hive.");
      return null;
    } catch (e) {
      print("❌ Error loading batch CT average: $e");
      return null;
    }
  }
}
