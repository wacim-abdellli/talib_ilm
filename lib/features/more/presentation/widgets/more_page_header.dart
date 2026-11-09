import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/animations/theme_switcher.dart';

class MorePageHeader extends StatelessWidget {
  final int streak;
  final int minutesToday;
  final VoidCallback onThemeLongPress;

  const MorePageHeader({
    super.key,
    required this.streak,
    required this.minutesToday,
    required this.onThemeLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.surfaceRaised,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: palette.gold.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: palette.shadow,
                ),
                padding: const EdgeInsets.all(AppSpace.xs),
                child: ClipRRect(
                  borderRadius: AppRadius.smRadius,
                  child: Image.asset(
                    palette.logoSymbol,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.settings_suggest_rounded,
                      color: palette.gold,
                      size: AppIcon.lg,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإعدادات والمزيد',
                      style: textTheme.title.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs / 2),
                    Text(
                      'طالب علم • سائر في الطلب 🌿',
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              ThemeSwitcher(
                builder: (switcherContext) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        final isDark = themeService.isDark;
                        final nextMode = isDark
                            ? ThemeMode.light
                            : ThemeMode.dark;
                        final nextTheme = nextMode == ThemeMode.dark
                            ? AppTheme.darkTheme
                            : AppTheme.lightTheme;
                        ThemeSwitcher.of(switcherContext).changeTheme(
                          theme: nextTheme,
                          isReversed: isDark,
                          onAnimationFinish: () {
                            themeService.setThemeMode(nextMode);
                          },
                        );
                      },
                      onLongPress: () => onThemeLongPress(),
                      borderRadius: AppRadius.pillRadius,
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.md,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(color: palette.border, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              themeService.themeIcon,
                              size: AppIcon.sm,
                              color: palette.gold,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Text(
                              themeService.themeDisplayName,
                              style: textTheme.caption.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpace.md),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: palette.border, width: 1),
            ),
            child: Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: AppIcon.sm,
                      color: palette.gold,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      '$streak أيام تتابع',
                      style: textTheme.caption.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(width: 1, height: 14, color: palette.border),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: AppIcon.sm,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      '$minutesToday دقيقة تعلّم اليوم',
                      style: textTheme.caption.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
