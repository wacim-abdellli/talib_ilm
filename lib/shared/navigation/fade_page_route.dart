import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../app/theme/app_palette.dart';

/// Builds a route with native iOS interactive swipe-to-back gesture support
/// and smooth fade/slide transitions on Android and other platforms.
PageRoute<T> buildFadeRoute<T>({
  required Widget page,
  Duration duration = AppMotion.base,
  RouteSettings? settings,
}) {
  return AppFadePageRoute<T>(
    builder: (context) => page,
    duration: duration,
    settings: settings,
  );
}

/// Custom [PageRoute] mixing in [CupertinoRouteTransitionMixin] so iOS users
/// enjoy the native edge-swipe back gesture ([popGestureEnabled]), while
/// maintaining elegant transitions aligned with the design system.
class AppFadePageRoute<T> extends PageRoute<T>
    with CupertinoRouteTransitionMixin<T> {
  AppFadePageRoute({
    required this.builder,
    this.duration = AppMotion.base,
    super.settings,
  });

  final WidgetBuilder builder;
  final Duration duration;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => duration;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  String? get title => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return CupertinoRouteTransitionMixin.buildPageTransitions<T>(
        this,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
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
  }
}
