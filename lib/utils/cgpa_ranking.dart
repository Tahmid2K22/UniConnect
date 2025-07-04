import '../models/batchmate_cgpa_entry.dart';

List<BatchmateCgpaEntry> getCgpaRanking(List<Map<String, dynamic>> data) {
  return data
      .where((e) => e['status'] == 'active')
      .map((e) {
        final cgpaList = (e['cgpa_list'] as List?)
            ?.map((v) => (v as num).toDouble())
            .toList();
        final avg = cgpaList != null && cgpaList.isNotEmpty
            ? cgpaList.reduce((a, b) => a + b) / cgpaList.length
            : null;
        return BatchmateCgpaEntry(
          roll: e['roll'],
          name: e['name'],
          status: e['status'],
          cgpaList: cgpaList,
          avgCgpa: avg,
        );
      })
      .where((e) => e.avgCgpa != null)
      .toList()
    ..sort((a, b) => b.avgCgpa!.compareTo(a.avgCgpa!));
}
