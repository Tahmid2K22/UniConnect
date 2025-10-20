import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/calendar/data_models.dart';
import '../utils/glass_card.dart';
import '../firebase/firestore/database.dart';

class AcademicCalendarWidget extends StatelessWidget {
  const AcademicCalendarWidget({super.key});

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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: fetchCalendarFromFirestore(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox(
            height: 180,
            child: Center(child: Text("No calendar data available")),
          );
        }

        // Convert Firestore -> Semester model
        final semester = Semester.fromMap(snapshot.data!);
        final today = DateTime.now();

        final semesterProgress = calculateSemesterProgress(today, semester);

        final currentVacation = semester.vacations.firstWhere(
          (v) =>
              today.isAfter(v.startDate.subtract(const Duration(days: 1))) &&
              today.isBefore(v.endDate.add(const Duration(days: 1))),
          orElse: () =>
              Vacation(name: "", startDate: DateTime(0), endDate: DateTime(0)),
        );
        final isVacationActive = currentVacation.name.isNotEmpty;

        final nextVacation = semester.vacations.firstWhere(
          (v) => v.startDate.isAfter(today),
          orElse: () =>
              Vacation(name: "", startDate: DateTime(0), endDate: DateTime(0)),
        );

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/calendar'),
          child: SizedBox(
            height: 180,
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header
                        Flexible(
                          child: Text(
                            today.isBefore(semester.startDate)
                                ? "Semester Starts Soon"
                                : today.isAfter(semester.finalsEnd)
                                ? "Semester Ended 🎉"
                                : isVacationActive
                                ? currentVacation.name
                                : today.isAfter(semester.finalsStart)
                                ? "Term Finals"
                                : "Week ${((today.difference(semester.startDate).inDays + 1) / 7).ceil()}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.pressStart2p(
                              fontSize: 20,
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 2),
                        // Subtitle
                        Flexible(
                          child: Text(
                            today.isBefore(semester.startDate)
                                ? "Semester starts in ${semester.startDate.difference(today).inDays + 1} days"
                                : today.isAfter(semester.finalsEnd)
                                ? "New calendar will be available soon"
                                : "Semester ends in ${semester.finalsEnd.difference(today).inDays + 1} days",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Progress
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: semesterProgress,
                            minHeight: 10,
                            color: Colors.cyanAccent,
                            backgroundColor: Colors.white10,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Info Boxes
                        Row(
                          children: [
                            _MiniInfoBox(
                              title: isVacationActive
                                  ? "Reopens in"
                                  : "Next Vacation",
                              value: isVacationActive
                                  ? "${currentVacation.endDate.difference(today).inDays + 1}d"
                                  : nextVacation.name.isNotEmpty
                                  ? "${nextVacation.startDate.difference(today).inDays + 1}d"
                                  : "-",
                            ),
                            _MiniInfoBox(
                              title: "Finals",
                              value: today.isBefore(semester.finalsStart)
                                  ? "${semester.finalsStart.difference(today).inDays + 1}d"
                                  : today.isAfter(semester.finalsEnd)
                                  ? "Done"
                                  : "Now",
                            ),
                            _MiniInfoBox(
                              title: "Progress",
                              value: "${(semesterProgress * 100).toInt()}%",
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniInfoBox extends StatelessWidget {
  final String title;
  final String value;

  const _MiniInfoBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: Colors.white60,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
