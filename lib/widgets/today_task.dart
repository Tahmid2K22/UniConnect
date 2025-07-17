import "package:uni_connect/features/todo/todo_task.dart";

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
