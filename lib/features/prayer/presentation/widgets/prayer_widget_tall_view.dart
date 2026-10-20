import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../data/models/prayer_models.dart';
import 'prayer_widget_standard_view.dart';
import 'prayer_widget_state_evaluator.dart';

/// PrayerWidgetTallView - Expanded 3-section layout for large widget sizes (height ≥ 160dp).
///
/// Section 1: Hijri date (right) + City (left)
/// Section 2: Hero prayer card — icon + name + countdown badge, with large prayer time
/// Section 3: 5-prayer horizontal strip
class PrayerWidgetTallView extends StatelessWidget {
  final PrayerTimesDay? prayerDay;
  final EvaluatedPrayerWidgetState eval;
  final Map<String, DateTime> all;
  final Color prayerColor;
  final Color bannerBgColor;
  final Color bannerBorderColor;
  final Color bannerTextColor;
  final DateTime now;

  const PrayerWidgetTallView({
    super.key,
    required this.prayerDay,
    required this.eval,
    required this.all,
    required this.prayerColor,
    required this.bannerBgColor,
    required this.bannerBorderColor,
    required this.bannerTextColor,
    required this.now,
  });

  String _formatHijri(DateTime date) {
    try {
      HijriCalendar.setLocal('ar');
      final h = HijriCalendar.fromDate(date);
      return '${h.hDay} ${h.longMonthName} ${h.hYear} هـ';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final hijriStr = _formatHijri(now);
    final city = prayerDay?.city;
    final cityName = (city != null && city.isNotEmpty) ? city : 'طالب العلم';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Section 1: Hijri date + City ───────────────────────────────────
        Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: AppIcon.xs,
              color: palette.gold,
            ),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Text(
                hijriStr.isNotEmpty ? hijriStr : 'طالب العلم',
                style: textTheme.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Icon(
              Icons.location_on_rounded,
              size: AppIcon.xs,
              color: prayerColor,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                cityName,
                style: textTheme.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpace.sm),

        // ── Section 2: Hero Prayer Card ────────────────────────────────────
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: prayerColor.withValues(alpha: 0.08),
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: prayerColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Prayer icon medallion
              Container(
                width: AppSize.tap * 0.75,
                height: AppSize.tap * 0.75,
                decoration: BoxDecoration(
                  color: prayerColor.withValues(alpha: 0.16),
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: prayerColor.withValues(alpha: 0.40),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  eval.prayerIcon,
                  color: prayerColor,
                  size: AppIcon.sm,
                ),
              ),
              const SizedBox(width: AppSpace.sm),

              // Prayer name + large time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      eval.displayTitle,
                      style: textTheme.label.copyWith(
                        fontWeight: FontWeight.w900,
                        color: palette.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      eval.timePillLabel,
                      style: textTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.w900,
                        color: prayerColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpace.xs),

              // Countdown badge
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: bannerBgColor,
                  borderRadius: AppRadius.smRadius,
                  border: Border.all(
                    color: bannerBorderColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      eval.statusLabel,
                      style: textTheme.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: bannerTextColor,
                      ),
                      maxLines: 1,
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        eval.countdownFormatted,
                        style: textTheme.label.copyWith(
                          fontWeight: FontWeight.w900,
                          color: palette.text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpace.sm),

        // ── Section 3: 5 Prayer Stations Strip ────────────────────────────
        Row(
          children: AppStrings.prayerOrder.map((prayerName) {
            final isCurrent = eval.activePrayerName == prayerName;
            final prayerTime = all[prayerName];
            final isPast = eval.completedPrayerNames.contains(prayerName);

            return WidgetPrayerStation(
              prayerName: prayerName,
              prayerTime: prayerTime,
              isCurrent: isCurrent,
              isPast: isPast,
              isInPrayerTime: isCurrent && eval.isInPrayerTime,
            );
          }).toList(),
        ),
      ],
    );
  }
}
