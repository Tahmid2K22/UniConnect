// nice_page_transition.dart

import 'package:flutter/material.dart';
import 'dart:ui';

class NicePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Curve curve;

  NicePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOutCubic,
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Fade + Slide + Scale + subtle blur for a modern look
           final curved = CurvedAnimation(parent: animation, curve: curve);

           return Stack(
             children: [
               // Subtle background blur during transition
               if (animation.value > 0)
                 BackdropFilter(
                   filter: ImageFilter.blur(
                     sigmaX: 6.0 * animation.value,
                     sigmaY: 6.0 * animation.value,
                   ),
                   child: Container(
                     color: Colors.black.withValues(
                       alpha: 0.04 * animation.value,
                     ),
                   ),
                 ),
               Transform.translate(
                 offset: Offset(0, 40 * (1 - curved.value)),
                 child: Transform.scale(
                   scale: 0.98 + 0.02 * curved.value,
                   child: Opacity(opacity: curved.value, child: child),
                 ),
               ),
             ],
           );
         },
       );
}
