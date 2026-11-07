import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../app/theme/app_palette.dart';

/// Ultra-smooth Circular Reveal Theme Transition System.
/// Implements the Telegram / @moza.flutter circular wave transition:
/// - [ThemeProvider] at the app root
/// - [ThemeSwitchingArea] around the screen
/// - [ThemeSwitcher] around the toggle button / action
class ThemeProvider extends StatefulWidget {
  final ThemeData initTheme;
  final Duration duration;
  final Widget Function(BuildContext context, ThemeData theme)? builder;
  final Widget? child;

  const ThemeProvider({
    super.key,
    required this.initTheme,
    this.duration = AppMotion.themeReveal,
    this.builder,
    this.child,
  }) : assert(builder != null || child != null);

  @override
  State<ThemeProvider> createState() => _ThemeProviderState();
}

class _ThemeProviderState extends State<ThemeProvider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late ThemeData _currentTheme;
  ui.Image? _screenshot;
  Offset _switcherOffset = Offset.zero;
  bool _isReversed = false;
  final GlobalKey _previewKey = GlobalKey();
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initTheme;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void didUpdateWidget(ThemeProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _screenshot?.dispose();
    _screenshot = null;
    super.dispose();
  }

  Future<void> changeTheme({
    required ThemeData theme,
    required GlobalKey key,
    bool isReversed = false,
    Offset? offset,
    VoidCallback? onAnimationFinish,
  }) async {
    if (!mounted || _isTransitioning || _controller.isAnimating) return;
    _isTransitioning = true;

    // 1. Calculate focal point from switcher button
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final localCenter = offset ??
          Offset(renderBox.size.width / 2, renderBox.size.height / 2);
      _switcherOffset = renderBox.localToGlobal(localCenter);
    } else {
      _switcherOffset = offset ?? Offset.zero;
    }

    // 2. Capture screenshot of current screen at 1.0 pixel ratio (< 4ms, zero GPU stall)
    try {
      final boundary = _previewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        _screenshot?.dispose();
        _screenshot = await boundary.toImage(pixelRatio: 1.0);
      }
    } catch (_) {
      _screenshot = null;
    }

    _currentTheme = theme;
    _isReversed = isReversed;

    if (!mounted) {
      _screenshot?.dispose();
      _screenshot = null;
      _isTransitioning = false;
      return;
    }

    // Update state to render the new theme under the screenshot
    setState(() {});

    // Allow one frame for the new theme to rasterize cleanly
    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) {
      _screenshot?.dispose();
      _screenshot = null;
      _isTransitioning = false;
      return;
    }

    if (_isReversed) {
      await _controller.reverse(from: 1.0);
    } else {
      await _controller.forward(from: 0.0);
    }

    _screenshot?.dispose();
    _screenshot = null;
    _isTransitioning = false;

    if (mounted) {
      setState(() {});
    }

    onAnimationFinish?.call();
  }

  @override
  Widget build(BuildContext context) {
    return _ThemeInheritedNotifier(
      state: this,
      currentTheme: _currentTheme,
      screenshot: _screenshot,
      switcherOffset: _switcherOffset,
      isReversed: _isReversed,
      animation: _animation,
      isAnimating: _controller.isAnimating || _isTransitioning,
      child: RepaintBoundary(
        key: _previewKey,
        child: widget.builder != null
            ? Builder(
                builder: (context) =>
                    widget.builder!(context, _currentTheme),
              )
            : widget.child!,
      ),
    );
  }
}

class _ThemeInheritedNotifier extends InheritedWidget {
  final _ThemeProviderState state;
  final ThemeData currentTheme;
  final ui.Image? screenshot;
  final Offset switcherOffset;
  final bool isReversed;
  final Animation<double> animation;
  final bool isAnimating;

  const _ThemeInheritedNotifier({
    required this.state,
    required this.currentTheme,
    required this.screenshot,
    required this.switcherOffset,
    required this.isReversed,
    required this.animation,
    required this.isAnimating,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ThemeInheritedNotifier oldWidget) {
    return currentTheme != oldWidget.currentTheme ||
        screenshot != oldWidget.screenshot ||
        isAnimating != oldWidget.isAnimating;
  }
}

/// Wraps the application screen or body where the circular reveal wave is displayed.
class ThemeSwitchingArea extends StatelessWidget {
  final Widget child;

  const ThemeSwitchingArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final notifier =
        context.dependOnInheritedWidgetOfExactType<_ThemeInheritedNotifier>();

    if (notifier == null ||
        !notifier.isAnimating ||
        notifier.screenshot == null) {
      return child;
    }

    final screenshot = notifier.screenshot!;
    final animation = notifier.animation;
    final center = notifier.switcherOffset;

    Widget bottomLayer;
    Widget topLayer;

    if (notifier.isReversed) {
      // REVERSE MODE (e.g. Dark to Light):
      // The new light theme is rendered on bottom.
      // The old dark screenshot is on top, shrinking into the moon button!
      bottomLayer = RepaintBoundary(child: child);
      topLayer = RepaintBoundary(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return ClipPath(
              clipper: CircularRevealClipper(
                center: center,
                fraction: animation.value,
              ),
              child: RawImage(
                image: screenshot,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            );
          },
        ),
      );
    } else {
      // FORWARD MODE (e.g. Light to Dark):
      // The old light screenshot is on bottom.
      // The new dark theme is on top, expanding out from the button!
      bottomLayer = RepaintBoundary(
        child: RawImage(
          image: screenshot,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
      topLayer = RepaintBoundary(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return ClipPath(
              clipper: CircularRevealClipper(
                center: center,
                fraction: animation.value,
              ),
              child: child,
            );
          },
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        bottomLayer,
        topLayer,
      ],
    );
  }
}

/// The circular clip path that expands or shrinks centered at [center].
class CircularRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double fraction;

  const CircularRevealClipper({
    required this.center,
    required this.fraction,
  });

  @override
  Path getClip(Size size) {
    final clamped = fraction.clamp(0.0, 1.0);
    if (clamped <= 0.0) return Path();
    if (clamped >= 1.0) {
      return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    final w = max(center.dx, size.width - center.dx);
    final h = max(center.dy, size.height - center.dy);
    final maxRadius = sqrt(w * w + h * h);
    final radius = maxRadius * clamped;

    return Path()
      ..addOval(
        Rect.fromCircle(center: center, radius: radius),
      );
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) {
    return oldClipper.fraction != fraction || oldClipper.center != center;
  }
}

/// Wraps any button or tap area to provide coordinates for the circular wave.
class ThemeSwitcher extends StatefulWidget {
  final Widget Function(BuildContext context) builder;

  const ThemeSwitcher({super.key, required this.builder});

  @override
  State<ThemeSwitcher> createState() => ThemeSwitcherState();

  static ThemeSwitcherState of(BuildContext context) {
    final state = context.findAncestorStateOfType<ThemeSwitcherState>();
    assert(state != null,
        'ThemeSwitcher.of() called with a context that does not contain a ThemeSwitcher.');
    return state!;
  }
}

class ThemeSwitcherState extends State<ThemeSwitcher> {
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: Builder(builder: widget.builder),
    );
  }

  void changeTheme({
    required ThemeData theme,
    bool isReversed = false,
    Offset? offset,
    VoidCallback? onAnimationFinish,
  }) {
    final notifier =
        context.dependOnInheritedWidgetOfExactType<_ThemeInheritedNotifier>();
    if (notifier == null) return;

    notifier.state.changeTheme(
      theme: theme,
      key: _key,
      isReversed: isReversed,
      offset: offset,
      onAnimationFinish: onAnimationFinish,
    );
  }
}
