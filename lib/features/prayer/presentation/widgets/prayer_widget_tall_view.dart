import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../data/models/prayer_models.dart';
import 'prayer_widget_standard_view.dart';
import 'prayer_widget_state_evaluator.dart';

/// PrayerWidgetTallView — 3-section layout for expanded widget sizes (height ≥ 160dp).
///
/// Section 1 (top bar): [🗓 Hijri date]  •  [📍 City]
/// Section 2 (hero):    [🕌 Icon | Prayer name / Time]  [Countdown badge]
/// Section 3 (strip):   5 prayer station columns
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
        // ── Section 1: Top bar — Hijri date + City ─────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_rounded, size: AppIcon.xs, color: palette.gold),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Text(
                hijriStr.isNotEmpty ? hijriStr : now.year.toString(),
                style: textTheme.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Icon(Icons.location_on_rounded, size: AppIcon.xs, color: prayerColor),
            const SizedBox(width: AppSpace.xxs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 80),
              child: Text(
                cityName,
                style: textTheme.caption.copyWith(
                  fontWeight: FontWeight.w600,
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
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpace.sm,
            AppSpace.xs,
            AppSpace.sm,
            AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: prayerColor.withValues(alpha: 0.08),
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: prayerColor.withValues(alpha: 0.25), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Countdown badge on the left (RTL = end)
              _HeroBadge(
                statusLabel: eval.statusLabel,
                countdown: eval.countdownFormatted,
                bgColor: bannerBgColor,
                borderColor: bannerBorderColor,
                textColor: bannerTextColor,
                countdownColor: palette.text,
              ),

              const SizedBox(width: AppSpace.sm),

              // Prayer name + time fills remaining space (RTL = start side)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      eval.timePillLabel,
                      style: textTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.w900,
                        color: prayerColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpace.sm),

              // Prayer icon medallion
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: prayerColor.withValues(alpha: 0.16),
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(color: prayerColor.withValues(alpha: 0.40), width: 1.2),
                ),
                child: Icon(eval.prayerIcon, color: prayerColor, size: AppIcon.sm),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpace.sm),

        // ── Section 3: 5 Prayer Stations Strip ────────────────────────────
        Row(
          children: AppStrings.prayerOrder.map((name) {
            return WidgetPrayerStation(
              prayerName: name,
              prayerTime: all[name],
              isCurrent: eval.activePrayerName == name,
              isPast: eval.completedPrayerNames.contains(name),
              isInPrayerTime: eval.activePrayerName == name && eval.isInPrayerTime,
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Hero countdown badge used inside the tall view card.
class _HeroBadge extends StatelessWidget {
  final String statusLabel;
  final String countdown;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final Color countdownColor;

  const _HeroBadge({
    required this.statusLabel,
    required this.countdown,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.countdownColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            statusLabel,
            style: textTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              countdown,
              style: textTheme.label.copyWith(
                fontWeight: FontWeight.w900,
                color: countdownColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
