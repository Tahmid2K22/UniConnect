import 'package:flutter/material.dart';
import 'package:uni_connect/utils/glass_card.dart';

// Todo Card for horizontal scroll
class TodoCard extends StatelessWidget {
  final String title;
  final String due;
  const TodoCard({super.key, required this.title, required this.due});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 180,
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
            const SizedBox(height: 6),
            Text(
              "Due: $due",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.chevron_right, color: Colors.white24, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// Gradiant effect animation
class SlideGradientTransform extends GradientTransform {
  final double slidePercent;
  const SlideGradientTransform(this.slidePercent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final double dx = -bounds.width * slidePercent;
    return Matrix4.translationValues(dx, 0, 0);
  }
}
