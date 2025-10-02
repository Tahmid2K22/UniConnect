// features/calendar/data_models.dart

class Semester {
  final DateTime startDate; // Semester official start
  final DateTime plStart; // Preparatory Leave start
  final DateTime plEnd; // Preparatory Leave end
  final DateTime finalsStart; // Finals start
  final DateTime finalsEnd; // Finals end
  final DateTime endDate; // Semester end (before finals)
  final List<Vacation> vacations;

  Semester({
    required this.startDate,
    required this.plStart,
    required this.plEnd,
    required this.finalsStart,
    required this.finalsEnd,
    required this.endDate,
    required this.vacations,
  });

  // Convert Semester → Map
  Map<String, dynamic> toMap() {
    return {
      'startDate': startDate.toIso8601String(),
      'plStart': plStart.toIso8601String(),
      'plEnd': plEnd.toIso8601String(),
      'finalsStart': finalsStart.toIso8601String(),
      'finalsEnd': finalsEnd.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'vacations': vacations.map((v) => v.toMap()).toList(),
    };
  }

  // Convert Map → Semester
  factory Semester.fromMap(Map<String, dynamic> map) {
    return Semester(
      startDate: DateTime.parse(map['startDate']),
      plStart: DateTime.parse(map['plStart']),
      plEnd: DateTime.parse(map['plEnd']),
      finalsStart: DateTime.parse(map['finalsStart']),
      finalsEnd: DateTime.parse(map['finalsEnd']),
      endDate: DateTime.parse(map['endDate']),
      vacations: (map['vacations'] as List)
          .map((v) => Vacation.fromMap(Map<String, dynamic>.from(v)))
          .toList(),
    );
  }
}

class Vacation {
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  Vacation({
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  // Convert Vacation → Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  // Convert Map → Vacation
  factory Vacation.fromMap(Map<String, dynamic> map) {
    return Vacation(
      name: map['name'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
    );
  }
}
