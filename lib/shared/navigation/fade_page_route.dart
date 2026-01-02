import 'package:flutter/material.dart';

PageRouteBuilder<T> buildFadeRoute<T>({
  required Widget page,
  Duration duration = const Duration(milliseconds: 180),
}) {
  return PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );
      return FadeTransition(
        opacity: curved,
        child: child,
      );
    },
  );
}
