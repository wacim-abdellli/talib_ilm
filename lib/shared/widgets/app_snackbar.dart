import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/app_ui.dart';

enum AppSnackbarType { success, info, error }

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarType type = AppSnackbarType.info,
    Duration? duration,
  }) {
    final theme = Theme.of(context);

    final config = _SnackbarConfig.fromType(type);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: duration ?? AppUi.snackDuration,
          backgroundColor: theme.colorScheme.surface,
          elevation: 4,
          margin: AppUi.snackMargin(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppUi.radiusSMPlus),
          ),
          content: Row(
            children: [
              Icon(
                config.icon,
                size: 18,
                color: config.color,
              ),
              const SizedBox(width: AppUi.gapSM),
              Expanded(
                child: Text(
                  message,
                  style: AppText.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
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
          AppColors.success,
        );
      case AppSnackbarType.error:
        return _SnackbarConfig(
          Icons.error_outline,
          AppColors.error,
        );
      case AppSnackbarType.info:
      return _SnackbarConfig(
          Icons.info_outline,
          AppColors.primary,
        );
    }
  }
}
