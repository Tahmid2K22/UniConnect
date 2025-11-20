import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 500, // Typical mobile width
  });

  @override
  Widget build(BuildContext context) {
    // On web, we now use WebLayout for specific pages to handle constraints.
    // We no longer want to force a mobile-like view globally.
    return child;
  }
}
