import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/app.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../core/services/home_widget_service.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_sheet.dart';

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

class ThemeSelectorSheet extends StatefulWidget {
  const ThemeSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppSheet.show<void>(
      context: context,
      builder: (_) => const ThemeSelectorSheet(),
    );
  }

  @override
  State<ThemeSelectorSheet> createState() => _ThemeSelectorSheetState();
}

class _ThemeSelectorSheetState extends State<ThemeSelectorSheet> {
  WidgetThemeMode _widgetTheme = WidgetThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadWidgetTheme();
  }

  Future<void> _loadWidgetTheme() async {
    final mode = await HomeWidgetService.getThemeMode();
    if (mounted) {
      setState(() => _widgetTheme = mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppSheet(
      titleText: 'المظهر والسمة',
      showCloseButton: true,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Section 1: App Theme ──
            Text(
              'مظهر التطبيق',
              style: textTheme.label.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            ThemeOption(
              icon: Icons.brightness_auto_rounded,
              title: 'تلقائي',
              subtitle: 'حسب إعدادات النظام',
              isSelected: themeService.isSystem,
              onTap: () {
                HapticFeedback.lightImpact();
                themeService.setThemeMode(ThemeMode.system);
                setState(() {});
              },
            ),
            const SizedBox(height: AppSpace.xs),
            ThemeOption(
              icon: Icons.light_mode_rounded,
              title: 'الوضع الفاتح',
              subtitle: 'مظهر فاتح وناصع',
              isSelected: themeService.isLight,
              onTap: () {
                HapticFeedback.lightImpact();
                themeService.setThemeMode(ThemeMode.light);
                setState(() {});
              },
            ),
            const SizedBox(height: AppSpace.xs),
            ThemeOption(
              icon: Icons.dark_mode_rounded,
              title: 'الوضع الداكن',
              subtitle: 'مظهر ليلي مريح للعين',
              isSelected: themeService.isDark,
              onTap: () {
                HapticFeedback.lightImpact();
                themeService.setThemeMode(ThemeMode.dark);
                setState(() {});
              },
            ),

            const SizedBox(height: AppSpace.lg),

            // ── Section 2: Home Screen Widget Theme ──
            Text(
              'مظهر أداة الشاشة الرئيسية',
              style: textTheme.label.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: AppSpace.xxs),
            Text(
              'اختر مظهر بطاقة الصلاة على شاشة هاتفك (داكن أو ناصع البياض)',
              style: textTheme.caption.copyWith(
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                _buildWidgetThemeChip(
                  context: context,
                  label: 'داكن (أسود)',
                  icon: Icons.dark_mode_rounded,
                  mode: WidgetThemeMode.dark,
                ),
                const SizedBox(width: AppSpace.xs),
                _buildWidgetThemeChip(
                  context: context,
                  label: 'فاتح (أبيض)',
                  icon: Icons.light_mode_rounded,
                  mode: WidgetThemeMode.light,
                ),
                const SizedBox(width: AppSpace.xs),
                _buildWidgetThemeChip(
                  context: context,
                  label: 'تلقائي',
                  icon: Icons.brightness_auto_rounded,
                  mode: WidgetThemeMode.auto,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetThemeChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required WidgetThemeMode mode,
  }) {
    final palette = context.palette;
    final textTheme = context.text;
    final isSelected = _widgetTheme == mode;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            HapticFeedback.selectionClick();
            setState(() => _widgetTheme = mode);
            await HomeWidgetService.setThemeMode(mode);
          },
          borderRadius: AppRadius.mdRadius,
          child: Ink(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: AppSpace.sm,
              horizontal: AppSpace.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected ? palette.primarySoft : palette.surfaceMuted,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: isSelected ? palette.primary : palette.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: AppIcon.sm,
                  color: isSelected ? palette.primary : palette.textMuted,
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(
                  label,
                  style: textTheme.caption.copyWith(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? palette.primary : palette.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
