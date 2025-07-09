import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

Future<List<Map<String, dynamic>>> loadBatchmates() async {
  final String jsonString = await rootBundle.loadString(
    'assets/batchmates.json',
  );
  final data = json.decode(jsonString);
  return List<Map<String, dynamic>>.from(data['batchmates']);
}
