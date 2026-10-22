import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import 'prayer_widget_state_evaluator.dart';
import 'widget_shared_components.dart';

const double kLargeW = 380.0;
const double kLargeH = 104.0;
const double kLargePadH = AppSpace.sm; // 8dp
const double kLargePadV = AppSpace.sm; // 8dp

/// Large flagship widget (Salaat First style, Pic 2) — fixed 380×104dp canvas.
/// Spans edge-to-edge across the launcher slot with zero side gutters.
/// Row 1: [Upcoming Prayer • Countdown] (Right) ←→ [Hijri Date • City] (Left)
/// Row 2: 5 Daily Prayers Strip with active prayer highlighted in signature gold pill
class WidgetLarge extends StatelessWidget {
  final EvaluatedPrayerWidgetState eval;
  final Map<String, DateTime> all;
  final String hijriDate;
  final String cityName;
  final bool isDark;
  final double? width;
  final double? height;
  final bool forNativeWidget;

  const WidgetLarge({
    super.key,
    required this.eval,
    required this.all,
    required this.hijriDate,
    required this.cityName,
    this.isDark = false,
    this.width,
    this.height,
    this.forNativeWidget = false,
  });

  static String _formatTime12h(DateTime time) {
    final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final hStr = hour12.toString().padLeft(2, '0');
    final mStr = time.minute.toString().padLeft(2, '0');
    return '$hStr:$mStr';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedW = width ?? kLargeW;
    final resolvedH = height ?? kLargeH;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: WidgetCard(
        width: resolvedW,
        height: resolvedH,
        isDark: isDark,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: kLargePadH,
          vertical: kLargePadV,
        ),
        child: Builder(
          builder: (ctx) {
            final palette = ctx.palette;
            final textTheme = ctx.text;

            final displayTitle = eval.displayTitle.startsWith('صلاة ')
                ? eval.displayTitle.substring(5)
                : eval.displayTitle;
            final cleanDate =
                hijriDate.replaceAll(RegExp(r'\s*\d{4}\s*هـ?'), '').trim();
            final displayDate = cleanDate.isNotEmpty ? cleanDate : hijriDate;
            final activePrayerColor = palette.prayer(eval.activePrayerName);

            return Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Top Bar: [Prayer • Countdown] (Start) ←→ [Hijri Date • City] (End) ──
                SizedBox(
                  height: AppSpace.xl,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Start (Right): Active/Upcoming Prayer title + Countdown (shrink-wrap)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (!forNativeWidget) ...[
                            Text(
                              displayTitle,
                              style: textTheme.caption.copyWith(
                                color: activePrayerColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                eval.headerCountdownLabel,
                                style: textTheme.caption.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(width: AppSpace.xs),

                      // End (Left): Hijri Date • City Name (scales down smoothly if tight, NO truncation dots)
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                displayDate,
                                style: textTheme.caption.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                              ),
                              if (cityName.isNotEmpty &&
                                  cityName != 'طالب العلم') ...[
                                const SizedBox(width: AppSpace.xs),
                                Text(
                                  '•',
                                  style: textTheme.caption.copyWith(
                                    color: palette.border,
                                  ),
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Text(
                                  cityName,
                                  style: textTheme.caption.copyWith(
                                    color: palette.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.sm),

                // ── 2. Bottom Row: 5 Daily Prayers (Salaat First style) ──
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: AppStrings.prayerOrder.map((name) {
                    final isCurrent = eval.activePrayerName == name;
                    final isPast = eval.completedPrayerNames.contains(name);
                    final pTime = all[name];
                    final timeStr =
                        pTime != null ? _formatTime12h(pTime) : '--:--';
                    final pColor = palette.prayer(name);

                    final nameColor = isCurrent
                        ? pColor
                        : (isPast ? palette.textMuted : palette.text);

                    return Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Prayer Name
                          Text(
                            name,
                            style: textTheme.caption.copyWith(
                              color: nameColor,
                              fontWeight: isCurrent
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpace.xs),

                          // Prayer Time
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.sm,
                                vertical: AppSpace.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: pColor,
                                borderRadius: AppRadius.smRadius,
                              ),
                              child: Text(
                                timeStr,
                                style: textTheme.caption.copyWith(
                                  color: palette.surface,
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsetsDirectional.symmetric(
                                vertical: AppSpace.xxs,
                              ),
                              child: Text(
                                timeStr,
                                style: textTheme.caption.copyWith(
                                  color: isPast
                                      ? palette.textMuted
                                      : palette.text,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
