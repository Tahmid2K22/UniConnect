import 'data_models.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum EventType { week, vacation, pl, finals }

int calculateDaysBetween(DateTime start, DateTime end) {
  return end.difference(start).inDays;
}

String formatDate(DateTime date) {
  return "${date.day}/${date.month}/${date.year}";
}

DateTime stripTime(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

double calculateSemesterProgress(DateTime today, Semester semester) {
  final t = stripTime(today);
  final start = stripTime(semester.startDate);
  final end = stripTime(semester.finalsEnd);

  final totalDays = end.difference(start).inDays + 1;

  int passedDays;
  if (t.isBefore(start)) {
    passedDays = 0;
  } else if (t.isAfter(end)) {
    passedDays = totalDays;
  } else {
    passedDays = t.difference(start).inDays + 1;
  }

  if (totalDays <= 0) return 0.0;
  return (passedDays / totalDays).clamp(0.0, 1.0);
}

class CalendarStatus {
  final String heroTitle;
  final String heroSubtitle;
  final double heroProgress;

  CalendarStatus(this.heroTitle, this.heroSubtitle, this.heroProgress);
}

// Generate an accurate breakdown of the semester.
List<Map<String, dynamic>> generateSemesterEvents(
  Semester semester,
  DateTime today,
) {
  final List<Map<String, dynamic>> events = [];
  final t = stripTime(today);
  DateTime current = stripTime(semester.startDate);
  final plStart = stripTime(semester.plStart);
  int weekNumber = 1;

  // Weeks (Sunday → Thursday)
  // Last week ends before PL starts
  while (current.isBefore(plStart)) {
    final weekStart = current;
    DateTime adjustedWeekEnd = current.add(
      const Duration(days: 4),
    ); // 5 working days

    // Cap at PL start
    if (adjustedWeekEnd.isAfter(plStart.subtract(const Duration(days: 1)))) {
      adjustedWeekEnd = plStart.subtract(const Duration(days: 1));
    }

    // Check vacations during this work week
    bool isFullyCovered = false;
    for (var v in semester.vacations) {
      final vStart = stripTime(v.startDate);
      final vEnd = stripTime(v.endDate);

      // If vacation covers the entire work week
      if (!weekStart.isBefore(vStart) && !adjustedWeekEnd.isAfter(vEnd)) {
        isFullyCovered = true;
        break;
      }

      // If vacation starts inside the week, truncate the week before vacation
      if (!vStart.isAfter(adjustedWeekEnd) && vStart.isAfter(weekStart)) {
        adjustedWeekEnd = vStart.subtract(const Duration(days: 1));
      }
    }

    if (!isFullyCovered && !weekStart.isAfter(adjustedWeekEnd)) {
      events.add({
        'title': "Week $weekNumber",
        'start': weekStart,
        'end': adjustedWeekEnd,
        'type': EventType.week,
        'isCompleted': adjustedWeekEnd.isBefore(t),
      });
      weekNumber++;
    }

    current = current.add(const Duration(days: 7));
  }

  // Add vacations
  for (var v in semester.vacations) {
    final vStart = stripTime(v.startDate);
    final vEnd = stripTime(v.endDate);
    events.add({
      'title': "Vacation - ${v.name}",
      'start': vStart,
      'end': vEnd,
      'type': EventType.vacation,
      'isCompleted': vEnd.isBefore(t),
    });
  }

  // Add PL
  final plE = stripTime(semester.plEnd);
  events.add({
    'title': "Preparatory Leave",
    'start': plStart,
    'end': plE,
    'type': EventType.pl,
    'isCompleted': plE.isBefore(t),
  });

  // Add Finals
  DateTime segmentStart = stripTime(semester.finalsStart);
  final finalEnd = stripTime(semester.finalsEnd);

  // Protect against infinity loop:
  int loopGuard = 0;
  while (!segmentStart.isAfter(finalEnd) && loopGuard < 50) {
    loopGuard++;

    // Find earliest vacation that overlaps with our current finals segment
    var overlappingVacation = semester.vacations.where((v) {
      final vs = stripTime(v.startDate);
      final ve = stripTime(v.endDate);
      return !vs.isAfter(finalEnd) && !ve.isBefore(segmentStart);
    }).toList();

    if (overlappingVacation.isEmpty) {
      events.add({
        'title': "Term Finals",
        'start': segmentStart,
        'end': finalEnd,
        'type': EventType.finals,
        'isCompleted': finalEnd.isBefore(t),
      });
      break;
    } else {
      // Sort to find the first overlapping one
      overlappingVacation.sort((a, b) => a.startDate.compareTo(b.startDate));
      var firstV = overlappingVacation.first;
      final fVs = stripTime(firstV.startDate);
      final fVe = stripTime(firstV.endDate);

      if (fVs.isAfter(segmentStart)) {
        events.add({
          'title': "Term Finals",
          'start': segmentStart,
          'end': fVs.subtract(const Duration(days: 1)),
          'type': EventType.finals,
          'isCompleted': fVs.subtract(const Duration(days: 1)).isBefore(t),
        });
      }
      segmentStart = fVe.add(const Duration(days: 1));
    }
  }

  events.sort(
    (a, b) => (a['start'] as DateTime).compareTo(b['start'] as DateTime),
  );
  return events;
}

CalendarStatus getCurrentCalendarStatus(Semester semester, DateTime rawToday) {
  final today = stripTime(rawToday);
  final semesterStart = stripTime(semester.startDate);
  final semesterEnd = stripTime(semester.finalsEnd);

  final beforeSemester = today.isBefore(semesterStart);
  final afterSemester = today.isAfter(semesterEnd);

  // Check active vacation
  final currentVacation = semester.vacations.firstWhere(
    (v) {
      final vs = stripTime(v.startDate);
      final ve = stripTime(v.endDate);
      return !today.isBefore(vs) && !today.isAfter(ve);
    },
    orElse: () =>
        Vacation(name: "", startDate: DateTime(0), endDate: DateTime(0)),
  );
  final isVacationActive = currentVacation.name.isNotEmpty;

  String heroTitle;
  String heroSubtitle;
  double heroProgress;

  if (beforeSemester) {
    final daysToStart = semesterStart.difference(today).inDays + 1;
    heroTitle = "Semester Starting Soon";
    heroSubtitle = "$daysToStart days until semester starts";
    heroProgress = 0.0;
  } else if (afterSemester) {
    heroTitle = "Semester Ended 🎉";
    heroSubtitle = "Hope you did great!";
    heroProgress = 1.0;
  } else if (isVacationActive) {
    final curVS = stripTime(currentVacation.startDate);
    final curVE = stripTime(currentVacation.endDate);
    final totalDays = curVE.difference(curVS).inDays + 1;
    final passedDays = today.difference(curVS).inDays + 1;
    heroTitle = currentVacation.name;
    heroSubtitle = "$passedDays of $totalDays days";
    heroProgress = calculateSemesterProgress(today, semester);
  } else {
    final fS = stripTime(semester.finalsStart);
    final fE = stripTime(semester.finalsEnd);
    final plS = stripTime(semester.plStart);
    final plE = stripTime(semester.plEnd);

    if (!today.isBefore(fS) && !today.isAfter(fE)) {
      final totalDays = fE.difference(fS).inDays + 1;
      final passedDays = today.difference(fS).inDays + 1;
      heroTitle = "Term Finals";
      heroSubtitle = "$passedDays of $totalDays days";
      heroProgress = calculateSemesterProgress(today, semester);
    } else if (!today.isBefore(plS) && !today.isAfter(plE)) {
      final totalDays = plE.difference(plS).inDays + 1;
      final passedDays = today.difference(plS).inDays + 1;
      heroTitle = "Preparatory Leave";
      heroSubtitle = "$passedDays of $totalDays days";
      heroProgress = calculateSemesterProgress(today, semester);
    } else {
      // Normal Week
      final events = generateSemesterEvents(semester, today);
      var currentWeek = events.firstWhere(
        (e) =>
            e['type'] == EventType.week &&
            !today.isBefore(e['start']) &&
            !today.isAfter(
              (e['end'] as DateTime).add(const Duration(days: 2)),
            ), // including weekend
        orElse: () => <String, dynamic>{}, // empty
      );

      if (currentWeek.isEmpty) {
        heroTitle = "Semester Progress";
        heroSubtitle = "Keep going strong!";
      } else {
        heroTitle = currentWeek['title'];
        heroSubtitle = "Keep going strong!";
      }

      heroProgress = calculateSemesterProgress(today, semester);
    }
  }

  return CalendarStatus(heroTitle, heroSubtitle, heroProgress);
}

// ---------------------------------------------------------
// NOTE MANAGEMENT (Memories & Reminders)
// ---------------------------------------------------------

/// Get up to 3 notes for a specific event
List<String> getEventNotes(String eventTitle) {
  final box = Hive.box('calendarNotesBox');
  final notes = box.get(eventTitle) as List<dynamic>?;
  if (notes == null) return [];
  return notes.map((e) => e.toString()).toList();
}

/// Save a short note under a specific event. Maximum of 3.
void saveEventNote(String eventTitle, String noteText) {
  if (noteText.trim().isEmpty) return;
  final box = Hive.box('calendarNotesBox');
  List<String> notes = getEventNotes(eventTitle);
  if (notes.length >= 3) return; // Prevent more than 3
  notes.add(noteText.trim());
  box.put(eventTitle, notes);
}

/// Delete a specific note by index
void deleteEventNote(String eventTitle, int index) {
  final box = Hive.box('calendarNotesBox');
  List<String> notes = getEventNotes(eventTitle);
  if (index >= 0 && index < notes.length) {
    notes.removeAt(index);
    box.put(eventTitle, notes);
  }
}

/// Helper to clear all notes if the entire calendar resets by the admin
void clearAllCalendarNotes() {
  final box = Hive.box('calendarNotesBox');
  box.clear();
}
