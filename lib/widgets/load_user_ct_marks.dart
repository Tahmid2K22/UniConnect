/// Utility to extract and format CT marks for visualization and details widgets.
Map<String, dynamic> parseCtMarksFromProfile(
  Map<String, dynamic>? userProfile,
) {
  final ctMarksRaw = userProfile?['ct_marks'] as Map<String, dynamic>? ?? {};
  final Map<String, List<List<num>>> courses = {};

  for (final entry in ctMarksRaw.entries) {
    final key = entry.key; // e.g., "EEE2117_CT1_20"
    final value = entry.value;
    final match = RegExp(r'^(.+)_CT(\d+)_(\d+)$').firstMatch(key);

    if (match == null) continue;

    final courseName = match.group(1)!;
    final totalMark = num.parse(match.group(3)!);

    final obtained = (value as List).isNotEmpty ? value[0] as num : 0;

    // NOTE:
    // We intentionally DO NOT pad missing CT numbers with placeholder
    // entries like [0, total]. That padding was creating extra "empty"
    // bars/rows whenever a new CT appeared with a higher CT number,
    // since all the skipped CTs were back-filled as 0.
    //
    // Instead, we only keep the actual CT records that exist in Firestore.
    // The UI widgets then simply render however many CTs exist for each
    // course.
    courses.putIfAbsent(courseName, () => []);
    courses[courseName]!.add([obtained, totalMark]);
  }

  return {'courses': courses};
}
