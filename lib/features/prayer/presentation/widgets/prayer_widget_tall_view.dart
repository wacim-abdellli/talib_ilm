import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../home/presentation/widgets/home_hero_timeline_station.dart';
import '../../data/models/prayer_models.dart';
import 'prayer_widget_state_evaluator.dart';

/// PrayerWidgetTallView - Rich, scholarly representation of the Prayer Card
/// for expanded / tall Android Home Screen AppWidget sizes (e.g. 4x3, 4x4).
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
    final cityName = (city != null && city.isNotEmpty)
        ? city
        : 'مواقيت الصلاة اليومية';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. Top Bar: Hijri Date on Right, Verified City on Left ──
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xxs + 1,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: AppRadius.smRadius,
            border: Border.all(
              color: palette.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Right (Start in RTL): Calendar & Hijri Date
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: AppIcon.xs,
                      color: palette.gold,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Flexible(
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
                  ],
                ),
              ),

              const SizedBox(width: AppSpace.xs),

              // Left (End in RTL): Verified City / Location
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: AppIcon.xs,
                      color: prayerColor,
                    ),
                    const SizedBox(width: AppSpace.xs),
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
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpace.xs),

        // ── 2. Hero Centerpiece: Prayer Medallion + Title + Time + Countdown ──
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: prayerColor.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Right: Medallion + Title + Primary Time
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: prayerColor.withValues(alpha: 0.16),
                            borderRadius: AppRadius.mdRadius,
                            border: Border.all(
                              color: prayerColor.withValues(alpha: 0.45),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            eval.prayerIcon,
                            color: prayerColor,
                            size: AppIcon.md,
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                eval.displayTitle,
                                style: textTheme.title.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: palette.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                eval.timePillLabel,
                                style: textTheme.label.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: prayerColor,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpace.sm),

                  // Left: Countdown Badge
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
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              eval.statusIcon,
                              size: AppIcon.xs,
                              color: bannerTextColor,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Text(
                              eval.statusLabel,
                              style: textTheme.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: bannerTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            eval.countdownFormatted,
                            style: textTheme.titleSmall.copyWith(
                              fontWeight: FontWeight.w900,
                              color: palette.text,
                              letterSpacing: 1.1,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // SubStatus text if available
              if (eval.subStatusText != null) ...[
                const SizedBox(height: AppSpace.xs),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xxs + 1,
                  ),
                  decoration: BoxDecoration(
                    color: bannerBgColor.withValues(alpha: 0.5),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: Text(
                    eval.subStatusText!,
                    style: textTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: bannerTextColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpace.xs),

        // ── 3. Full 5 Prayer Timeline Strip ──
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpace.xs,
            horizontal: AppSpace.xxs,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: palette.border,
              width: 1,
            ),
          ),
          child: Row(
            children: AppStrings.prayerOrder.map((prayerName) {
              final isCurrent = eval.activePrayerName == prayerName;
              final prayerTime = all[prayerName];
              final isPast = eval.completedPrayerNames.contains(prayerName);

              return _TallPrayerStation(
                prayerName: prayerName,
                prayerTime: prayerTime,
                isCurrent: isCurrent,
                isPast: isPast,
                isInPrayerTime: isCurrent && eval.isInPrayerTime,
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: AppSpace.xs),

        // ── 4. Bottom Islamic Dhikr & Remembrance Bar ──
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xxs + 1,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: AppRadius.smRadius,
            border: Border.all(
              color: palette.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_rounded,
                size: AppIcon.xs,
                color: palette.gold,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
                style: textTheme.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TallPrayerStation extends StatelessWidget {
  final String prayerName;
  final DateTime? prayerTime;
  final bool isCurrent;
  final bool isPast;
  final bool isInPrayerTime;

  const _TallPrayerStation({
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
    final timeStr = prayerTime != null ? formatPrayerTime12h(prayerTime!) : '';
    final icon = iconForPrayer(prayerName);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpace.xxs),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.xxs,
          vertical: AppSpace.xs,
        ),
        decoration: isCurrent
            ? BoxDecoration(
                color: palette.surfaceRaised,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: pColor,
                  width: isInPrayerTime ? 1.8 : 1.4,
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Indicator Pip
            SizedBox(
              height: AppSpace.sm,
              child: Center(
                child: isCurrent
                    ? Container(
                        width: AppSpace.xs + 2,
                        height: AppSpace.xs + 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isInPrayerTime ? palette.success : palette.gold,
                        ),
                      )
                    : isPast
                        ? Icon(
                            Icons.check_rounded,
                            size: AppIcon.xs,
                            color: palette.success,
                          )
                        : Container(
                            width: AppSpace.xs,
                            height: AppSpace.xs,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: pColor.withValues(alpha: 0.35),
                            ),
                          ),
              ),
            ),
            const SizedBox(height: AppSpace.xxs),

            // Prayer Celestial Icon
            Icon(
              icon,
              size: isCurrent ? AppIcon.md : AppIcon.sm,
              color: isCurrent
                  ? pColor
                  : (isPast
                      ? pColor.withValues(alpha: 0.45)
                      : pColor.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: AppSpace.xxs),

            // Prayer Name
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                prayerName,
                style: textTheme.caption.copyWith(
                  fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                  color: isCurrent
                      ? pColor
                      : (isPast ? palette.textMuted : palette.text),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xxs),

            // Prayer Time formatted in 12h
            if (timeStr.isNotEmpty)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  timeStr,
                  softWrap: false,
                  style: textTheme.caption.copyWith(
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                    color: isCurrent
                        ? palette.text
                        : (isPast ? palette.textSubtle : palette.textMuted),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
