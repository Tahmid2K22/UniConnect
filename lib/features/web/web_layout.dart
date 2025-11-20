import 'package:flutter/material.dart';
import 'web_navigation_bar.dart';

class WebLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const WebLayout({super.key, required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B22),
      body: Column(
        children: [
          WebNavigationBar(currentRoute: currentRoute),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
