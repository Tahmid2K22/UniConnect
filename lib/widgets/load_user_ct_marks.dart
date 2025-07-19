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
    final ctNumber = int.parse(match.group(2)!); // For ordering
    final totalMark = num.parse(match.group(3)!);

    final obtained = (value as List).isNotEmpty ? value[0] as num : 0;

    courses.putIfAbsent(courseName, () => []);
    // Ensure lists are in correct order. Insert at ctNumber - 1
    while (courses[courseName]!.length < ctNumber) {
      courses[courseName]!.add([0, totalMark]);
    }
    courses[courseName]![ctNumber - 1] = [obtained, totalMark];
  }

  return {'courses': courses};
}
