import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import 'prayer_widget_state_evaluator.dart';
import 'widget_shared_components.dart';

const double kRibbonW = 360.0;
const double kRibbonH = 80.0;
const double kRibbonPadH = AppSpace.lg; // 16dp
const double kRibbonPadV = AppSpace.xs; // 4dp
const double kRibbonBorder = 1.0;
const double kRibbonContent =
    kRibbonW - (kRibbonPadH * 2) - (kRibbonBorder * 2); // 326dp

/// Ribbon widget (4×1) — 360×80dp fixed canvas.
/// Row 1: Active prayer countdown + Hijri date
/// Row 2: 5-prayer strip
class WidgetRibbon extends StatelessWidget {
  final EvaluatedPrayerWidgetState eval;
  final Map<String, DateTime> all;
  final String hijriDate;
  final bool isDark;

  const WidgetRibbon({
    super.key,
    required this.eval,
    required this.all,
    required this.hijriDate,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    const double row1TitleW = kRibbonContent * 0.58;
    const double row1DateW = kRibbonContent * 0.42;
    const double titleTextW = row1TitleW - AppIcon.xs - AppSpace.xs;
    const double dateTextW = row1DateW - AppIcon.xs - AppSpace.xs;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: WidgetCard(
        width: kRibbonW,
        height: kRibbonH,
        isDark: true, // Ribbon is always dark card
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: kRibbonPadH,
          vertical: kRibbonPadV,
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
                // ── Row 1: Hero title/countdown + Hijri date ──
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: row1TitleW,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Icon(eval.prayerIcon, size: AppIcon.xs, color: prayerColor),
                          const SizedBox(width: AppSpace.xs),
                          SizedBox(
                            width: titleTextW,
                            child: Text(
                              '${eval.displayTitle} • ${eval.countdownFormatted}',
                              style: textTheme.caption.copyWith(color: palette.text),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: row1DateW,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: AppIcon.xs, color: palette.gold),
                          const SizedBox(width: AppSpace.xs),
                          SizedBox(
                            width: dateTextW,
                            child: Text(
                              hijriDate,
                              style: textTheme.caption.copyWith(color: palette.textMuted),
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

                // ── Row 2: 5-Prayer Station Strip ──
                PrayerStrip(
                  totalWidth: kRibbonContent,
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
