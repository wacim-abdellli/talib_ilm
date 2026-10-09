import 'package:flutter/material.dart';
import '../../app/theme/app_palette.dart';

enum AppSnackbarType { success, info, error }

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarType type = AppSnackbarType.info,
    Duration? duration,
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

    final bottomMargin = AppSize.navClearance(context);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: duration ?? const Duration(seconds: 2),
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, bottomMargin),
          padding: EdgeInsets.zero,
          content: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.md,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceRaised,
              borderRadius: AppRadius.mdRadius,
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
}
