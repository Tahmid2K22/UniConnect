import '../features/todo/todo_task.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uni_connect/models/data_model.dart';

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
  final today = DateTime(now.year, now.month, now.day); // strip time
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

List<DataModel> getTodayNextClass(List<List<String>> sectionData) {
  if (sectionData.isEmpty) {
    return [
      DataModel(period: 'No data', data: 'No classes scheduled', endTime: ''),
    ];
  }

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

    if (todayRow.isEmpty) {
      return [DataModel(period: 'No classes', data: 'Rest up!', endTime: '')];
    }

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
