import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class AppPopup {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.check_circle,
    String buttonText = 'حسناً',

    /// NEW
    bool autoDismiss = true,
    Duration dismissAfter = const Duration(seconds: 1),
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
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (sheetContext) {
        if (autoDismiss) {
          Timer(dismissAfter, () {
            if (Navigator.of(sheetContext).canPop()) {
              Navigator.of(sheetContext).pop();
            }
          });
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedScale(
              scale: 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: AppTextStyles.heading3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (!autoDismiss) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(buttonText),
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
