import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/theme_colors.dart';

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
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

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
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: sheetContext.surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: sheetContext.goldColor.withValues(alpha: isDark ? 0.3 : 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 20,
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
                        color: sheetContext.primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sheetContext.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: sheetContext.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: sheetContext.textPrimaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: sheetContext.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!autoDismiss) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: FilledButton.styleFrom(
                            backgroundColor: sheetContext.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            buttonText,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
