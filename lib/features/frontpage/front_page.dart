import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:uni_connect/firebase/firestore/database.dart';
import 'package:uni_connect/utils/glass_card.dart';

import '../navigation/side_navigation.dart';

import '../routine/collect_data.dart';
import '../todo/todo_task.dart';

import 'package:uni_connect/utils/front_page_utils.dart';
import 'package:uni_connect/models/data_model.dart';

import 'package:uni_connect/widgets/calander_card.dart';
import 'package:uni_connect/widgets/ct_marks_histogram.dart';
import 'package:uni_connect/widgets/ct_marks_details.dart';
import 'package:uni_connect/widgets/load_user_ct_marks.dart';
import 'package:uni_connect/widgets/monthly_task_completion_graph.dart';
import 'package:uni_connect/utils/todo_card.dart';
import 'package:uni_connect/utils/notice_card.dart';
import 'package:uni_connect/widgets/today_task.dart';
import 'package:uni_connect/widgets/top_section.dart';

// Constants (reuse the same box/key as in analytics page)
const String userCtMarksBox = 'userCtMarksBox';
const String userCtMarksKey = 'user';

class FrontPage extends StatefulWidget {
  const FrontPage({super.key});

  @override
  State<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _controller;

  DataModel? nextClass;
  Map<String, dynamic>? userProfile;
  String userRoll = "";

  Map<String, dynamic>? ctMarksData;
  Map<String, dynamic>? upcomingExam;

  String _noticeSummary = "";

  // Cache computed values to avoid recalculating on every build
  List<TodoTask>? _cachedTasks;
  Map<String, int>? _cachedTodayStats;
  List<TodoTask>? _cachedDueSoonTasks;
  List<int>? _cachedCompletionStats;
  List<Map<String, dynamic>>? _cachedNotices;

