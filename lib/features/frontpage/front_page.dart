import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:marquee/marquee.dart';
// import 'package:intl/intl.dart' as init;
import 'dart:io';
//import 'dart:convert';
//import 'package:image/image.dart' as img;

//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:uni_connect/firebase/firestore/database.dart';

import '../todo/todo_task.dart';

import '../navigation/side_navigation.dart';

import '../routine/collect_data.dart';

import 'package:uni_connect/utils/front_page_utils.dart';
import 'package:uni_connect/models/data_model.dart';

import 'package:uni_connect/widgets/ct_marks_histogram.dart';
import 'package:uni_connect/widgets/ct_marks_details.dart';
import 'package:uni_connect/widgets/load_user_ct_marks.dart';
import 'package:uni_connect/widgets/monthly_task_completion_graph.dart';
import 'package:uni_connect/utils/todo_card.dart';
import 'package:uni_connect/utils/notice_card.dart';
import 'package:uni_connect/utils/dashboard_card.dart';
import 'package:uni_connect/widgets/today_task.dart';

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

  List<List<String>> sectionAData = [];
  DataModel? nextClass;
  Map<String, dynamic>? userProfile;

  String? _profileImagePath;

  Map<String, dynamic>? ctMarksData;

  @override
  void initState() {
    super.initState();
    _loadRoutineData();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: false);
    _loadProfile();
    _loadProfileImagePath();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For progress summary
    final tasks = getAllTasks();
    final todayStats = getTodayTaskStats(tasks);
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
              color: Colors.cyanAccent,
              backgroundColor: const Color.fromARGB(255, 11, 11, 34),
              onRefresh: () async {
                final profile = await reloadUserProfile();
                final parsed = parseCtMarksFromProfile(profile);

                // Save new parsed ct marks to Hive cache
                await cacheUserCtMarks(parsed);

                // ...reload other things as you do
                await reloadExams();
                await reloadNotices();
                await _loadRoutineData();
                await reloadBatchmates();

                setState(() {
                  userProfile = profile;
                  ctMarksData = parsed; // Now already cached for future loads
                });
              },

              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: User Avatar, App Name, Greeting
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left side: UniConnect + Greeting
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      colors: [
                                        Colors.cyan,
                                        Colors.blue,
                                        const Color.fromARGB(255, 192, 56, 216),
                                        Colors.cyan,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      stops: const [0.0, 0.33, 0.66, 1.0],
                                      tileMode: TileMode.repeated,
                                      transform: SlideGradientTransform(
                                        _controller.value,
                                      ),
                                    ).createShader(
                                      Rect.fromLTWH(
                                        0,
                                        0,
                                        bounds.width * 2,
                                        bounds.height,
                                      ),
                                    );
                                  },
                                  child: child,
                                );
                              },
                              child: Text(
                                'UniConnect',
                                style: GoogleFonts.poppins(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 28,
                              width: 200,
                              child: Marquee(
                                text:
                                    "${getGreetingMessage()}, ${userProfile?['name'] ?? ''}!",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                                scrollAxis: Axis.horizontal,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                blankSpace: 40.0,
                                velocity: 50.0,
                                startPadding: 10.0,
                              ),
                            ),
                          ],
                        ),

                        // Right side: Profile image
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, "/profile"),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: _profileImagePath != null
                                ? FileImage(File(_profileImagePath!))
                                : const AssetImage('assets/profile/profile.jpg')
                                      as ImageProvider,
                            backgroundColor: Colors.cyanAccent.withAlpha(50),
                            child: userProfile == null
                                ? const CircularProgressIndicator()
                                : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Next Class Card
                    DashboardCard(
                      icon: Icons.class_,
                      color: Colors.green,
                      title: "Next Class",
                      titleValue: nextClass?.data ?? "No classes scheduled",
                      subtitle: nextClass?.period ?? "",
                      onTap: () => Navigator.pushNamed(context, '/routine'),
                    ),
                    const SizedBox(height: 12),

                    // Upcoming Exam Card (fetches first upcoming exam)
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchExamsFromFirestore(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox(
                            height: 70,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final exams = snapshot.data!;

                        // Sort exams by days left (soonest first)
                        exams.sort((a, b) {
                          final aDays = _daysUntil(a['data']['date'] ?? '');
                          final bDays = _daysUntil(b['data']['date'] ?? '');
                          return aDays.compareTo(bDays);
                        });

                        final exam = exams.isNotEmpty ? exams.first : null;

                        final daysLeft = exam != null
                            ? _daysUntil(exam['data']['date'] ?? '')
                            : null;
                        final daysLeftText = daysLeft == null
                            ? ''
                            : daysLeft < 0
                            ? 'Passed'
                            : daysLeft == 0
                            ? 'Today'
                            : '$daysLeft day${daysLeft == 1 ? '' : 's'} left';

                        return GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/exams'),
                          child: DashboardCard(
                            icon: Icons.event,
                            color: Colors.blueAccent,
                            title: "Upcoming Exam",
                            titleValue:
                                exam?['data']['title'] ?? "No upcoming exams",
                            subtitle: exam != null
                                ? "${exam['data']['date']} • ${exam['data']['time']}"
                                : "",
                            trailingWidget: daysLeft != null
                                ? Text(
                                    daysLeftText,
                                    style: TextStyle(
                                      color: _daysLeftColor(daysLeft),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            onTap: () => Navigator.pushNamed(context, '/exam'),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Notices (horizontal scroll)
                    Text(
                      "Notices",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchNoticesFromFirestore(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox(
                            height: 110,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final noticeList = snapshot.data!;
                        if (noticeList.isEmpty) {
                          return const SizedBox(
                            height: 110,
                            child: Center(
                              child: Text(
                                "No notices found.",
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          );
                        }
                        return GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/notices'),
                          child: SizedBox(
                            height: 110,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: noticeList.map((notice) {
                                final data = notice['data'] ?? {};
                                return NoticeCard(
                                  title: data['title'] ?? "",
                                  desc: data['desc'] ?? "",
                                  time: data['time'] ?? "",
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Todo List (horizontal scroll)
                    Text(
                      "Todo",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder(
                      valueListenable: Hive.box<TodoTask>(
                        'todoBox',
                      ).listenable(),
                      builder: (context, Box<TodoTask> box, _) {
                        final tasks = getDueSoonTasks();
                        if (tasks.isEmpty) {
                          return SizedBox(
                            height: 90,
                            child: Center(
                              child: Text(
                                "No tasks for today!",
                                style: GoogleFonts.poppins(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }
                        return SizedBox(
                          height: 90,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: tasks.map((task) {
                              return GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/todo').then((
                                      _,
                                    ) {
                                      setState(() {}); // Refresh home on return
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
                            }).toList(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Task Graph (small, as a card)
                    Card(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/analytics'),
                        child: SizedBox(
                          width: double.infinity,
                          height: 180,
                          child: ValueListenableBuilder(
                            valueListenable: Hive.box<TodoTask>(
                              'todoBox',
                            ).listenable(),
                            builder: (context, Box<TodoTask> box, _) {
                              final taskStats = getCompletionStatsLast30Days();
                              return MonthlyTaskCompletionGraph(
                                taskStats: taskStats,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Progress Summary / Motivation
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, '/todo').then((_) {
                            setState(() {}); // Refresh home on return
                          }),
                      child: Card(
                        color: Colors.white.withValues(alpha: 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        color: Colors.cyanAccent,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      createdToday == 0
                                          ? "No tasks added today yet."
                                          : (completedToday == createdToday
                                                ? "All done for today! 🎉"
                                                : (completedToday > 0
                                                      ? "Great progress, keep going!"
                                                      : "Let's get started!")),
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
                    const SizedBox(height: 16),
                    if (ctMarksData != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        "CT Marks Histogram",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CtMarksHistogram(data: ctMarksData!),
                      const SizedBox(height: 18),
                      Text(
                        "CT Marks Details",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CtMarksDetails(data: ctMarksData!),
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
      setState(() {
        sectionAData = results!['sheet1'] ?? [];
        final nextList = getTodayNextClass(sectionAData);
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
      // Use cached, fallback to dynamic parse if cache is absent
      ctMarksData = cachedCt ?? parseCtMarksFromProfile(profile);
    });
  }

  void _loadProfileImagePath() {
    _profileImagePath = loadLocalProfileImagePath();
    // syncProfilePicIfNeeded(_profileImagePath);
    setState(() {});
  }

  // Load Data End -------------------------------------------------------------------------------------------------------------------

  // Call this in initState or wherever you check profile state
  // Future<void> syncProfilePicIfNeeded(String? localPath) async {
  //   if (localPath == null) return;

  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null || user.email == null) return;

  //   final docRef = FirebaseFirestore.instance
  //       .collection('students')
  //       .doc(user.email);
  //   final doc = await docRef.get();

  //   if (!doc.exists) return;
  //   final data = doc.data();
  //   if (data == null ||
  //       (data['profile_pic'] == null || data['profile_pic'].isEmpty)) {
  //     final file = File(localPath);
  //     if (!await file.exists()) return;
  //     final bytes = await file.readAsBytes();
  //     final image = img.decodeImage(bytes);
  //     if (image == null) return;
  //     final resized = img.copyResize(image, width: 96, height: 96); // Low-res
  //     final jpg = img.encodeJpg(resized, quality: 60);
  //     final base64Str = base64Encode(jpg);
  //     await docRef.update({'profile_pic': base64Str});
  //   }
  // }
  // Exam Utils

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

  Color _daysLeftColor(int daysLeft) {
    if (daysLeft < 0) return Colors.grey;
    if (daysLeft <= 1) return Colors.redAccent;
    if (daysLeft <= 3) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  //Greet Message Utils

  String getGreetingMessage() {
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday; // Monday=1, Sunday=7 in Dart

    String greeting;

    if (hour >= 1 && hour < 4) {
      greeting = "You should be sleeping, what are you up to? ";
    } else if (hour >= 5 && hour < 12) {
      greeting = "Good morning";
    } else if (hour >= 12 && hour < 17) {
      greeting = "Good afternoon";
    } else if (hour >= 17 && hour < 21) {
      greeting = "Good evening";
    } else {
      greeting = "Good night";
    }

    if ((weekday == 4 || weekday == 5) && !(hour >= 1 && hour < 4)) {
      greeting += ", enjoy your weekend";
    } else if (!(hour >= 1 && hour < 4)) {
      greeting += ", have a nice day";
    }

    return greeting;
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
