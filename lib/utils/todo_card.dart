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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  "Due: $due",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
