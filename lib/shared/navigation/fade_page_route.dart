import 'package:flutter/material.dart';
import '../../app/theme/app_palette.dart';

PageRouteBuilder<T> buildFadeRoute<T>({
  required Widget page,
  Duration duration = AppMotion.base,
}) {
  return PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeOut,
      );
      final offsetTween = Tween<Offset>(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: curved.drive(offsetTween),
          child: child,
        ),
      );
    },
  );
}
