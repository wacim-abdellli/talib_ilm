import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_colors.dart';

class AdhkarHeader extends StatelessWidget {
  final int streak;
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;

  const AdhkarHeader({
    super.key,
    required this.streak,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  Widget _buildCategoryTab(
    BuildContext context,
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    final activeBg = context.primaryColor;
    const activeText = Colors.white;

    final inactiveBg = context.surfaceColor;
    final inactiveBorder = context.outlineVariantColor;
    final inactiveText = context.textSecondaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(12),
            border: isActive ? null : Border.all(color: inactiveBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? activeText : inactiveText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? activeText : inactiveText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final headerBg = context.surfaceColor;
    final headerGradient = isDark ? AppColors.premiumDarkGradient : null;
    final headerBorder = context.outlineVariantColor;
    final titleColor = context.textPrimaryColor;
    final subtitleColor = context.textSecondaryColor;

    final iconContainerDecoration = BoxDecoration(
      color: context.primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: context.primaryColor.withValues(alpha: 0.25),
        width: 1,
      ),
    );
    final iconColor = context.primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: headerBg,
        gradient: headerGradient,
        border: Border(bottom: BorderSide(color: headerBorder, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: iconContainerDecoration,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الأذكار والأدعية',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'احفظ أذكار اليوم والليلة',
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.goldColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: context.goldColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 16,
                        color: context.goldColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$streak',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.goldColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Category tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildCategoryTab(
                    context,
                    'الكل',
                    Icons.grid_view_rounded,
                    selectedCategory == 'all',
                    () => onSelectCategory('all'),
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryTab(
                    context,
                    'الصباح',
                    Icons.wb_sunny_rounded,
                    selectedCategory == 'morning',
                    () => onSelectCategory('morning'),
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryTab(
                    context,
                    'المساء',
                    Icons.nights_stay_rounded,
                    selectedCategory == 'evening',
                    () => onSelectCategory('evening'),
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryTab(
                    context,
                    'بعد الصلاة',
                    Icons.mosque_outlined,
                    selectedCategory == 'after_prayer',
                    () => onSelectCategory('after_prayer'),
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryTab(
                    context,
                    'متنوعة',
                    Icons.auto_awesome_outlined,
                    selectedCategory == 'misc',
                    () => onSelectCategory('misc'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
