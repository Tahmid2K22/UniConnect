class BatchmateCgpaEntry {
  final String roll;
  final String name;
  final String status;
  final List<double>? cgpaList;
  final double? avgCgpa;

  BatchmateCgpaEntry({
    required this.roll,
    required this.name,
    required this.status,
    this.cgpaList,
    this.avgCgpa,
  });
}