  @override
  void initState() {
    super.initState();
    _loadUpcomingExam();
    _loadNoticesSummary();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: false);
    _loadProfile();
    _computeCachedValues();
    _loadNotices();
  }

  void _computeCachedValues() {
    _cachedTasks = getAllTasks();
    _cachedTodayStats = getTodayTaskStats(_cachedTasks!);
    _cachedDueSoonTasks = getDueSoonTasks();
    _cachedCompletionStats = getCompletionStatsLast30Days();
  }

  Future<void> _loadNotices() async {
    final notices = await fetchNoticesFromFirestore();
    setState(() {
      _cachedNotices = notices;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use cached values instead of recomputing
    final todayStats =
        _cachedTodayStats ?? {'createdToday': 0, 'completedToday': 0};
    final createdToday = todayStats['createdToday']!;
    final completedToday = todayStats['completedToday']!;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx < -10) {
            scaffoldKey.currentState?.openEndDrawer();
          }
        },
        child: Scaffold(
          key: scaffoldKey,
          endDrawer: const SideNavigation(),
          backgroundColor: const Color.fromARGB(255, 11, 11, 34),
          body: SafeArea(
            child: RefreshIndicator(
              color: Colors.tealAccent[400]!,
              backgroundColor: const Color.fromARGB(255, 11, 11, 34),
              onRefresh: () async {
                final profile = await reloadUserProfile();
                final parsed = parseCtMarksFromProfile(profile);

                await cacheUserCtMarks(parsed);

                // Reload all data in parallel for faster refresh
                await Future.wait([
                  reloadExams(),
                  reloadNotices(),
                  _loadRoutineData(),
                  reloadBatchmates(),
                ]);

                await _loadUpcomingExam();
                await _loadNotices();

                _computeCachedValues();

                setState(() {
                  userProfile = profile;
                  ctMarksData = parsed;
                });
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: TopSection(
                        userName: extractName(userProfile?['name']),
                        nextClassTitle: nextClass != null
                            ? filterClassForUser(
                                    nextClass!.data,
                                    (userProfile?['roll'] ?? '0'),
                                  ) ??
                                  ''
                            : '',
                        nextClassTime: nextClass?.period ?? '',
                        hasNextClass:
                            nextClass != null &&
                            nextClass!.data != 'No classes scheduled',
                        hasNextExam: upcomingExam != null,
                        nextExamTitle: upcomingExam?['data']?['title'] ?? '',
                        nextExamTime: upcomingExam != null
                            ? "${upcomingExam?['data']?['date'] ?? ''} • ${upcomingExam?['data']?['time'] ?? ''}"
                            : '',
                        daysUntilExam: upcomingExam != null
                            ? _daysUntil(upcomingExam?['data']?['date'] ?? '')
                            : null,
                        noticesText: _noticeSummary,
                        onTapNextClass: () =>
                            Navigator.pushNamed(context, '/routine'),
                        onTapNextExam: () =>
                            Navigator.pushNamed(context, '/exam'),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25.0,
                        vertical: 10,
                      ),
                      child: const AcademicCalendarWidget(),
                    ),
                  ),

                  const _SectionHeader(title: "Notices"),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 19.0),
                      child: _cachedNotices == null
                          ? const SizedBox(
                              height: 110,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.tealAccent,
                                ),
                              ),
                            )
                          : _cachedNotices!.isEmpty
                          ? const SizedBox(
                              height: 110,
                              child: Center(
                                child: Text(
                                  "No notices found.",
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/notices'),
                              child: SizedBox(
                                height: 110,
                                child: ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.transparent,
                                        Colors.white,
                                        Colors.white,
                                        Colors.transparent,
                                      ],
                                      stops: [0.0, 0.02, 0.98, 1.0],
                                    ).createShader(bounds);
                                  },
                                  blendMode: BlendMode.dstIn,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: _cachedNotices!.map((notice) {
                                      final data = notice['data'] ?? {};
                                      return NoticeCard(
                                        title: data['title'] ?? "",
                                        desc: data['desc'] ?? "",
                                        time: data['time'] ?? "",
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),

                  // Todo Section (only show if tasks exist)
                  if ((_cachedDueSoonTasks ?? []).isNotEmpty) ...[
                    const _SectionHeader(title: "Todo"),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 19.0),
                        child: SizedBox(
                          height: 110,
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.transparent, // left fade
                                  Colors.white,
                                  Colors.white,
                                  Colors.transparent, // right fade
                                ],
                                stops: [0.0, 0.02, 0.98, 1.0],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.dstIn,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: (_cachedDueSoonTasks ?? <TodoTask>[])
                                  .map<Widget>((task) {
                                    return GestureDetector(
                                      onTap: () =>
                                          Navigator.pushNamed(
                                            context,
                                            '/todo',
                                          ).then((_) {
                                            _computeCachedValues();
                                            setState(() {});
                                          }),
                                      child: TodoCard(
                                        title: task.title,
                                        due: task.dueDate != null
                                            ? task.dueDate!
                                                  .toLocal()
                                                  .toString()
                                                  .split(' ')[0]
                                            : "No due date",
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Task Analytics (only show if non-empty)
                  if (!(_cachedCompletionStats ?? []).every((c) => c == 0)) ...[
                    const _SectionHeader(title: "Task Analytics"),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 23.0,
                          vertical: 0,
                        ),
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/analytics'),
                          child: SizedBox(
                            width: double.infinity,
                            height: 180,
                            child: MonthlyTaskCompletionGraph(
                              taskStats: _cachedCompletionStats ?? [],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Progress Summary (only show if at least one task created today)
                  if (createdToday > 0) ...[
                    const _SectionHeader(title: "Progress Summary"),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/todo').then((_) {
                                _computeCachedValues();
                                setState(() {}); // Refresh home on return
                              }),
                          child: GlassCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    color: Colors.amber.shade300,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Today's Progress",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$completedToday of $createdToday tasks completed today",
                                          style: GoogleFonts.poppins(
                                            color: Colors.tealAccent[400]!,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          completedToday == createdToday
                                              ? "All done for today! 🎉"
                                              : (completedToday > 0
                                                    ? "Great progress, keep going!"
                                                    : "Let's get started!"),
                                          style: GoogleFonts.poppins(
                                            color: Colors.white54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  ],

                  // CT Marks (only show if data is non-null & not empty)
                  if (ctMarksData != null &&
                      (ctMarksData!['courses'] as Map).isNotEmpty) ...[
                    const _SectionHeader(title: "CT Marks Histogram"),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: GlassCard(
                          child: CtMarksHistogram(data: ctMarksData!),
                        ),
                      ),
                    ),
                    const _SectionHeader(title: "CT Marks Details"),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: GlassCard(
                          child: CtMarksDetails(data: ctMarksData!),
                        ),
                      ),
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

  // Front Page
  Future<void> _loadRoutineData({bool forceRefresh = false}) async {
    try {
      Map<String, dynamic>? results;
      if (!forceRefresh) {
        results = await RoutineCache.loadRoutine();
      }
      if (results == null) {
        results = await CollectData.collectAllData();
        await RoutineCache.saveRoutine(results);
      }

      // Determine section based on roll number
      final int roll = int.tryParse(userRoll) ?? 0;
      final bool isSectionA = roll >= 2207001 && roll <= 2207060;
      final String sheetKey = isSectionA ? 'sheet1' : 'sheet2';

      setState(() {
        final routineData = results![sheetKey] ?? [];

        final nextList = getTodayNextClass(routineData);
        nextClass = nextList.isNotEmpty
            ? nextList.first
            : DataModel(
                period: 'No data',
                data: 'No classes scheduled',
                endTime: '',
              );
      });
    } catch (e) {
      setState(() {
        nextClass = DataModel(
          period: 'Error',
          data: 'Could not load routine',
          endTime: '',
        );
      });
    }
  }

  Future<void> _loadProfile() async {
    final profile = await loadUserProfile();
    // Try to load formatted CT marks from Hive cache
    final cachedCt = await loadCachedUserCtMarks();

    setState(() {
      userProfile = profile;
      userRoll = profile?['roll'] ?? '';
      // Use cached, fallback to dynamic parse if cache is absent
      ctMarksData = cachedCt ?? parseCtMarksFromProfile(profile);
    });

    // Now that userRoll is available, load the routine data
    await _loadRoutineData();
  }

  Future<void> _loadNoticesSummary() async {
    final notices = await fetchNoticesFromFirestore();
    final titles = notices
        .map((n) => n['data']?['desc']?.toString() ?? "")
        .toList();
    _noticeSummary = titles.join("; ");
    setState(() {});
  }

  // Load Data End -------------------------------------------------------------------------------------------------------------------

  int _daysUntil(String date) {
    try {
      DateTime examDate = DateTime.parse(date);
      DateTime today = DateTime.now();
      return examDate
          .difference(DateTime(today.year, today.month, today.day))
          .inDays;
    } catch (e) {
      return 99999; // Arbitrarily large for failed parse, sorts those exams last
    }
  }

  Future<void> _loadUpcomingExam() async {
    try {
      final exams =
          await fetchExamsFromFirestore(); // Your async fetch function

      // Filter exams to only include future ones
      final futureExams = exams.where((exam) {
        final days = _daysUntil(exam['data']['date'] ?? '');
        return days >= 0;
      }).toList();

      if (futureExams.isNotEmpty) {
        // Sort future exams by closest date
        futureExams.sort((a, b) {
          final aDays = _daysUntil(a['data']['date'] ?? '');
          final bDays = _daysUntil(b['data']['date'] ?? '');
          return aDays.compareTo(bDays);
        });

        setState(() {
          upcomingExam = futureExams.first;
        });
      } else {
        setState(() {
          upcomingExam = null;
        });
      }
    } catch (e) {
      setState(() {
        upcomingExam = null;
      });
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(23, 24, 23, 12),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>?> loadCachedUserCtMarks() async {
  final box = await Hive.openBox(userCtMarksBox);
  final raw = box.get(userCtMarksKey);

  if (raw is Map) {
    final coursesRaw = raw['courses'];

    if (coursesRaw is Map) {
      final courses = <String, List<List<int>>>{};

      for (final entry in coursesRaw.entries) {
        final key = entry.key.toString();
        final value = entry.value;

        if (value is List) {
          final marks = value.map<List<int>>((pair) {
            if (pair is List && pair.length == 2) {
              return [
                int.parse(pair[0].toString()),
                int.parse(pair[1].toString()),
              ];
            }
            return [0, 0];
          }).toList();

          courses[key] = marks;
        }
      }

      return {'courses': courses};
    }
  }

  return null;
}

Future<void> cacheUserCtMarks(Map<String, dynamic> formattedCtMarks) async {
  final box = await Hive.openBox(userCtMarksBox);
  await box.put(userCtMarksKey, formattedCtMarks);
}

String extractName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return '';
  final trimmed = fullName.trim();

  // Remove all spaces and check character count
  final nonSpaceChars = trimmed.replaceAll(' ', '');
  if (nonSpaceChars.length <= 3) {
    // Get index of second space
    int first = trimmed.indexOf(' ');
    if (first == -1) return trimmed; // No spaces
    int second = trimmed.indexOf(' ', first + 1);
    if (second == -1) return trimmed; // Only one space
    return trimmed.substring(0, second).trim();
  } else {
    // Typical case: cut at first space
    int first = trimmed.indexOf(' ');
    if (first == -1) return trimmed; // No spaces
    return trimmed.substring(0, first);
  }
}
