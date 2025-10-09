import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data_models.dart';

enum EventType { week, vacation, pl, finals }

class SemesterBreakdownPage extends StatelessWidget {
  final Semester semester;

  const SemesterBreakdownPage({super.key, required this.semester});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    // 1️⃣ Build list of events dynamically
    final List<Map<String, dynamic>> events = [];

    // Weeks (Sunday → Thursday), skip any week that overlaps a vacation
    DateTime current = semester.startDate;
    int weekNumber = 1;

    // Last week ends **before PL starts**
    while (current.isBefore(semester.plStart)) {
      final weekStart = current;
      final weekEnd = current.add(const Duration(days: 4));

      // Ensure we don't exceed PL start
      final adjustedWeekEnd =
          weekEnd.isAfter(semester.plStart.subtract(const Duration(days: 1)))
          ? semester.plStart.subtract(const Duration(days: 1))
          : weekEnd;

      // Skip overlapping vacation weeks
      bool isOverlappingVacation = semester.vacations.any(
        (v) =>
            weekStart.isBefore(v.endDate.add(const Duration(days: 1))) &&
            adjustedWeekEnd.isAfter(
              v.startDate.subtract(const Duration(days: 1)),
            ),
      );

      if (!isOverlappingVacation) {
        events.add({
          'title': "Week $weekNumber",
          'start': weekStart,
          'end': adjustedWeekEnd,
          'type': EventType.week,
          'isCompleted': adjustedWeekEnd.isBefore(today),
        });
        weekNumber++;
      }

      // Move to next week
      current = current.add(const Duration(days: 7));
    }

    // Add vacations
    for (var v in semester.vacations) {
      events.add({
        'title': "Vacation - ${v.name}",
        'start': v.startDate,
        'end': v.endDate,
        'type': EventType.vacation,
        'isCompleted': v.endDate.isBefore(today),
      });
    }

    // Add Preparatory Leave (PL)
    events.add({
      'title': "Preparatory Leave",
      'start': semester.plStart,
      'end': semester.plEnd,
      'type': EventType.pl,
      'isCompleted': semester.plEnd.isBefore(today),
    });

    // Add Term Finals (handle vacation pauses)
    final finalStart = semester.finalsStart;
    final finalEnd = semester.finalsEnd;
    DateTime segmentStart = finalStart;

    while (segmentStart.isBefore(finalEnd.add(const Duration(days: 1)))) {
      final overlappingVacation = semester.vacations.firstWhere(
        (v) =>
            v.startDate.isBefore(finalEnd.add(const Duration(days: 1))) &&
            v.endDate.isAfter(segmentStart.subtract(const Duration(days: 1))),
        orElse: () =>
            Vacation(name: "", startDate: DateTime(0), endDate: DateTime(0)),
      );

      if (overlappingVacation.name.isEmpty) {
        // No overlap
        events.add({
          'title': "Term Finals",
          'start': segmentStart,
          'end': finalEnd,
          'type': EventType.finals,
          'isCompleted': finalEnd.isBefore(today),
        });
        break;
      } else {
        if (overlappingVacation.startDate.isAfter(segmentStart)) {
          events.add({
            'title': "Term Finals",
            'start': segmentStart,
            'end': overlappingVacation.startDate.subtract(
              const Duration(days: 1),
            ),
            'type': EventType.finals,
            'isCompleted': overlappingVacation.startDate
                .subtract(const Duration(days: 1))
                .isBefore(today),
          });
        }

        segmentStart = overlappingVacation.endDate.add(const Duration(days: 1));
        if (segmentStart.isAfter(finalEnd)) break;
      }
    }

    // Sort events by start date
    events.sort((a, b) => a['start'].compareTo(b['start']));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Semester Breakdown",
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...events.map((e) {
          // Assign background color dynamically
          Color bgColor;
          switch (e['type'] as EventType) {
            case EventType.week:
              bgColor = e['isCompleted']
                  ? Colors.grey.shade800
                  : Colors.blue.shade600;
              break;
            case EventType.vacation:
              bgColor = e['isCompleted']
                  ? Colors.grey.shade800
                  : Colors.green.shade500;
              break;
            case EventType.pl:
              bgColor = e['isCompleted']
                  ? Colors.grey.shade800
                  : Colors.indigo.shade600;
              break;
            case EventType.finals:
              bgColor = e['isCompleted']
                  ? Colors.grey.shade800
                  : Colors.orange.shade600;
              break;
          }

          IconData icon;
          switch (e['type'] as EventType) {
            case EventType.week:
              icon = Icons.check_circle_outline;
              break;
            case EventType.vacation:
              icon = Icons.beach_access;
              break;
            case EventType.pl:
              icon = Icons.shield;
              break;
            case EventType.finals:
              icon = Icons.emoji_events;
              break;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bgColor.withOpacity(0.85), bgColor.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e['title'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            decoration: e['isCompleted']
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          "${(e['start'] as DateTime).day}/${(e['start'] as DateTime).month} - ${(e['end'] as DateTime).day}/${(e['end'] as DateTime).month}",
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
