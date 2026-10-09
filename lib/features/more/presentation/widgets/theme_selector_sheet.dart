import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/app.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';

class ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const ThemeOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.lg),
      color: isSelected ? palette.goldSoft : palette.surface,
      border: Border.all(
        color: isSelected ? palette.gold : palette.border,
        width: isSelected ? 1.5 : 1,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? palette.gold.withValues(alpha: 0.2)
                  : palette.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? palette.gold : palette.textMuted,
              size: AppIcon.md,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
                ),
                Text(
                  subtitle,
                  style: textTheme.caption.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle_rounded,
              color: palette.gold,
              size: AppIcon.lg,
            ),
        ],
      ),
    );
  }
}

class ThemeSelectorSheet extends StatelessWidget {
  const ThemeSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    final palette = context.palette;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => const ThemeSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            Text(
              'اختر المظهر',
              style: textTheme.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.text,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            ThemeOption(
              icon: Icons.brightness_auto_rounded,
              title: 'تلقائي',
              subtitle: 'حسب إعدادات النظام',
              isSelected: themeService.isSystem,
              onTap: () {
                HapticFeedback.lightImpact();
                themeService.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpace.sm),
            ThemeOption(
              icon: Icons.light_mode_rounded,
              title: 'الوضع الفاتح',
              subtitle: 'مظهر فاتح وناصع',
              isSelected: themeService.isLight,
              onTap: () {
                HapticFeedback.lightImpact();
                themeService.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpace.sm),
            ThemeOption(
              icon: Icons.dark_mode_rounded,
              title: 'الوضع الداكن',
              subtitle: 'مظهر ليلي مريح للعين',
              isSelected: themeService.isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                themeService.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpace.md),
          ],
        ),
      ),
    );
  }
}
