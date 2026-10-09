import 'package:flutter/material.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/icon_badge.dart';

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
    final palette = context.palette;
    final activeBg = palette.primary;
    final activeText = palette.onPrimary;

    final inactiveBg = palette.surface;
    final inactiveBorder = palette.border;
    final inactiveText = palette.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdRadius,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: isActive ? activeBg : inactiveBg,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: isActive ? palette.primary : inactiveBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppIcon.sm,
                color: isActive ? activeText : inactiveText,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                label,
                style: context.text.label.copyWith(
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
    final palette = context.palette;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpace.xl,
        AppSpace.lg,
        AppSpace.xl,
        AppSpace.lg,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.border, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconBadge(
                  icon: Icons.auto_awesome_rounded,
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الأذكار والأدعية',
                        style: context.text.title.copyWith(
                          color: palette.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'احفظ أذكار اليوم والليلة',
                        style: context.text.bodySmall.copyWith(
                          color: palette.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.goldSoft,
                    borderRadius: AppRadius.smRadius,
                    border: Border.all(
                      color: palette.gold.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: AppIcon.sm,
                        color: palette.gold,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        '$streak',
                        style: context.text.label.copyWith(
                          color: palette.gold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
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
                  const SizedBox(width: AppSpace.sm),
                  _buildCategoryTab(
                    context,
                    'الصباح',
                    Icons.wb_sunny_rounded,
                    selectedCategory == 'morning',
                    () => onSelectCategory('morning'),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _buildCategoryTab(
                    context,
                    'المساء',
                    Icons.nights_stay_rounded,
                    selectedCategory == 'evening',
                    () => onSelectCategory('evening'),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _buildCategoryTab(
                    context,
                    'بعد الصلاة',
                    Icons.mosque_outlined,
                    selectedCategory == 'after_prayer',
                    () => onSelectCategory('after_prayer'),
                  ),
                  const SizedBox(width: AppSpace.sm),
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
