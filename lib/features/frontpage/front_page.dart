import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:marquee/marquee.dart';
import 'package:uni_connect/firebase/firestore/database.dart';
import '../todo/todo_task.dart';
import '../navigation/side_navigation.dart';
import '../routine/collect_data.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:uni_connect/widgets/monthly_task_completion_graph.dart';
import 'package:uni_connect/utils/front_page_utils.dart';
import 'package:uni_connect/models/data_model.dart';
import 'package:intl/intl.dart' as init;
import 'dart:io';

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
          backgroundColor: const Color(0xFF0E0E2C),
          endDrawer: const SideNavigation(),

          body: SafeArea(
            child: RefreshIndicator(
              color: Colors.cyanAccent,
              backgroundColor: const Color(0xFF0E0E2C),
              onRefresh: () async {
                // Call your reload functions here
                await _loadRoutineData();
                await _loadProfile();
                setState(() {});
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: User Avatar, App Name, Greeting
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, "/profile"),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: _profileImagePath != null
                                ? FileImage(File(_profileImagePath!))
                                : AssetImage('assets/profile/profile.jpg')
                                      as ImageProvider,
                            backgroundColor: Colors.cyanAccent.withAlpha(50),
                            child: userProfile == null
                                ? const CircularProgressIndicator()
                                : null,
                          ),
                        ),

                        const SizedBox(width: 14),
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
                                  fontSize: 34, // Use your preferred size
                                  fontWeight: FontWeight.bold,
                                  color: Colors
                                      .white, // This is masked by the shader
                                ),
                              ),
                            ),

                            SizedBox(
                              height: 28, // or whatever fits your design
                              width: 200, // or your preferred width
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
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Next Class Card
                    _DashboardCard(
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
  
                        final exam = exams.isNotEmpty ? exams.first : null;

                        final daysLeft = exam != null
                            ? _daysUntil(exam['data']['date'] ?? '')
                            : null;
                        final daysLeftText = daysLeft == null
                            ? ''
                            : daysLeft < 0
                            ? 'Today'
                            : '$daysLeft day${daysLeft == 1 ? '' : 's'} left';

                        return GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/exams'),
                          child: _DashboardCard(
                            icon: Icons.event,
                            color: Colors.blueAccent,
                            title: "Upcoming Exam",
                            titleValue: exam?['data']['title'] ?? "No upcoming exams",
                            subtitle: exam != null
                                ? "${exam['data']['date']}"
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
                                return _NoticeCard(
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
                                child: _TodoCard(
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
                          height: 180, // increased height
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
                    const SizedBox(height: 70),
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

  Future<void> _loadRoutineData() async {
    try {
      final results = await CollectData.collectAllData();
      setState(() {
        sectionAData = results['sheet1'] ?? [];
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

  Future<Map<String, dynamic>> loadExamJson() async {
    final String response = await rootBundle.loadString('assets/exams.json');
    return json.decode(response);
  }

  Future<void> _loadProfile() async {
    final String jsonString = await rootBundle.loadString(
      'assets/user_profile_demo.json',
    );
    setState(() {
      userProfile = json.decode(jsonString);
    });
  }

  void _loadProfileImagePath() {
    final box = Hive.box('profileBox');
    setState(() {
      _profileImagePath = box.get('profileImagePath');
    });
  }

  // Load Data End -------------------------------------------------------------------------------------------------------------------

  // Exam Utils

  int? _daysUntil(String dateStr) {
    try {
      final examDate = init.DateFormat('yyyy-MM-dd').parse(dateStr);
      final now = DateTime.now();
      return examDate.difference(DateTime(now.year, now.month, now.day)).inDays;
    } catch (_) {
      return null;
    }
  }

  Color _daysLeftColor(int daysLeft) {
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

// Get Tasks Data for Today

Map<String, int> getTodayTaskStats(List<TodoTask> tasks) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  int createdToday = 0;
  int completedToday = 0;

  for (final task in tasks) {
    final created = DateTime(
      task.createdAt.year,
      task.createdAt.month,
      task.createdAt.day,
    );
    if (created == today) createdToday += 1;
    if (task.completedAt != null) {
      final completed = DateTime(
        task.completedAt!.year,
        task.completedAt!.month,
        task.completedAt!.day,
      );
      if (completed == today) completedToday += 1;
    }
  }
  return {'createdToday': createdToday, 'completedToday': completedToday};
}

//Dashboard card
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String titleValue;
  final String subtitle;
  final Widget? trailingWidget;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.titleValue,
    required this.subtitle,
    this.trailingWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          title,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleValue,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: trailingWidget,
        onTap: onTap,
      ),
    );
  }
}

// Notice Card for horizontal scroll
class _NoticeCard extends StatelessWidget {
  final String title;
  final String desc;
  final String time;
  const _NoticeCard({
    required this.title,
    required this.desc,
    required this.time,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            time,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// Todo Card for horizontal scroll
class _TodoCard extends StatelessWidget {
  final String title;
  final String due;
  const _TodoCard({required this.title, required this.due});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Due: $due",
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ),
        ],
      ),
    );
  }
}

// Gradiant effect animation
class SlideGradientTransform extends GradientTransform {
  final double slidePercent;
  const SlideGradientTransform(this.slidePercent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final double dx = -bounds.width * slidePercent;
    return Matrix4.translationValues(dx, 0, 0);
  }
}
