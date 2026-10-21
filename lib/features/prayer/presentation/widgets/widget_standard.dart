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
    const double cardW = (kStandardContent - AppSpace.sm) / 2.0; // 159dp each

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
                // ── Hero Section: Two Balanced 159dp Cards ──
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Right Card (RTL Start): Active Prayer Info
                    Container(
                      width: cardW,
                      padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                      decoration: BoxDecoration(
                        color: prayerColor.withValues(alpha: 0.08),
                        borderRadius: AppRadius.mdRadius,
                        border: Border.all(
                          color: prayerColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: prayerColor.withValues(alpha: 0.16),
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: Icon(
                              eval.prayerIcon,
                              size: AppIcon.xs,
                              color: prayerColor,
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eval.displayTitle,
                                  style: textTheme.label.copyWith(
                                    color: palette.text,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  eval.timePillLabel,
                                  style: textTheme.titleSmall.copyWith(
                                    color: prayerColor,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Left Card (RTL End): Live Countdown Badge
                    Container(
                      width: cardW,
                      padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: AppRadius.mdRadius,
                        border: Border.all(
                          color: palette.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: palette.gold.withValues(alpha: 0.14),
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: Icon(
                              Icons.hourglass_top_rounded,
                              size: AppIcon.xs,
                              color: palette.gold,
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eval.statusLabel,
                                  style: textTheme.caption.copyWith(
                                    color: palette.gold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    eval.countdownFormatted,
                                    style: textTheme.titleSmall.copyWith(
                                      color: palette.text,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
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
