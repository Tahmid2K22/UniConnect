import '../models/ct_comparison_entry.dart';

List<CtComparisonEntry> getCtComparisonEntries(
  Map<String, dynamic> userCtData,
  Map<String, dynamic> avgCtData,
) {
  final List<CtComparisonEntry> entries = [];
  final userCourses = userCtData['courses'] as Map<String, dynamic>;
  final avgCourses = avgCtData['courses'] as Map<String, dynamic>;

  for (final course in userCourses.keys) {
    final userExams = userCourses[course] as List;
    final avgExams = avgCourses[course] as List?;

    if (avgExams == null) continue;

    final int len = userExams.length < avgExams.length
        ? userExams.length
        : avgExams.length;

    for (int i = 0; i < len; i++) {
      final userPair = userExams[i] as List;
      final avgPair = avgExams[i] as List;

      final num userTotal = userPair[1] ?? 0;
      final num avgTotal = avgPair[1] ?? 0;
      if (userTotal == 0 || avgTotal == 0) continue;

      final userPercent = (userPair[0] / userTotal) * 100;
      final avgPercent = (avgPair[0] / avgTotal) * 100;
      entries.add(
        CtComparisonEntry(
          course: course,
          ctNumber: i + 1,
          userPercent: userPercent,
          avgPercent: avgPercent,
        ),
      );
    }
  }
  return entries;
}
