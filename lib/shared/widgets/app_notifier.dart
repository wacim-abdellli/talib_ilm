import 'package:flutter/material.dart';
import 'package:talib_ilm/app/theme/app_colors.dart';
import 'package:talib_ilm/app/theme/app_text.dart';
import 'package:talib_ilm/app/theme/app_ui.dart';

class AppNotifier {
  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.info_outline,
    Color? iconColor,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
        margin: const EdgeInsets.all(AppUi.paddingMD),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppUi.radiusMD),
        ),
        content: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
            const SizedBox(width: AppUi.gapSM),
            Expanded(
              child: Text(
                message,
                style: AppText.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
