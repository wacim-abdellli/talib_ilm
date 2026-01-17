import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon: 80 size
            Icon(
              icon,
              size: 80,
              color: isDark
                  ? const Color(0xFF333333)
                  : context.textTertiaryColor,
            ),

            const SizedBox(height: 16),

            // Title: 20sp semi-bold
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : context.textSecondaryColor,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle: 15sp, centered
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? const Color(0xFF666666)
                      : context.textTertiaryColor,
                  height: 1.5,
                ),
              ),
            ),

            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              // Action button
              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: onAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? const Color(0xFF3B9EFF)
                        : const Color(0xFF0D9488),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF3B9EFF)
                          : const Color(0xFF0D9488),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: isDark ? Colors.transparent : null,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
