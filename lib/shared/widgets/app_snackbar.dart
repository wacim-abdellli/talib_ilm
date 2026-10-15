import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_ui.dart';

enum AppSnackbarType { success, info, error }

/// Luxury, bottom-floating dynamic pill toast HUD.
/// Positioned snugly down near the bottom edge/above the navigation bar,
/// with instant in-place updates, zero bounce-back lag, and clean dismissals.
class AppSnackbar {
  static OverlayEntry? _currentEntry;
  static _ToastWidgetState? _currentState;

  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarType type = AppSnackbarType.info,
    Duration? duration,
    bool haptic = true,
    bool hasNavBar = true,
    double? bottomMargin,
  }) {
    if (haptic) {
      HapticFeedback.lightImpact();
    }

    final displayDuration = duration ?? AppMotion.toastShort;

    // If an existing toast is currently active and mounted, update its content in-place.
    // This gives an instant, lag-free response with ZERO flicker, double-popups, or delays.
    if (_currentState != null && _currentState!.mounted) {
      _currentState!.update(
        message: message,
        type: type,
        duration: displayDuration,
      );
      return;
    }

    // Dismiss any previous entry cleanly and immediately
    _dismissCurrent();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      _showFallback(
        context,
        message,
        type,
        displayDuration,
        hasNavBar: hasNavBar,
        bottomMargin: bottomMargin,
      );
      return;
    }

    // Calculate ergonomic bottom placement down near the screen bottom
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final effectiveBottomMargin = bottomMargin ??
        (keyboardInset > 0
            ? keyboardInset + AppSpace.md
            : (hasNavBar
                ? (bottomInset > 0 ? bottomInset : AppSpace.xs) +
                    AppSize.navH +
                    AppSpace.xs
                : (bottomInset > 0 ? bottomInset : AppSpace.md) +
                    AppSpace.sm));

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        key: UniqueKey(),
        message: message,
        type: type,
        bottomMargin: effectiveBottomMargin,
        displayDuration: displayDuration,
        onStateCreated: (state) => _currentState = state,
        onDismissed: () {
          if (_currentEntry == entry) {
            _dismissCurrent();
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void _dismissCurrent() {
    try {
      _currentState?.dismissImmediate();
      _currentEntry?.remove();
    } catch (_) {}
    _currentEntry = null;
    _currentState = null;
  }

  /// Immediately dismiss any currently active toast across the app
  static void dismiss() {
    _dismissCurrent();
  }

  static void success(
    BuildContext context,
    String message, {
    Duration? duration,
    bool hasNavBar = true,
    double? bottomMargin,
  }) =>
      show(
        context,
        message: message,
        type: AppSnackbarType.success,
        duration: duration,
        hasNavBar: hasNavBar,
        bottomMargin: bottomMargin,
      );

  static void info(
    BuildContext context,
    String message, {
    Duration? duration,
    bool hasNavBar = true,
    double? bottomMargin,
  }) =>
      show(
        context,
        message: message,
        type: AppSnackbarType.info,
        duration: duration,
        hasNavBar: hasNavBar,
        bottomMargin: bottomMargin,
      );

  static void error(
    BuildContext context,
    String message, {
    Duration? duration,
    bool hasNavBar = true,
    double? bottomMargin,
  }) =>
      show(
        context,
        message: message,
        type: AppSnackbarType.error,
        duration: duration,
        hasNavBar: hasNavBar,
        bottomMargin: bottomMargin,
      );

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
    bool hasNavBar = true,
    double? bottomMargin,
  }) =>
      success(
        context,
        message,
        duration: duration,
        hasNavBar: hasNavBar,
        bottomMargin: bottomMargin,
      );

  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
    bool hasNavBar = true,
    double? bottomMargin,
  }) =>
      error(
        context,
        message,
        duration: duration,
        hasNavBar: hasNavBar,
        bottomMargin: bottomMargin,
      );

  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    bool hasNavBar = true,
    double? bottomMargin,
  }) =>
      info(
        context,
        message,
        duration: duration,
        hasNavBar: hasNavBar,
        bottomMargin: bottomMargin,
      );

  static void _showFallback(
    BuildContext context,
    String message,
    AppSnackbarType type,
    Duration duration, {
    bool hasNavBar = true,
    double? bottomMargin,
  }) {
    final palette = context.palette;
    final textTheme = context.text;

    Color iconColor;
    IconData icon;
    switch (type) {
      case AppSnackbarType.success:
        iconColor = palette.success;
        icon = Icons.check_circle_rounded;
        break;
      case AppSnackbarType.info:
        iconColor = palette.primary;
        icon = Icons.info_rounded;
        break;
      case AppSnackbarType.error:
        iconColor = palette.error;
        icon = Icons.error_rounded;
        break;
    }

    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final effectiveBottomMargin = bottomMargin ??
        (keyboardInset > 0
            ? keyboardInset + AppSpace.md
            : (hasNavBar
                ? (bottomInset > 0 ? bottomInset : AppSpace.xs) +
                    AppSize.navH +
                    AppSpace.xs
                : (bottomInset > 0 ? bottomInset : AppSpace.md) +
                    AppSpace.sm));

    ScaffoldMessenger.maybeOf(context)
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: duration,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsetsDirectional.only(
            bottom: effectiveBottomMargin,
            start: AppSpace.lg,
            end: AppSpace.lg,
          ),
          padding: EdgeInsets.zero,
          content: Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.md,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceRaised,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(color: palette.border, width: 1),
              boxShadow: palette.shadow,
            ),
            child: Row(
              children: [
                Icon(icon, size: AppIcon.md, color: iconColor),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    message,
                    style: textTheme.bodySmall.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final AppSnackbarType type;
  final double bottomMargin;
  final Duration displayDuration;
  final ValueChanged<_ToastWidgetState> onStateCreated;
  final VoidCallback onDismissed;

  const _ToastWidget({
    super.key,
    required this.message,
    required this.type,
    required this.bottomMargin,
    required this.displayDuration,
    required this.onStateCreated,
    required this.onDismissed,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late String _message;
  late AppSnackbarType _type;
  Timer? _timer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _message = widget.message;
    _type = widget.type;
    widget.onStateCreated(this);

    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.base,
      reverseDuration: AppMotion.toastDismiss,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _controller.forward();

    _timer = Timer(widget.displayDuration, dismiss);
  }

  void update({
    required String message,
    required AppSnackbarType type,
    required Duration duration,
  }) {
    if (!mounted) return;
    _timer?.cancel();
    setState(() {
      _message = message;
      _type = type;
    });

    if (_isDismissing) {
      _isDismissing = false;
      _controller.forward();
    }

    _timer = Timer(duration, dismiss);
  }

  void dismissImmediate() {
    _timer?.cancel();
    _isDismissing = true;
    _controller.stop();
  }

  void dismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    _timer?.cancel();

    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    Color iconColor;
    Color badgeColor;
    Color borderColor;
    IconData icon;

    switch (_type) {
      case AppSnackbarType.success:
        iconColor = palette.success;
        badgeColor = palette.success.withValues(alpha: 0.15);
        borderColor = palette.success.withValues(alpha: 0.35);
        icon = Icons.check_circle_rounded;
        break;
      case AppSnackbarType.info:
        iconColor = palette.primary;
        badgeColor = palette.primary.withValues(alpha: 0.15);
        borderColor = palette.gold.withValues(alpha: 0.35);
        icon = Icons.info_rounded;
        break;
      case AppSnackbarType.error:
        iconColor = palette.error;
        badgeColor = palette.error.withValues(alpha: 0.15);
        borderColor = palette.error.withValues(alpha: 0.35);
        icon = Icons.error_rounded;
        break;
    }

    return SafeArea(
      top: false,
      bottom: false,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsetsDirectional.only(bottom: widget.bottomMargin),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Dismissible(
                  key: const ValueKey('app_toast_dismissible'),
                  direction: DismissDirection.down,
                  onDismissed: (_) => dismiss(),
                  child: Material(
                    color: Colors.transparent,
                    elevation: 0,
                    child: Container(
                      margin: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.lg,
                      ),
                      constraints: const BoxConstraints(maxWidth: 440),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.pillRadius,
                        boxShadow: palette.shadow,
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.pillRadius,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Material(
                            color: palette.surfaceRaised.withValues(alpha: 0.94),
                            child: InkWell(
                              onTap: dismiss,
                              child: Container(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                  AppSpace.md,
                                  AppSpace.sm,
                                  AppSpace.md,
                                  AppSpace.sm,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.pillRadius,
                                  border: Border.all(
                                    color: borderColor,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: badgeColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          icon,
                                          size: AppIcon.sm,
                                          color: iconColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpace.sm),
                                    Flexible(
                                      child: AnimatedSwitcher(
                                        duration: AppMotion.fast,
                                        child: Text(
                                          _message,
                                          key: ValueKey<String>(_message),
                                          style: textTheme.label.copyWith(
                                            color: palette.text,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpace.xs),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
