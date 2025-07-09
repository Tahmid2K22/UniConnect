import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

Future<List<Map<String, dynamic>>> loadTeachers() async {
  final String jsonString = await rootBundle.loadString('assets/teachers.json');
  final data = json.decode(jsonString);
  return List<Map<String, dynamic>>.from(data['teachers']);
}
