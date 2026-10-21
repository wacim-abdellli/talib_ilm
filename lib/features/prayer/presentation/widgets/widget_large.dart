import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../data/models/prayer_models.dart';
import 'prayer_widget_state_evaluator.dart';
import 'widget_shared_components.dart';

const double kLargeW = 360.0;
const double kLargeH = 240.0;
const double kLargePadH = AppSpace.md; // 12dp
const double kLargePadV = AppSpace.md; // 12dp
const double kLargeBorder = 1.0;
const double kLargeContent =
    kLargeW - (kLargePadH * 2) - (kLargeBorder * 2); // 334dp

/// Large widget (4×3) — 360×240dp fixed canvas.
/// Designed to match the app's flagship HomeHeroCard (Pic 2):
///  1. Top Bar: [City Name] • [Hijri Date]
///  2. Header: [Medallion + Prayer Name] on Start, [Adhan Time Pill] on End
///  3. Horizon Countdown Banner: [Pulse Dot + Status] on Start, [HH : MM : SS Box] on End
///  4. Journey Strip: 5 Daily Prayers with celestial icons and active station highlight
class WidgetLarge extends StatelessWidget {
  final EvaluatedPrayerWidgetState eval;
  final Map<String, DateTime> all;
  final String hijriDate;
  final String cityName;
  final bool isDark;

