import 'package:flutter/material.dart';
import 'glass_card.dart';

class NoticePreviewList extends StatelessWidget {
  final List<Map<String, dynamic>> notices;
  final VoidCallback onTap;
  const NoticePreviewList({
    super.key,
    required this.notices,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (notices.isEmpty) {
      return const Text('No notices found.');
    }
    return Column(
      children: notices.map((notice) {
        return GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            child: GlassCard(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice["data"]["title"],
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notice["data"]["desc"],
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notice["data"]["time"],
                    style: const TextStyle(color: Colors.white30, fontSize: 11),
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
