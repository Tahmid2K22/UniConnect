import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/todo/todo_task.dart';
import 'features/navigation/side_navigation.dart';
import 'package:intl/intl.dart' as intl;
import 'features/routine/collect_data.dart';

// Front page layout
class FrontPage extends StatefulWidget {
  const FrontPage({super.key});

  @override
  State<FrontPage> createState() => _FrontPageState();
}

// Front Page State
class _FrontPageState extends State<FrontPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _controller;

  List<List<String>> sectionAData =
      []; // Will hold raw routine data for Section A
  DataModel? nextClass;

  // For UniConnect Text animation
  @override
  void initState() {
    super.initState();
    _loadRoutineData();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Build widget
  @override
  Widget build(BuildContext context) {
    // Placeholder for Todo-list tasks

    // Directionality to add the side navigation menu
    return Directionality(
      textDirection: TextDirection.ltr,

      // Gesture Detector to open the side navigation menu
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          // Swipe from right to left
          if (details.delta.dx < -10) {
            scaffoldKey.currentState?.openEndDrawer();
          }
        },
        // Scaffold
        child: Scaffold(
          key: scaffoldKey, // key to open side navigation menu
          backgroundColor: const Color(0xFF0E0E2C),
          endDrawer: const SideNavigation(),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🟣 UniConnect and Hamburger icon
                  Row(
                    children: [
                      // Animated UniConnect text
                      Expanded(
                        child: AnimatedBuilder(
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
                                  stops: [0.0, 0.33, 0.66, 1.0],
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
                      ),

                      // Hamburger Icon for side navigation bar
                      IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () =>
                            scaffoldKey.currentState?.openEndDrawer(),
                      ),
                    ],
                  ),

                  // 🟣 Up Next
                  const SizedBox(height: 10),

                  _sectionTitle(
                    "Up Next",
                  ).animate().fadeIn().moveY(begin: -20, duration: 600.ms),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/routine',
                      ); // Navigate to routine section
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: _glassCard(),
                      child: nextClass == null
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.cyanAccent,
                              ),
                            )
                          : (nextClass!.period == 'No more classes' ||
                                nextClass!.period == 'No data' ||
                                nextClass!.period == 'Error')
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nextClass!.data, style: _sectionTextStyle),
                                const SizedBox(height: 6),
                                Text(
                                  nextClass!.period,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Next Class: ${nextClass!.data}",
                                  style: _sectionTextStyle,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  nextClass!.period,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Ends: ${nextClass!.endTime}",
                                  style: const TextStyle(color: Colors.white38),
                                ),
                              ],
                            ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3),

                  // 🟢 Todo & Exam summary row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Unfinished Tasks
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle("Todo"),
                            ValueListenableBuilder(
                              valueListenable: Hive.box<TodoTask>(
                                'todoBox',
                              ).listenable(),
                              builder: (context, Box<TodoTask> box, _) {
                                final tasks = getDueSoonTasks();
                                if (tasks.isEmpty) {
                                  return GestureDetector(
                                    onTap: () =>
                                        Navigator.pushNamed(context, '/todo'),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: _glassCard(),
                                      child: const Text(
                                        "Add a task to get started!",
                                        style: _sectionTextStyle,
                                      ),
                                    ).animate().fadeIn().slideX(begin: -0.2),
                                  );
                                }
                                return Column(
                                  children: tasks
                                      .map(
                                        (task) => GestureDetector(
                                          onTap: () => Navigator.pushNamed(
                                            context,
                                            '/todo',
                                          ),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6,
                                                  ),
                                              padding: const EdgeInsets.all(12),
                                              decoration: _glassCard(),
                                              child: Text(
                                                task.title +
                                                    (task.dueDate != null
                                                        ? " (Due: ${task.dueDate!.toLocal().toString().split(' ')[0]})"
                                                        : ""),
                                                style: _sectionTextStyle,
                                              ),
                                            ).animate().fadeIn().slideX(begin: -0.2),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Upcoming Exam
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle("Upcoming Exam"),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/exam');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: _glassCard(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "OS Midterm",
                                      style: _sectionTextStyle,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      "June 28, 9:00 AM",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn().slideX(begin: 0.2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 🟡 Task Graph
                  _sectionTitle(
                    "Monthly Task Completion",
                  ).animate().fadeIn().moveY(begin: -10),

                  ValueListenableBuilder(
                    valueListenable: Hive.box<TodoTask>('todoBox').listenable(),
                    builder: (context, Box<TodoTask> box, _) {
                      final taskStats = getCompletionStatsLast30Days();
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/analytics'),
                        child: Container(
                          height: 120,
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
                        ).animate().fadeIn().slideY(begin: 0.3),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // 🔵 Recent Notices
                  _sectionTitle(
                    "Recent Notices",
                  ).animate().fadeIn().moveY(begin: -10),

                  ...[
                    {
                      "title": "Semester Registration Deadline",
                      "desc":
                          "Last date to complete your semester registration is June 30.",
                      "time": "2h ago",
                    },
                    {
                      "title": "Midterm Routine Published",
                      "desc":
                          "Midterm exam routine has been released on the official website.",
                      "time": "5h ago",
                    },
                    {
                      "title": "Club Fair 2025",
                      "desc":
                          "Join the Inter-University Club Fair this Friday in the auditorium.",
                      "time": "1d ago",
                    },
                  ].map((notice) {
                    return GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/notices'),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: _glassCard(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notice["title"]!,
                              style: _sectionTextStyle.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notice["desc"]!,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notice["time"]!,
                              style: const TextStyle(
                                color: Colors.white30,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideX(begin: -0.2),
                    );
                  }),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  static const TextStyle _sectionTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );

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

  List<TodoTask> getAllTasks() {
    final box = Hive.box<TodoTask>('todoBox');
    return box.values.toList();
  }

  List<TodoTask> getDueSoonTasks() {
    final tasks = getAllTasks().where((task) => !task.isDone).toList();

    // Tasks with due dates, sorted by soonest
    final withDueDate = tasks.where((t) => t.dueDate != null).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    // Tasks without due dates
    final withoutDueDate = tasks.where((t) => t.dueDate == null).toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    // Take up to 3 tasks: due soon first, then any others
    return [
      ...withDueDate.take(3),
      ...withoutDueDate.take(3 - withDueDate.length),
    ];
  }

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

  Future<void> _loadRoutineData() async {
    try {
      final results = await CollectData.collectAllData();
      setState(() {
        sectionAData = results['sheet1'] ?? [];
        final nextList = getTodayNextClass(sectionAData);
        // Always set nextClass, even if the list is empty
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
}

// Custom Gradiant Transform Class
class SlideGradientTransform extends GradientTransform {
  final double slidePercent;
  const SlideGradientTransform(this.slidePercent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final double dx = -bounds.width * slidePercent;
    return Matrix4.translationValues(dx, 0, 0);
  }
}

class DataModel {
  final String period;
  final String data;
  final String endTime;

  DataModel({required this.period, required this.data, required this.endTime});
}

List<DataModel> getTodayNextClass(List<List<String>> sectionData) {
  if (sectionData.isEmpty)
    return [
      DataModel(period: 'No data', data: 'No classes scheduled', endTime: ''),
    ];

  final now = DateTime.now();
  final weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final today = weekdays[now.weekday - 1];

  try {
    final todayRow = sectionData.firstWhere(
      (row) => row.isNotEmpty && row[0] == today,
      orElse: () => [],
    );

    if (todayRow.isEmpty)
      return [DataModel(period: 'No classes', data: 'Rest up!', endTime: '')];

    for (int i = 1; i < sectionData[0].length; i++) {
      final period = sectionData[0][i];
      final classTitle = todayRow[i];

      if (classTitle.isEmpty || classTitle == '-') continue;

      final timeRange = RegExp(r'\((.*?)\)').firstMatch(period)?.group(1);
      if (timeRange == null) continue;

      final endTimeStr = timeRange.split('-')[1].trim();
      final endTime = intl.DateFormat('hh:mm a').parse(endTimeStr);
      final endDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        endTime.hour,
        endTime.minute,
      );

      if (now.isBefore(endDateTime)) {
        return [
          DataModel(period: period, data: classTitle, endTime: endTimeStr),
        ];
      }
    }
  } catch (e) {
    debugPrint('Error processing class data: $e');
  }

  return [DataModel(period: 'No more classes', data: 'Rest up!', endTime: '')];
}
