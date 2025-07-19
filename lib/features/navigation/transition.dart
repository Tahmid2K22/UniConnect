import 'package:flutter/material.dart';

class NicePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Curve curve;

  NicePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.fastOutSlowIn,
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curved = CurvedAnimation(parent: animation, curve: curve);

           return FadeTransition(
             opacity: curved,
             child: SlideTransition(
               position: Tween<Offset>(
                 begin: const Offset(0.05, 0),
                 end: Offset.zero,
               ).animate(curved),
               child: child,
             ),
           );
         },
       );
}
