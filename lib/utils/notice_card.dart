import 'package:flutter/material.dart';
import 'package:uni_connect/utils/glass_card.dart';

// Notice Card for horizontal scroll
class NoticeCard extends StatelessWidget {
  final String title;
  final String desc;
  final String time;
  const NoticeCard({
    super.key,
    required this.title,
    required this.desc,
    required this.time,
  });
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              time,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
