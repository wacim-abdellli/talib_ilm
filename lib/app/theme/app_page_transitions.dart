import 'package:flutter/material.dart';

import 'app_palette.dart';

/// RTL-harmonized, micro-elevated page transition builder.
///
/// Designed for Arabic RTL reading flow:
/// - Entering pages gently lift with micro-elevation (3.5% down to zero),
///   subtle scale breathing (0.98 -> 1.0), and smooth opacity fade over
///   [AppMotion.base] using [Curves.easeOutCubic].
/// - Exiting pages subtly settle (1.0 -> 0.98 scale) without abrupt cuts.
/// - Popping back reverses smoothly with [Curves.easeInCubic].
class AppRtlPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppRtlPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.easeOut,
      reverseCurve: AppMotion.easeIn,
    );

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.035),
      end: Offset.zero,
    ).animate(curved);

    final scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(curved);

    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.easeOut,
      reverseCurve: AppMotion.easeIn,
    );
    final secondaryScale = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(secondaryCurved);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: ScaleTransition(
            scale: secondaryScale,
            child: child,
          ),
        ),
      ),
    );
  }
}
