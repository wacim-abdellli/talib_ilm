import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/icon_badge.dart';

class PrayerHeader extends StatelessWidget {
  final String city;
  final String gregorianDate;
  final VoidCallback onOpenLocationSettings;
  final VoidCallback? onOpenPrayerSettings;
  final VoidCallback onOpenQibla;

  const PrayerHeader({
    super.key,
    required this.city,
    required this.gregorianDate,
    required this.onOpenLocationSettings,
    this.onOpenPrayerSettings,
    required this.onOpenQibla,
  });

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
        color: palette.surfaceRaised,
        border: Border(
          bottom: BorderSide(
            color: palette.border,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top row: Title with Mosque badge + Quick Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const IconBadge(icon: Icons.mosque_rounded),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Text(
                          'مواقيت الصلاة',
                          style: context.text.titleSmall.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIconButton(
                      icon: Icons.explore_outlined,
                      tooltip: 'بوصلة القبلة',
                      color: palette.textMuted,
                      onPressed: onOpenQibla,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    AppIconButton(
                      icon: Icons.tune_rounded,
                      tooltip: 'إعدادات الصلاة والتنبيهات',
                      color: palette.textMuted,
                      onPressed: onOpenPrayerSettings ?? onOpenLocationSettings,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),

            // Chips Sub-bar: City Selector Chip + Date Chip
            Row(
              children: [
                // City Selector Chip with dropdown indicator
                Expanded(
                  flex: 3,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onOpenLocationSettings,
                      borderRadius: AppRadius.mdRadius,
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: AppSpace.sm,
                        ),
                        constraints: const BoxConstraints(
                          minHeight: AppSize.tap,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: AppRadius.mdRadius,
                          border: Border.all(
                            color: palette.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: palette.gold,
                              size: AppIcon.sm,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Expanded(
                              child: Text(
                                city,
                                style: context.text.label.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: palette.textSubtle,
                              size: AppIcon.sm,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),

                // Date Chip
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: AppSpace.sm,
                    ),
                    constraints: const BoxConstraints(
                      minHeight: AppSize.tap,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: palette.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: palette.textSubtle,
                          size: AppIcon.sm,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Flexible(
                          child: Text(
                            gregorianDate,
                            style: context.text.label.copyWith(
                              color: palette.text,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
