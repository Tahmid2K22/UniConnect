import 'package:flutter/material.dart';
import '../utils/glass_card.dart';

class ExamPreviewList extends StatelessWidget {
  final List<Map<String, dynamic>> exams;
  final VoidCallback onTap;
  const ExamPreviewList({super.key, required this.exams, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return const Text('No exams found.');
    }
    return Column(
      children: exams.map((exam) {
        return GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            child: GlassCard(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    exam['date'],
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
