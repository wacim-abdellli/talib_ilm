import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import 'prayer_widget_state_evaluator.dart';
import 'widget_shared_components.dart';

const double kLargeW = 360.0;
const double kLargeH = 240.0;
const double kLargePadH = AppSpace.lg; // 16dp
const double kLargePadV = AppSpace.sm; // 8dp
const double kLargeBorder = 1.0;
const double kLargeContent =
    kLargeW - (kLargePadH * 2) - (kLargeBorder * 2); // 326dp
const double kLargeMedallionSize = 36.0;

/// Large widget (4×3) — 360×240dp fixed canvas.
/// Section 1: Top bar (Hijri date • City)
/// Section 2: Divider
/// Section 3: Hero prayer section
/// Section 4: Divider
/// Section 5: 5-prayer strip
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
    const double dateBoxW = kLargeContent * 0.55;
    const double cityBoxW = kLargeContent * 0.38;
    const double heroTextW = kLargeContent * 0.45;
    const double countdownW =
        kLargeContent - kLargeMedallionSize - (AppSpace.sm * 2) - heroTextW;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: WidgetCard(
        width: kLargeW,
        height: kLargeH,
        isDark: isDark,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: kLargePadH,
          vertical: kLargePadV,
        ),
        child: Builder(
          builder: (ctx) {
            final palette = ctx.palette;
            final textTheme = ctx.text;
            final prayerColor = palette.prayer(eval.activePrayerName);

            return Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── Top Bar: Hijri date • City ──
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: dateBoxW,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: AppIcon.xs,
                            color: palette.gold,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Expanded(
                            child: Text(
                              hijriDate,
                              style: textTheme.caption.copyWith(
                                color: palette.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '•',
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    SizedBox(
                      width: cityBoxW,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: AppIcon.xs,
                            color: prayerColor,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Expanded(
                            child: Text(
                              cityName,
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Divider 1 ──
                Container(
                  height: 1,
                  color: palette.border,
                ),

                // ── Hero Section ──
                Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: kLargeMedallionSize,
                      height: kLargeMedallionSize,
                      decoration: BoxDecoration(
                        color: prayerColor.withValues(alpha: 0.14),
                        borderRadius: AppRadius.mdRadius,
                        border: Border.all(
                          color: prayerColor.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        eval.prayerIcon,
                        size: AppIcon.md,
                        color: prayerColor,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    SizedBox(
                      width: heroTextW,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eval.displayTitle,
                            style: textTheme.label.copyWith(
                              color: palette.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpace.xxs),
                          Text(
                            eval.timePillLabel,
                            style: textTheme.titleSmall.copyWith(
                              color: prayerColor,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    FixedCountdownBadge(
                      maxWidth: countdownW,
                      statusLabel: eval.statusLabel,
                      countdown: eval.countdownFormatted,
                      bgColor: palette.surfaceMuted,
                      borderColor: palette.border,
                      labelColor: palette.gold,
                      countdownColor: palette.text,
                      isVertical: true,
                    ),
                  ],
                ),

                // ── Divider 2 ──
                Container(
                  height: 1,
                  color: palette.border,
                ),

                // ── 5-Prayer Station Strip ──
                PrayerStrip(
                  totalWidth: kLargeContent,
                  eval: eval,
                  all: all,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
