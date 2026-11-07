import 'dart:async';
import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';

/// Scholarly staggered entrance animation for list items and cards.
/// Cascades items line-by-line with a subtle upward translation and smooth fade.
class StaggeredEntrance extends StatefulWidget {
  /// The index position of the item in the list or grid.
  final int index;

  /// The child widget to animate.
  final Widget child;

  /// Optional custom delay before animation starts.
  final Duration? delay;

  /// Optional custom duration of the entrance animation.
  final Duration? duration;

  /// Vertical slide offset in logical pixels. Default is 14.0dp.
  final double slideOffset;

  /// Easing curve for smooth scholarly entrance.
  final Curve curve;

  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.delay,
    this.duration,
    this.slideOffset = 14.0,
    this.curve = AppMotion.easeOut,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? AppMotion.staggerDuration,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(curved);

    _scheduleEntrance();
  }

  void _scheduleEntrance() {
    final effectiveDelay = widget.delay ?? _computeDelay(widget.index);
    if (effectiveDelay == AppMotion.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(effectiveDelay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  static Duration _computeDelay(int index) {
    if (index <= 0) return AppMotion.zero;
    // Beyond 10 items, start without delay to avoid lagging deep scrolls
    if (index >= 10) return AppMotion.zero;

    final ms = index * 28;
    return ms > 240
        ? AppMotion.staggerMaxDelay
        : AppMotion.fromMilliseconds(ms);
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: _slideAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

