import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_ui.dart';
import 'app_button.dart';

class AppPopup {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.check_circle_rounded,
    String buttonText = 'حسناً',
    bool autoDismiss = true,
    Duration dismissAfter = AppMotion.twoSeconds,
    bool haptic = true,
  }) {
    if (haptic) {
      HapticFeedback.lightImpact();
    }

    showDialog<void>(
      context: context,
      barrierColor: context.palette.brandDark.withValues(alpha: 0.50),
      builder: (dialogContext) {
        final palette = dialogContext.palette;
        final textTheme = dialogContext.text;

        if (autoDismiss) {
          Timer(dismissAfter, () {
            if (Navigator.of(dialogContext).canPop()) {
              Navigator.of(dialogContext).pop();
            }
          });
        }

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              margin: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
              padding: const EdgeInsets.all(AppSpace.xl),
              decoration: BoxDecoration(
                color: palette.surfaceRaised,
                borderRadius: AppRadius.xlRadius,
                border: Border.all(color: palette.border, width: 1),
                boxShadow: palette.shadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: palette.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: palette.primary,
                        size: AppIcon.lg,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Text(
                    title,
                    style: textTheme.titleSmall.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    message,
                    style: textTheme.bodySmall.copyWith(
                      color: palette.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!autoDismiss) ...[
                    const SizedBox(height: AppSpace.lg),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: buttonText,
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