  const WidgetLarge({
    super.key,
    required this.eval,
    required this.all,
    required this.hijriDate,
    required this.cityName,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: WidgetCard(
        width: kLargeW,
        height: kLargeH,
        isDark: isDark,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: kLargePadH,
          vertical: AppSpace.sm,
        ),
        child: Builder(
          builder: (ctx) {
            final palette = ctx.palette;
            final textTheme = ctx.text;
            final prayerColor = palette.prayer(eval.activePrayerName);
            final pIcon = iconForPrayer(eval.activePrayerName);

            // Precision countdown parts matching Pic 2 [HH : MM : SS]
            final parts = eval.countdownFormatted.split(':');
            final hours = parts.isNotEmpty ? parts[0] : '00';
            final minutes = parts.length > 1 ? parts[1] : '00';
            final seconds = parts.length > 2 ? parts[2] : '00';

            return Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── 1. Top Bar: [City Name] • [Hijri Date] ──
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: AppIcon.xs,
                            color: palette.gold,
                          ),
                          const SizedBox(width: AppSpace.xxs),
                          Flexible(
                            child: Text(
                              cityName,
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: AppIcon.xs,
                            color: palette.gold,
                          ),
                          const SizedBox(width: AppSpace.xxs),
                          Flexible(
                            child: Text(
                              hijriDate,
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                                fontWeight: FontWeight.w600,
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

                // ── 2. Header: [Medallion + Prayer Name] (Right) | [Time Jewel Pill] (Left) ──
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Start (Right): Icon Medallion + Large Prayer Title
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: AppSpace.xl + AppSpace.sm, // 36dp
                            height: AppSpace.xl + AppSpace.sm,
                            decoration: BoxDecoration(
                              color: prayerColor.withValues(alpha: 0.16),
                              borderRadius: AppRadius.mdRadius,
                              border: Border.all(
                                color: prayerColor.withValues(alpha: 0.40),
                                width: 1.2,
                              ),
                            ),
                            child: Icon(
                              pIcon,
                              color: prayerColor,
                              size: AppIcon.sm,
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Expanded(
                            child: Text(
                              'صلاة ${eval.activePrayerName}',
                              style: textTheme.titleSmall.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),

                    // End (Left): Adhan Time Jewel Pill
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.xxs + 1,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(
                          color: prayerColor.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              eval.timePillLabel,
                              style: textTheme.caption.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpace.xxs),
                          Icon(
                            Icons.access_time_rounded,
                            size: AppIcon.xs,
                            color: prayerColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── 3. Countdown Banner: [Pulse Dot + Status] (Right) | [HH : MM : SS Box] (Left) ──
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xxs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: prayerColor.withValues(alpha: 0.10),
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(
                      color: prayerColor.withValues(alpha: 0.28),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Start (Right): Status indicator with pulse dot
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: AppSpace.xs + 2,
                              height: AppSpace.xs + 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: prayerColor,
                              ),
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Flexible(
                              child: Text(
                                eval.statusLabel,
                                style: textTheme.caption.copyWith(
                                  color: prayerColor,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),

                      // End (Left): Digital Precision Countdown Clock
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: AppSpace.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceRaised,
                          borderRadius: AppRadius.smRadius,
                          border: Border.all(
                            color: prayerColor.withValues(alpha: 0.40),
                            width: 1.2,
                          ),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                hours,
                                style: textTheme.label.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: palette.text,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                              Text(
                                ' : ',
                                style: textTheme.label.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: prayerColor,
                                ),
                              ),
                              Text(
                                minutes,
                                style: textTheme.label.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: palette.text,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                              Text(
                                ' : ',
                                style: textTheme.label.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: prayerColor,
                                ),
                              ),
                              Text(
                                seconds,
                                style: textTheme.label.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: prayerColor,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── 4. Bottom: 5 Daily Prayers Journey Strip with Authentic Celestial Icons ──
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.xs,
                    vertical: AppSpace.xxs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.lgRadius,
                    border: Border.all(
                      color: palette.border,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: AppStrings.prayerOrder.map((name) {
                      final isCurrent = eval.activePrayerName == name;
                      final isPast = eval.completedPrayerNames.contains(name);
                      final pCol = palette.prayer(name);
                      final pTime = all[name];
                      final timeStr =
                          pTime != null ? formatPrayerTime12h(pTime) : '--:--';
                      final stationIcon = iconForPrayer(name);

                      return Expanded(
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.xxs,
                            vertical: AppSpace.xxs + 1,
                          ),
                          decoration: isCurrent
                              ? BoxDecoration(
                                  color: palette.surfaceRaised,
                                  borderRadius: AppRadius.smRadius,
                                  border: Border.all(
                                    color: palette.gold,
                                    width: 1.5,
                                  ),
                                )
                              : null,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Pip indicator
                              if (isCurrent)
                                Container(
                                  width: AppSpace.xs + 1,
                                  height: AppSpace.xs + 1,
                                  margin: const EdgeInsetsDirectional.only(
                                    bottom: AppSpace.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: palette.gold,
                                  ),
                                )
                              else if (isPast)
                                Container(
                                  margin: const EdgeInsetsDirectional.only(
                                    bottom: AppSpace.xxs,
                                  ),
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
                                  margin: const EdgeInsetsDirectional.only(
                                    bottom: AppSpace.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: pCol.withValues(alpha: 0.35),
                                  ),
                                ),

                              // Celestial Icon
                              Icon(
                                stationIcon,
                                size: isCurrent ? AppIcon.sm : AppIcon.xs,
                                color: isCurrent
                                    ? palette.gold
                                    : (isPast
                                        ? pCol.withValues(alpha: 0.45)
                                        : pCol.withValues(alpha: 0.85)),
                              ),
                              const SizedBox(height: AppSpace.xxs),

                              // Prayer Name
                              Text(
                                name,
                                style: textTheme.caption.copyWith(
                                  color: isCurrent
                                      ? palette.gold
                                      : (isPast
                                          ? palette.textMuted
                                          : palette.text),
                                  fontWeight: isCurrent
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpace.xxs),

                              // Prayer Time
                              Text(
                                timeStr,
                                style: textTheme.caption.copyWith(
                                  color: isCurrent
                                      ? palette.text
                                      : (isPast
                                          ? palette.textMuted
                                              .withValues(alpha: 0.75)
                                          : palette.text),
                                  fontWeight: isCurrent
                                      ? FontWeight.w800
                                      : FontWeight.normal,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
