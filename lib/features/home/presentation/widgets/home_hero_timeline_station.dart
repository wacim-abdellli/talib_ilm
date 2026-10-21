import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../prayer/data/models/prayer_models.dart';

/// Single station pill within the Home Hero 5-prayer journey strip.
class HomeHeroTimelineStation extends StatelessWidget {
  final String prayerName;
  final DateTime? prayerTime;
  final bool isCurrent;
  final bool isPast;
  final bool isInPrayerTime;

  const HomeHeroTimelineStation({
    super.key,
    required this.prayerName,
    required this.prayerTime,
    required this.isCurrent,
    required this.isPast,
    required this.isInPrayerTime,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final pColor = palette.prayer(prayerName);
    final timeStr =
        prayerTime != null ? formatPrayerTime12h(prayerTime!) : '';
    final icon = iconForPrayer(prayerName);

    return Expanded(
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.xs,
          vertical: AppSpace.xs,
        ),
        decoration: isCurrent
            ? BoxDecoration(
                color: palette.surfaceRaised,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: pColor,
                  width: isInPrayerTime ? 1.8 : 1.5,
                ),
                boxShadow: palette.shadow,
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Pip
            if (isCurrent)
              Container(
                width: AppSpace.xs + 1,
                height: AppSpace.xs + 1,
                margin: const EdgeInsets.only(bottom: AppSpace.xs),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pColor,
                ),
              )
            else if (isPast)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpace.xs),
                child: Icon(
                  Icons.check_rounded,
                  size: AppIcon.xs,
                  color: palette.success,
                ),
              )
            else
              Container(
                width: AppSpace.xs,
                height: AppSpace.xs,
                margin: const EdgeInsets.only(bottom: AppSpace.xs),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pColor.withValues(alpha: 0.35),
                ),
              ),

            // Celestial Icon with individual prayer color
            Icon(
              icon,
              size: isCurrent ? AppIcon.md : AppIcon.sm,
              color: isCurrent
                  ? pColor
                  : (isPast
                      ? pColor.withValues(alpha: 0.45)
                      : pColor.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: AppSpace.xs),

            // Prayer Name
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                prayerName,
                style: isCurrent
                    ? textTheme.caption.copyWith(
                        color: pColor,
                        fontWeight: FontWeight.w800,
                      )
                    : textTheme.caption.copyWith(
                        color: isPast ? palette.textMuted : palette.text,
                        fontWeight: FontWeight.w600,
                      ),
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),

            // Prayer Time with Western Arabic numerals (123456)
            if (timeStr.isNotEmpty)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  timeStr,
                  style: isCurrent
                      ? textTheme.caption.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )
                      : textTheme.caption.copyWith(
                          color: isPast ? palette.textSubtle : palette.textMuted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper returning the canonical celestial icon for an Arabic prayer name.
IconData iconForPrayer(String name) {
  final p = name.trim();
  if (p.contains('الجمعة')) {
    return Icons.mosque_rounded;
  }
  if (p.contains(AppStrings.prayerFajr) || p == 'الفجر') {
    return Icons.wb_twilight_rounded;
  }
  if (p == 'الشروق') {
    return Icons.wb_sunny_rounded;
  }
  if (p.contains(AppStrings.prayerDhuhr) || p == 'الظهر') {
    return Icons.wb_sunny_rounded;
  }
  if (p.contains(AppStrings.prayerAsr) || p == 'العصر') {
    return Icons.wb_sunny_outlined;
  }
  if (p.contains(AppStrings.prayerMaghrib) || p == 'المغرب') {
    return Icons.nights_stay_outlined;
  }
  if (p.contains(AppStrings.prayerIsha) || p == 'العشاء') {
    return Icons.bedtime_rounded;
  }
  return Icons.access_time_rounded;
}

/// Colon separator with prayer tone for the digital countdown display.
class CountdownColon extends StatelessWidget {
  final Color color;

  const CountdownColon({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      child: Text(
        ':',
        style: context.text.titleSmall.copyWith(
          fontWeight: FontWeight.w800,
          color: color.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
