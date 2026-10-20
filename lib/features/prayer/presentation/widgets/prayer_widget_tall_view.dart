import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../data/models/prayer_models.dart';
import 'prayer_widget_standard_view.dart';
import 'prayer_widget_state_evaluator.dart';

/// PrayerWidgetTallView - Minimalist, sleek representation of the Prayer Card
/// for expanded Android Home Screen AppWidget sizes (e.g. 4x2, 4x3, 4x4).
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
        // ── 1. Top Bar: Hijri Date on Right, Verified City on Left ──
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
            const SizedBox(width: AppSpace.xs),
            Text(
              cityName,
              style: textTheme.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),

        const SizedBox(height: AppSpace.xs),

        // ── 2. Hero Centerpiece: [Medallion + Title + Time] on Right, [Countdown Badge] on Left ──
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
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
            const SizedBox(width: AppSpace.xs),
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
                  Text(
                    eval.timePillLabel,
                    style: textTheme.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      color: prayerColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Flexible(
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: AppSpace.xxs,
                ),
                decoration: BoxDecoration(
                  color: bannerBgColor,
                  borderRadius: AppRadius.smRadius,
                  border: Border.all(
                    color: bannerBorderColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      eval.statusIcon,
                      size: AppIcon.xs,
                      color: bannerTextColor,
                    ),
                    const SizedBox(width: AppSpace.xxs),
                    Flexible(
                      child: Text(
                        eval.statusLabel,
                        style: textTheme.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: bannerTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpace.xxs),
                    Flexible(
                      child: Text(
                        eval.countdownFormatted,
                        style: textTheme.caption.copyWith(
                          fontWeight: FontWeight.w900,
                          color: palette.text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpace.sm),

        // ── 3. Bottom Row: 5 Daily Prayer Stations Strip ──
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
