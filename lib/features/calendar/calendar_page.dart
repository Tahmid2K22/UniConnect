import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data_models.dart';
import 'calendar_widgets/index.dart';
import 'package:uni_connect/features/navigation/side_navigation.dart';
import '../../firebase/firestore/database.dart';
import 'package:flutter/foundation.dart';
import 'package:uni_connect/features/web/web_layout.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late Future<Semester?> _semesterFuture;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _semesterFuture = fetchCalendarFromFirestore().then((map) {
      if (map != null) {
        return Semester.fromMap(map);
      } else {
        return null;
      }
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _semesterFuture = reloadCalendar().then((map) {
        if (map != null) {
          return Semester.fromMap(map);
        } else {
          return null;
        }
      });
    });
    await _semesterFuture;
  }

  // -------- Helpers for gradients & progress --------

  List<Color> getGradientColors(String type, int daysLeft) {
    switch (type) {
      case "Semester Starts":
        return [
          Colors.indigo.shade900,
          Colors.indigo.shade700,
          Colors.cyan.shade800,
        ];
      case "Vacation":
        return [
          Colors.teal.shade900,
          Colors.green.shade700,
          Colors.teal.shade600,
          Colors.green.shade300.withOpacity(0.7),
        ];
      case "PL Break":
        return [
          Colors.brown.shade800,
          Colors.deepOrange.shade700,
          Colors.orange.shade600,
          Colors.red.shade300.withOpacity(0.6),
        ];
      case "Finals":
        return [
          Colors.red.shade900,
          Colors.red.shade700,
          Colors.deepOrange.shade600,
          Colors.amber.shade400.withOpacity(0.7),
        ];
      default:
        return [
          Colors.deepPurple.shade900,
          Colors.deepPurple.shade700,
          Colors.purple.shade500,
          Colors.pink.shade300.withOpacity(0.6),
        ];
    }
  }

  List<Color> getHeroCardGradient(double completionPercent) {
    double percent = completionPercent.clamp(0.0, 1.0);

    if (percent <= 0.1) {
      return [
        Colors.indigo.shade900,
        Colors.indigo.shade700,
        Colors.blueGrey.shade700,
      ];
    } else if (percent <= 0.2) {
      return [
        Colors.indigo.shade800,
        Colors.teal.shade800,
        Colors.teal.shade600,
      ];
    } else if (percent <= 0.3) {
      return [
        Colors.teal.shade800,
        Colors.teal.shade600,
        Colors.green.shade700,
      ];
    } else if (percent <= 0.4) {
      return [
        Colors.green.shade800,
        Colors.green.shade600,
        Colors.lightGreen.shade700,
      ];
    } else if (percent <= 0.5) {
      return [
        Colors.green.shade700,
        Colors.lime.shade800,
        Colors.lime.shade600,
      ];
    } else if (percent <= 0.6) {
      return [
        Colors.lime.shade700,
        Colors.amber.shade700,
        Colors.amber.shade600,
      ];
    } else if (percent <= 0.7) {
      return [
        Colors.amber.shade800,
        Colors.deepOrange.shade700,
        Colors.orange.shade600,
      ];
    } else if (percent <= 0.8) {
      return [
        Colors.deepOrange.shade800,
        Colors.red.shade700,
        Colors.red.shade600,
      ];
    } else if (percent <= 0.9) {
      return [
        Colors.red.shade800,
        Colors.pink.shade700,
        Colors.purple.shade600,
      ];
    } else {
      return [
        Colors.amber.shade700,
        Colors.green.shade700,
        Colors.teal.shade600,
      ];
    }
  }

  double calculateSemesterProgress(DateTime today, Semester semester) {
    final semesterStart = semester.startDate;
    final semesterEnd = semester.finalsEnd;

    final totalDays = semesterEnd.difference(semesterStart).inDays + 1;

    int passedDays;
    if (today.isBefore(semesterStart)) {
      passedDays = 0;
    } else if (today.isAfter(semesterEnd)) {
      passedDays = totalDays;
    } else {
      passedDays = today.difference(semesterStart).inDays + 1;
    }

    return (passedDays / totalDays).clamp(0.0, 1.0);
  }

  // -------- Build --------

  @override
  Widget build(BuildContext context) {
    final content = GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (!kIsWeb && details.delta.dx < -10) {
          _scaffoldKey.currentState?.openEndDrawer();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: kIsWeb ? null : const SideNavigation(),
        backgroundColor: kIsWeb
            ? Colors.transparent
            : const Color.fromARGB(255, 11, 11, 34),
        appBar: kIsWeb
            ? null
            : AppBar(
                backgroundColor: const Color.fromARGB(255, 11, 11, 34),
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text(
                  "Academic Calendar",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: const BackButton(color: Colors.white),
              ),
        body: FutureBuilder<Semester?>(
          future: _semesterFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error loading calendar",
                  style: GoogleFonts.poppins(color: Colors.redAccent),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Text(
                  "No calendar data found",
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              );
            }

            final semester = snapshot.data!;
            final today = DateTime.now();

            final semesterStart = semester.startDate;
            final semesterEnd = semester.endDate;

            final beforeSemester = today.isBefore(semesterStart);
            final afterSemester = today.isAfter(semesterEnd);

            // Active vacation
            final currentVacation = semester.vacations.firstWhere(
              (v) =>
                  today.isAfter(
                    v.startDate.subtract(const Duration(days: 1)),
                  ) &&
                  today.isBefore(v.endDate.add(const Duration(days: 1))),
              orElse: () => Vacation(
                name: "",
                startDate: DateTime(0),
                endDate: DateTime(0),
              ),
            );
            final isVacationActive = currentVacation.name.isNotEmpty;

            // ---- Hero Section ----
            String heroTitle;
            String heroSubtitle;
            double heroProgress;
            List<Color> heroGradient;

            if (beforeSemester) {
              final daysToStart = semesterStart.difference(today).inDays + 1;
              heroTitle = "Semester Starting Soon";
              heroSubtitle = "$daysToStart days until semester starts";
              heroProgress = 0.0;
              heroGradient = getHeroCardGradient(heroProgress);
            } else if (afterSemester) {
              heroTitle = "Semester Ended 🎉";
              heroSubtitle = "Hope you did great!";
              heroProgress = 1.0;
              heroGradient = getHeroCardGradient(heroProgress);
            } else if (isVacationActive) {
              final totalDays =
                  currentVacation.endDate
                      .difference(currentVacation.startDate)
                      .inDays +
                  1;
              final passedDays =
                  today.difference(currentVacation.startDate).inDays + 1;
              heroTitle = currentVacation.name;
              heroSubtitle = "$passedDays of $totalDays days";
              heroProgress = calculateSemesterProgress(today, semester);
              heroGradient = getHeroCardGradient(heroProgress);
            } else if (today.isBefore(semester.plStart)) {
              final passedDays = today.difference(semesterStart).inDays + 1;
              heroTitle = "Week ${(passedDays / 7).ceil()}";
              heroSubtitle = "Keep going strong!";
              heroProgress = calculateSemesterProgress(today, semester);
              heroGradient = getHeroCardGradient(heroProgress);
            } else if (today.isAfter(semester.plStart) &&
                today.isBefore(semester.plEnd)) {
              final totalDays =
                  semester.plEnd.difference(semester.plStart).inDays + 1;
              final passedDays = today.difference(semester.plStart).inDays + 1;
              heroTitle = "Preparatory Leave";
              heroSubtitle = "$passedDays of $totalDays days";
              heroProgress = calculateSemesterProgress(today, semester);
              heroGradient = getHeroCardGradient(heroProgress);
            } else {
              final totalDays =
                  semesterEnd.difference(semesterStart).inDays + 1;
              final passedDays = today.difference(semesterStart).inDays + 1;
              heroTitle = "Semester Progress";
              heroSubtitle = "${(passedDays / totalDays * 100).round()}% done";
              heroProgress = calculateSemesterProgress(today, semester);
              heroGradient = getHeroCardGradient(heroProgress);
            }

            // ---- Countdown ----
            int daysToNextEvent;
            String nextEventTitle;
            List<Color> nextEventGradient;

            if (beforeSemester) {
              daysToNextEvent = semesterStart.difference(today).inDays + 1;
              nextEventTitle = "Semester Starts";
              nextEventGradient = getGradientColors(
                nextEventTitle,
                daysToNextEvent,
              );
            } else if (isVacationActive) {
              final totalVacationDays =
                  currentVacation.endDate
                      .difference(currentVacation.startDate)
                      .inDays +
                  1;
              final passedVacationDays =
                  today.difference(currentVacation.startDate).inDays + 1;
              daysToNextEvent = totalVacationDays - passedVacationDays;
              nextEventTitle = "Ongoing - ${currentVacation.name}";
              nextEventGradient = getGradientColors(
                "Vacation",
                daysToNextEvent,
              );
            } else {
              final upcomingVacation = semester.vacations.firstWhere(
                (v) => v.startDate.isAfter(today),
                orElse: () => Vacation(
                  name: "",
                  startDate: DateTime(0),
                  endDate: DateTime(0),
                ),
              );
              if (upcomingVacation.name.isNotEmpty) {
                daysToNextEvent =
                    upcomingVacation.startDate.difference(today).inDays + 1;
                nextEventTitle = "Upcoming - ${upcomingVacation.name}";
                nextEventGradient = getGradientColors(
                  "Vacation",
                  daysToNextEvent,
                );
              } else {
                daysToNextEvent = 0;
                nextEventTitle = "No Upcoming Event";
                nextEventGradient = getGradientColors("Semester Starts", 0);
              }
            }

            int daysToFinals;
            if (today.isAfter(semester.finalsEnd)) {
              daysToFinals = 0;
            } else if (today.isBefore(semester.finalsStart)) {
              daysToFinals = semester.finalsStart.difference(today).inDays + 1;
            } else {
              daysToFinals = semester.finalsEnd.difference(today).inDays + 1;
            }
            final finalsGradient = getGradientColors("Finals", daysToFinals);

            // ---- Achievements ----
            final totalSemesterDays =
                semesterEnd.difference(semesterStart).inDays + 1;
            final passedSemesterDays = today.isBefore(semesterStart)
                ? 0
                : (today.isAfter(semesterEnd)
                      ? totalSemesterDays
                      : today.difference(semesterStart).inDays + 1);

            final achievements = <Widget>[];
            if (passedSemesterDays >= totalSemesterDays / 2 &&
                passedSemesterDays < totalSemesterDays) {
              achievements.add(
                const AchievementCard(title: "Halfway There 🎯"),
              );
            }
            if (today.isAfter(semester.plStart) &&
                today.isBefore(semester.plEnd)) {
              achievements.add(
                const AchievementCard(title: "Work Weeks Done 🚀"),
              );
            }
            if (today.isAfter(semester.finalsEnd)) {
              achievements.add(
                const AchievementCard(title: "Semester Completed 🏆"),
              );
            }

            return RefreshIndicator(
              color: Colors.cyanAccent,
              backgroundColor: const Color.fromARGB(255, 20, 20, 50),
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (kIsWeb) ...[
                    Text(
                      "Academic Calendar",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  HeroCard(
                    baseGradient: heroGradient,
                    title: heroTitle,
                    progress: heroProgress,
                    aiSummary: heroSubtitle,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CountdownCard(
                          title: nextEventTitle,
                          daysLeft: daysToNextEvent,
                          icon: Icons.event,
                          gradientColors: nextEventGradient,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CountdownCard(
                          title: "Finals",
                          daysLeft: daysToFinals,
                          icon: Icons.emoji_events,
                          gradientColors: finalsGradient,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ...achievements,
                  const SizedBox(height: 24),
                  SemesterBreakdownPage(semester: semester),
                ],
              ),
            );
          },
        ),
      ),
    );

    if (kIsWeb) {
      return WebLayout(currentRoute: '/calendar', child: content);
    }
    return content;
  }
}
