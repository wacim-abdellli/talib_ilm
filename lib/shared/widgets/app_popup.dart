import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_palette.dart';
import 'app_button.dart';

class AppPopup {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.check_circle_rounded,
    String buttonText = 'حسناً',
    bool autoDismiss = true,
    Duration dismissAfter = const Duration(seconds: 2),
    bool haptic = true,
  }) {
    if (haptic) {
      HapticFeedback.lightImpact();
    }

    // Prevent stacking multiple popups
    Navigator.of(context).popUntil((route) => route.isFirst);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (sheetContext) {
        final palette = sheetContext.palette;
        final textTheme = sheetContext.text;

        if (autoDismiss) {
          Timer(dismissAfter, () {
            if (Navigator.of(sheetContext).canPop()) {
              Navigator.of(sheetContext).pop();
            }
          });
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: AnimatedScale(
              scale: 1,
              duration: AppMotion.fast,
              curve: AppMotion.easeOut,
              child: Container(
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
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: palette.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: palette.onPrimarySoft,
                          size: AppIcon.xl,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Text(
                      title,
                      style: textTheme.titleSmall.copyWith(color: palette.text),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      message,
                      style: textTheme.bodySmall.copyWith(color: palette.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    if (!autoDismiss) ...[
                      const SizedBox(height: AppSpace.xl),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: buttonText,
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
