import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import 'prayer_widget_state_evaluator.dart';
import 'widget_shared_components.dart';

const double kStandardW = 360.0;
const double kStandardH = 160.0;
const double kStandardPadH = AppSpace.lg; // 16dp
const double kStandardPadV = AppSpace.sm; // 8dp
const double kStandardBorder = 1.0;
const double kStandardContent =
    kStandardW - (kStandardPadH * 2) - (kStandardBorder * 2); // 326dp
const double kMedallionSize = 36.0;

/// Standard widget (4×2) — 360×160dp fixed canvas.
/// Section 1: Hero prayer info & countdown badge
/// Section 2: Divider
/// Section 3: 5-prayer strip
class WidgetStandard extends StatelessWidget {
  final EvaluatedPrayerWidgetState eval;
  final Map<String, DateTime> all;
  final bool isDark;

  const WidgetStandard({
    super.key,
    required this.eval,
    required this.all,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    const double heroTextW = kStandardContent * 0.45;
    const double countdownW =
        kStandardContent - kMedallionSize - (AppSpace.sm * 2) - heroTextW;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: WidgetCard(
        width: kStandardW,
        height: kStandardH,
        isDark: isDark,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: kStandardPadH,
          vertical: kStandardPadV,
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
                // ── Hero Section ──
                Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon medallion
                    Container(
                      width: kMedallionSize,
                      height: kMedallionSize,
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

                    // Prayer title + time
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

                    // Countdown badge
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

                // ── Divider ──
                Container(
                  height: 1,
                  color: palette.border,
                ),

                // ── 5-Prayer Station Strip ──
                PrayerStrip(
                  totalWidth: kStandardContent,
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
