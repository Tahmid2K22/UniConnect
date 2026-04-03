// features/calendar/data_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDate(dynamic dateData) {
  if (dateData == null) return DateTime.now();
  if (dateData is DateTime) return dateData;
  if (dateData is Timestamp) return dateData.toDate();
  if (dateData is String) return DateTime.tryParse(dateData) ?? DateTime.now();
  if (dateData is int) return DateTime.fromMillisecondsSinceEpoch(dateData);
  return DateTime.now();
}

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
      startDate: _parseDate(map['startDate']),
      plStart: _parseDate(map['plStart']),
      plEnd: _parseDate(map['plEnd']),
      finalsStart: _parseDate(map['finalsStart']),
      finalsEnd: _parseDate(map['finalsEnd']),
      endDate: _parseDate(map['endDate']),
      vacations:
          (map['vacations'] as List?)
              ?.map((v) => Vacation.fromMap(Map<String, dynamic>.from(v)))
              .toList() ??
          [],
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
      startDate: _parseDate(map['startDate']),
      endDate: _parseDate(map['endDate']),
    );
  }
}
