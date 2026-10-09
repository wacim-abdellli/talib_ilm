import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_colors.dart';

class CategoryCardData {
  final String id;
  final String title;
  final int total;
  final IconData icon;
  final Color tint;
  final bool showProgress;
  final VoidCallback onTap;

  const CategoryCardData({
    required this.id,
    required this.title,
    required this.total,
    required this.icon,
    required this.tint,
    required this.onTap,
    this.showProgress = false,
  });
}

class CategoryProgress {
  final int completed;
  final int total;

  const CategoryProgress(this.completed, this.total);
}

class CategoryTile extends StatelessWidget {
  final CategoryCardData data;
  final Future<CategoryProgress> Function()? progressLoader;

  const CategoryTile({
    super.key,
    required this.data,
    this.progressLoader,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColors = _getCategoryColors(data.id);
    final accentColor = accentColors[0];
    final tileBg = context.surfaceContainer;
    final textColor = context.textPrimaryColor;
    final subtitleColor = context.textSecondaryColor;

    return Container(
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.25 : 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            data.onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Medallion + Count Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        _getCategoryIcon(data.id),
                        size: 24,
                        color: accentColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _subtitleLabel(data.id, data.total),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  data.title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'عرض الأذكار',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 9,
                      color: subtitleColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getCategoryColors(String id) {
    switch (id) {
      case 'morning':
        return const [AppColors.gold, AppColors.goldDark];
      case 'evening':
        return const [AppColors.categoryLanguage, Color(0xFF2A4860)];
      case 'after_prayer':
        return const [AppColors.primary, AppColors.primaryDark];
      case 'duas':
        return const [AppColors.categoryHadith, Color(0xFF1E683E)];
      case 'tasbeeh':
        return const [AppColors.darkGold, AppColors.gold];
      case 'sleeping':
        return const [Color(0xFF476070), Color(0xFF334652)];
      default:
        return const [AppColors.primary, AppColors.primaryDark];
    }
  }

  IconData _getCategoryIcon(String id) {
    switch (id) {
      case 'morning':
        return Icons.wb_sunny_rounded;
      case 'evening':
        return Icons.nights_stay_rounded;
      case 'after_prayer':
        return Icons.mosque_rounded;
      case 'duas':
        return Icons.menu_book_rounded;
      case 'tasbeeh':
        return Icons.fingerprint_rounded;
      case 'sleeping':
        return Icons.bedtime_rounded;
      default:
        return Icons.auto_stories_rounded;
    }
  }

  String _subtitleLabel(String id, int total) {
    if (id == 'tasbeeh') return 'تسبيح';
    if (id == 'duas') return '$total دعاء';
    return '$total ذكراً';
  }
}
