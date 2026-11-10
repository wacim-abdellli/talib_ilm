import 'package:flutter/material.dart';
import '../../app/theme/app_palette.dart';

class FadeScaleAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double startScale;

  const FadeScaleAnimation({
    super.key,
    required this.child,
    this.duration = AppMotion.base,
    this.curve = Curves.easeOut,
    this.startScale = 0.98,
  });

  @override
  State<FadeScaleAnimation> createState() => _FadeScaleAnimationState();
}

class _FadeScaleAnimationState extends State<FadeScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _scaleAnimation = Tween<double>(
      begin: widget.startScale,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

/// Fast, silky-smooth section & category switcher for in-page partition tabs.
/// Uses exponential ease-out micro-glide + fade without blocking scroll gestures.
class AppSectionSwitcher extends StatelessWidget {
  final Key sectionKey;
  final Widget child;
  final Duration duration;

  const AppSectionSwitcher({
    super.key,
    required this.sectionKey,
    required this.child,
    this.duration = AppMotion.sectionSwitch,
  });

  static final Animatable<Offset> _slideInTween = Tween<Offset>(
    begin: const Offset(0.0, 0.016),
    end: Offset.zero,
  );

  static final Animatable<double> _scaleInTween = Tween<double>(
    begin: 0.992,
    end: 1.0,
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: AppMotion.fast,
      switchInCurve: AppMotion.easeOut,
      switchOutCurve: AppMotion.easeIn,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: AlignmentDirectional.topStart,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: _slideInTween.animate(animation),
            child: ScaleTransition(
              scale: _scaleInTween.animate(animation),
              child: child,
            ),
          ),
        );
      },
      child: KeyedSubtree(
        key: sectionKey,
        child: RepaintBoundary(child: child),
      ),
    );
  }
}
