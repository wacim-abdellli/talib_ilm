import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../data/models/prayer_models.dart';
import 'prayer_widget_state_evaluator.dart';

/// PrayerWidgetStandardView - Canonical 4x1 / 4x2 Home Screen AppWidget layout
/// inspired by the clean, minimal Salaat First card:
/// Top row: [Prayer title + countdown badge] on Right, [Time / Iqama pill] on Left.
/// Bottom row: 5 horizontally balanced prayer stations with vibrant active highlight.
class PrayerWidgetStandardView extends StatelessWidget {
  final EvaluatedPrayerWidgetState eval;
  final Map<String, DateTime> all;
  final Color prayerColor;
  final Color bannerBgColor;
  final Color bannerBorderColor;
  final Color bannerTextColor;
  final DateTime? referenceTime;

  const PrayerWidgetStandardView({
    super.key,
    required this.eval,
    required this.all,
    required this.prayerColor,
    required this.bannerBgColor,
    required this.bannerBorderColor,
    required this.bannerTextColor,
    this.referenceTime,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. Top Header Row: [Title & Status] on Right, [Time / Iqama Pill] on Left ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Right (Start in RTL): Prayer Title & Status Badge
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpace.xs,
                runSpacing: AppSpace.xxs,
                children: [
                  Text(
                    eval.displayTitle,
                    style: textTheme.label.copyWith(
                      fontWeight: FontWeight.w800,
                      color: palette.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Container(
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
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            eval.countdownFormatted,
                            style: textTheme.caption.copyWith(
                              fontWeight: FontWeight.w800,
                              color: palette.text,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpace.xs),

            // Left (End in RTL): Time / Iqama Pill (e.g. "5:02 ص" or "الإقامة 12:40 م")
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.xs,
                vertical: AppSpace.xxs,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.pillRadius,
                border: Border.all(
                  color: prayerColor.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Text(
                eval.timePillLabel,
                style: textTheme.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpace.sm),

        // ── 2. Bottom Row: 5 Daily Prayer Stations Strip ──
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

class WidgetPrayerStation extends StatelessWidget {
  final String prayerName;
  final DateTime? prayerTime;
  final bool isCurrent;
  final bool isPast;
  final bool isInPrayerTime;

  const WidgetPrayerStation({
    super.key,
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
    final timeStr = prayerTime != null ? formatPrayerTime12h(prayerTime!) : '';

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Prayer Name
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              prayerName,
              style: textTheme.caption.copyWith(
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: isCurrent ? palette.primary : palette.textMuted,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: AppSpace.xxs),
          // Prayer Time with Golden Active Pill Badge (Salaat First style)
          if (isCurrent)
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.xs,
                vertical: AppSpace.xxs,
              ),
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: AppRadius.smRadius,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  timeStr,
                  style: textTheme.caption.copyWith(
                    fontWeight: FontWeight.w900,
                    color: palette.onPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                ),
              ),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                timeStr,
                style: textTheme.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: palette.text,
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
