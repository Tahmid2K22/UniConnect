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
    final avgExams = avgCourses[course] as List;
    for (int i = 0; i < userExams.length; i++) {
      final userPair = userExams[i] as List;
      final avgPair = avgExams[i] as List;
      final userPercent = (userPair[0] / userPair[1]) * 100;
      final avgPercent = (avgPair[0] / avgPair[1]) * 100;
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
