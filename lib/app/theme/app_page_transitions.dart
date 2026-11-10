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
  Duration get transitionDuration => AppMotion.base;

  static final Animatable<Offset> _slideTween = Tween<Offset>(
    begin: const Offset(0.0, 0.024),
    end: Offset.zero,
  );

  static final Animatable<double> _scaleTween = Tween<double>(
    begin: 0.988,
    end: 1.0,
  );

  static final Animatable<double> _secondaryScaleTween = Tween<double>(
    begin: 1.0,
    end: 0.988,
  );

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

    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.easeOut,
      reverseCurve: AppMotion.easeIn,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: _slideTween.animate(curved),
        child: ScaleTransition(
          scale: _scaleTween.animate(curved),
          child: ScaleTransition(
            scale: _secondaryScaleTween.animate(secondaryCurved),
            child: RepaintBoundary(child: child),
          ),
        ),
      ),
    );
  }
}
