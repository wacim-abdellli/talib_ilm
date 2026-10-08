import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/theme_colors.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Medallion icon container
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 42,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            // Title: Cairo semi-bold
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle: Cairo centered
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 290),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: context.textSecondaryColor,
                  height: 1.6,
                ),
              ),
            ),

            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              // Action button
              SizedBox(
                height: 44,
                child: FilledButton.tonal(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
                    foregroundColor:
                        isDark ? AppColors.primaryLight : AppColors.primaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.2),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                  ),
                  child: Text(
                    actionLabel!,
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
    );
  }
}
