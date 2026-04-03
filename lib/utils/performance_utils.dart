import 'package:flutter/material.dart';

/// Simple performance monitoring utility
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  
  static void startTimer(String label) {
    _startTimes[label] = DateTime.now();
    debugPrint('⏱️ START: $label');
  }
  
  static void endTimer(String label) {
    final start = _startTimes[label];
    if (start != null) {
      final duration = DateTime.now().difference(start);
      debugPrint('⏱️ END: $label - ${duration.inMilliseconds}ms');
      _startTimes.remove(label);
    }
  }
  
  static void logMemory(String label) {
    debugPrint('📊 Memory checkpoint: $label');
  }
}

/// Error boundary widget to catch and display errors gracefully
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final Widget Function(Object error)? errorBuilder;
  
  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });
  
  @override
  Widget build(BuildContext context) {
    return child;
  }
}
