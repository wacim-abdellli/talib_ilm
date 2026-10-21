import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import 'prayer_widget_state_evaluator.dart';
import 'widget_shared_components.dart';

const double kRibbonW = 380.0;
const double kRibbonH = 104.0;
const double kRibbonPadH = AppSpace.sm; // 8dp
const double kRibbonPadV = AppSpace.sm; // 8dp
const double kRibbonBorder = 1.0;
const double kRibbonContent =
    kRibbonW - (kRibbonPadH * 2) - (kRibbonBorder * 2); // 362dp

/// Ribbon widget (4×1) — 380×104dp fixed canvas.
/// Row 1: Active prayer countdown + Hijri date
/// Row 2: 5-prayer strip with celestial sun and moon icons
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
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: WidgetCard(
        width: kRibbonW,
        height: kRibbonH,
        isDark: isDark,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: kRibbonPadH,
          vertical: kRibbonPadV,
        ),
        child: Builder(
          builder: (ctx) {
            final palette = ctx.palette;
            final textTheme = ctx.text;
            final activeColor = palette.prayer(eval.activePrayerName);

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
                    // Start (Right): Active prayer icon + title + countdown
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          eval.prayerIcon,
                          size: AppIcon.xs,
                          color: activeColor,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          eval.displayTitle,
                          style: textTheme.label.copyWith(
                            color: activeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            eval.headerCountdownLabel,
                            style: textTheme.label.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpace.xs),

                    // End (Left): Hijri Date with Calendar Icon (never truncates)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: AppIcon.xs,
                              color: palette.textMuted,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Text(
                              hijriDate,
                              style: textTheme.caption.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpace.xs),

                // ── Row 2: 5-Prayer Station Strip with Celestial Icons ──
                PrayerStrip(
                  totalWidth: kRibbonContent,
                  eval: eval,
                  all: all,
                  showIcons: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
