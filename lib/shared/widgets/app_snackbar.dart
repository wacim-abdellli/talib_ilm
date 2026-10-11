import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_ui.dart';

enum AppSnackbarType { success, info, error }

/// Luxury, top-floating dynamic pill toast HUD.
/// Positioned cleanly below the status bar, avoiding all bottom navigation
/// bars, cards, and the 3/4 screen dead zone.
class AppSnackbar {
  static OverlayEntry? _currentEntry;
  static _ToastWidgetState? _currentState;

  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarType type = AppSnackbarType.info,
    Duration? duration,
    bool haptic = true,
  }) {
    if (haptic) {
      HapticFeedback.lightImpact();
    }

    // Dismiss existing toast smoothly if one is open
    _currentState?.dismiss();
    _currentEntry?.remove();
    _currentEntry = null;
    _currentState = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      _showFallback(context, message, type, duration);
      return;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        key: UniqueKey(),
        message: message,
        type: type,
        displayDuration: duration ?? AppMotion.toast,
        onStateCreated: (state) => _currentState = state,
        onDismissed: () {
          if (_currentEntry == entry) {
            _currentEntry?.remove();
            _currentEntry = null;
            _currentState = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.success);

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.info);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.error);

  static void showSuccess(BuildContext context, String message) =>
      success(context, message);

  static void showError(BuildContext context, String message) =>
      error(context, message);

  static void showInfo(BuildContext context, String message) =>
      info(context, message);

  static void _showFallback(
    BuildContext context,
    String message,
    AppSnackbarType type,
    Duration? duration,
  ) {
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

    ScaffoldMessenger.maybeOf(context)
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: duration ?? AppMotion.toast,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          padding: EdgeInsets.zero,
          content: Container(
            padding: const EdgeInsets.symmetric(
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
  final Duration displayDuration;
  final ValueChanged<_ToastWidgetState> onStateCreated;
  final VoidCallback onDismissed;

  const _ToastWidget({
    super.key,
    required this.message,
    required this.type,
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
  Timer? _timer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    widget.onStateCreated(this);

    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.65),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward();

    _timer = Timer(widget.displayDuration, () {
      dismiss();
    });
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

    switch (widget.type) {
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

    final topPadding = MediaQuery.paddingOf(context).top + AppSpace.sm;

    return SafeArea(
      top: false,
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Dismissible(
                key: const ValueKey('app_toast_dismissible'),
                direction: DismissDirection.up,
                onDismissed: (_) => dismiss(),
                child: Material(
                  color: Colors.transparent,
                  elevation: 0,
                  child: InkWell(
                    onTap: dismiss,
                    borderRadius: AppRadius.pillRadius,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                      constraints: const BoxConstraints(maxWidth: 440),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.pillRadius,
                        boxShadow: palette.shadow,
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.pillRadius,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              AppSpace.lg,
                              AppSpace.sm,
                              AppSpace.md,
                              AppSpace.sm,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surfaceRaised.withValues(alpha: 0.92),
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(color: borderColor, width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                          Container(
                            width: 32,
                            height: 32,
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
                          const SizedBox(width: AppSpace.md),
                          Flexible(
                            child: Text(
                              widget.message,
                              style: textTheme.label.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
);
  }
}
