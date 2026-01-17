import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine color based on mode and label (User Request: Neon in Dark)
    Color effectiveColor = color;
    if (isDark) {
      if (label.contains('المكتبة')) {
        effectiveColor = const Color(0xFF3B9EFF); // Library Blue
      } else if (label.contains('المفضلة')) {
        effectiveColor = const Color(0xFFFF4D9E); // Favorites Pink
      } else if (label.contains('القبلة')) {
        effectiveColor = const Color(0xFF00E676); // Qibla Green
      } else if (label.contains('الأذكار')) {
        effectiveColor = const Color(0xFFA855F7); // Adhkar Purple
      }
    }

    // Styling
    final containerBg = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F1F1F) : AppColors.border;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.6)
        : AppColors.black.withValues(alpha: 0.02);
    final shadowBlur = isDark ? 12.0 : 8.0;
    final textColor = isDark ? const Color(0xFFFFFFFF) : AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: shadowBlur,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: effectiveColor),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
