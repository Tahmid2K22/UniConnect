import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches all routine and assignment data from your Google Apps Script endpoint.
/// Expects a JSON structure like:
/// {
///   "sheet1": [ [row1], [row2], ... ],
///   "sheet2": [ [row1], [row2], ... ],
///   "sheet3": [ [row1], [row2], ... ]
/// }
class CollectData {
  static Future<Map<String, List<List<String>>>> collectAllData() async {
    // Replace with your actual Apps Script URL:
    final scriptURL =
        "https://script.google.com/macros/s/AKfycbwV26WyUpb8zgfyWGlepwMP3JS3Vo6YamCIlYaJR03KGtdSDbIeqC80cFITkh04HjZfAQ/exec";
    final response = await http.get(Uri.parse(scriptURL));
    if (response.statusCode == 200) {
      print('Raw response: ${response.body}');
      final data = json.decode(response.body) as Map<String, dynamic>;
      print('Data keys: ${data.keys}');
      return data.map(
        (key, value) => MapEntry(
          key,
          (value as List)
              .map((e) => (e as List).map((cell) => cell.toString()).toList())
              .toList(),
        ),
      );
    } else {
      throw Exception('Failed to load data from Google Apps Script');
    }
  }
}
