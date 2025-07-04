import '../models/batchmate_cgpa_entry.dart';

int? getUserCgpaPosition(List<BatchmateCgpaEntry> ranking, String userRoll) {
  final idx = ranking.indexWhere((e) => e.roll == userRoll);
  return idx >= 0 ? idx + 1 : null;
}
