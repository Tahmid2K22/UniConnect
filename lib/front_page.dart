import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/todo/todo_task.dart';
import 'features/navigation/side_navigation.dart';
import 'features/routine/collect_data.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:uni_connect/widgets/section_title.dart';
import 'package:uni_connect/widgets/monthly_task_completion_graph.dart';
import 'package:uni_connect/widgets/up_next_card.dart';
import 'package:uni_connect/widgets/todo_preview_list.dart';
import 'package:uni_connect/widgets/exam_preview_list.dart';
import 'package:uni_connect/widgets/notice_preview_list.dart';
import 'package:uni_connect/utils/front_page_utils.dart';
import 'package:uni_connect/models/data_model.dart';

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

  @override
  Widget build(BuildContext context) {
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🟣 UniConnect and Hamburger icon
                  Row(
                    children: [
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

                  const SizedBox(height: 10),

                  // 🟣 Up Next
                  const SectionTitle(
                    "Up Next",
                  ).animate().fadeIn().moveY(begin: -20, duration: 600.ms),
                  UpNextCard(
                    nextClass: nextClass,
                    onTap: () => Navigator.pushNamed(context, '/routine'),
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
                            const SectionTitle("Todo"),
                            ValueListenableBuilder(
                              valueListenable: Hive.box<TodoTask>(
                                'todoBox',
                              ).listenable(),
                              builder: (context, Box<TodoTask> box, _) {
                                final tasks = getDueSoonTasks();
                                return TodoPreviewList(
                                  tasks: tasks,
                                  onTap: () =>
                                      Navigator.pushNamed(context, '/todo'),
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
                            const SectionTitle("Upcoming Exams"),
                            FutureBuilder<Map<String, dynamic>>(
                              future: loadExamJson(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                final examsRaw =
                                    snapshot.data!['upcoming_exams'];
                                final List<Map<String, dynamic>> exams =
                                    examsRaw == null || examsRaw is! List
                                    ? []
                                    : examsRaw
                                          .map<Map<String, dynamic>>(
                                            (e) => Map<String, dynamic>.from(e),
                                          )
                                          .toList();
                                return ExamPreviewList(
                                  exams: exams,
                                  onTap: () =>
                                      Navigator.pushNamed(context, '/exam'),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 🟡 Task Graph
                  const SectionTitle(
                    "Monthly Task Completion",
                  ).animate().fadeIn().moveY(begin: -10),
                  ValueListenableBuilder(
                    valueListenable: Hive.box<TodoTask>('todoBox').listenable(),
                    builder: (context, Box<TodoTask> box, _) {
                      final taskStats = getCompletionStatsLast30Days();
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/analytics'),
                        child: MonthlyTaskCompletionGraph(taskStats: taskStats),
                      ).animate().fadeIn().slideY(begin: 0.3);
                    },
                  ),

                  const SizedBox(height: 30),

                  //  Recent Notices
                  const SectionTitle("Recent Notices"),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchNoticesFromFirestore(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final noticeList = snapshot.data!;
                      return NoticePreviewList(
                        notices: noticeList,
                        onTap: () => Navigator.pushNamed(context, '/notices'),
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
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

  Future<List<Map<String, dynamic>>> fetchNoticesFromFirestore() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('notices')
        .get();
    return querySnapshot.docs.map((doc) {
      return {"id": doc.id, "data": doc.data()};
    }).toList();
  }
  // Load Data End -------------------------------------------------------------------------------------------------------------------
}

// Custom Gradient Transform Class (keep as is)
class SlideGradientTransform extends GradientTransform {
  final double slidePercent;
  const SlideGradientTransform(this.slidePercent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final double dx = -bounds.width * slidePercent;
    return Matrix4.translationValues(dx, 0, 0);
  }
}
