import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';

class UpNextCard extends StatelessWidget {
  final dynamic nextClass;
  final VoidCallback onTap;
  const UpNextCard({super.key, required this.nextClass, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        child: nextClass == null
            ? const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              )
            : (nextClass.period == 'No more classes' ||
                  nextClass.period == 'No data' ||
                  nextClass.period == 'Error')
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nextClass.data, style: _sectionTextStyle),
                  const SizedBox(height: 6),
                  Text(
                    nextClass.period,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Next Class: ${nextClass.data}",
                    style: _sectionTextStyle,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nextClass.period,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Ends: ${nextClass.endTime}",
                    style: const TextStyle(color: Colors.white38),
                  ),
                ],
              ),
      ),
    );
  }

  static const TextStyle _sectionTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );
}
