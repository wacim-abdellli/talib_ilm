import 'package:flutter/material.dart';

enum AppSnackbarType { success, info, error }

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarType type = AppSnackbarType.info,
    Duration? duration,
  }) {
    final config = _SnackbarConfig.fromType(type);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: duration ?? const Duration(seconds: 2),
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.all(20),
          padding: EdgeInsets.zero,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: config.color.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: config.color.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(config.icon, size: 20, color: config.color),
                const SizedBox(width: 8),
                if (message.length < 40)
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.success);

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.info);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackbarType.error);
}

class _SnackbarConfig {
  final IconData icon;
  final Color color;

  _SnackbarConfig(this.icon, this.color);

  factory _SnackbarConfig.fromType(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return _SnackbarConfig(
          Icons.check_circle_rounded,
          const Color(0xFF00E676),
        );
      case AppSnackbarType.error:
        return _SnackbarConfig(Icons.error_outline, const Color(0xFFFF5252));
      case AppSnackbarType.info:
        return _SnackbarConfig(Icons.info_outline, Colors.white);
    }
  }
}
