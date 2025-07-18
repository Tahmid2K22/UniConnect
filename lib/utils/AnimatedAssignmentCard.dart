import 'package:flutter/material.dart';

import 'package:uni_connect/utils/glass_card_2.dart';

// Animation Utils
class AnimatedAssignmentCard extends StatefulWidget {
  final int index;
  final String title;
  final String description;

  const AnimatedAssignmentCard({
    super.key,
    required this.index,
    required this.title,
    required this.description,
  });

  @override
  State<AnimatedAssignmentCard> createState() => _AnimatedAssignmentCardState();
}

class _AnimatedAssignmentCardState extends State<AnimatedAssignmentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 550 + widget.index * 70),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slide = Tween<Offset>(
      begin: Offset(0, 0.15 + 0.08 * (widget.index % 2 == 0 ? 1 : -1)),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 80 * widget.index), () {
        if (mounted) _controller.forward();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GlassCard(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.cyanAccent.withValues(alpha: 0.15),
              child: Icon(Icons.assignment, color: Colors.cyanAccent),
            ),
            title: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                widget.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
