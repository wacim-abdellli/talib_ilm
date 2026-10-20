import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../data/models/prayer_models.dart';
import 'prayer_widget_state_evaluator.dart';

/// PrayerWidgetStandardView - Canonical 2-row Salaat-First–style card.
///
/// Row 1 (header): [Prayer name + countdown badge] ←→ [active prayer time pill]
/// Row 2 (strip) : 5 prayer stations distributed evenly, active highlighted.
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
        // ── Row 1: Header ──────────────────────────────────────────────────
        // RTL layout: Prayer title (right) | countdown badge (center) | time (left)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Prayer name (right side in RTL)
            Expanded(
              child: Text(
                eval.displayTitle,
                style: textTheme.label.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: AppSpace.xs),

            // Countdown badge (centre pill)
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.sm,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: bannerBgColor,
                borderRadius: AppRadius.smRadius,
                border: Border.all(color: bannerBorderColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    eval.statusLabel,
                    style: textTheme.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: bannerTextColor,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(width: AppSpace.xs),
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

            const SizedBox(width: AppSpace.xs),

            // Active prayer time pill (left side in RTL)
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.xs,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: prayerColor.withValues(alpha: 0.12),
                borderRadius: AppRadius.pillRadius,
              ),
              child: Text(
                eval.timePillLabel,
                style: textTheme.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: prayerColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpace.sm),

        // ── Row 2: 5 Daily Prayer Stations Strip ───────────────────────────
        IntrinsicHeight(
          child: Row(
            children: AppStrings.prayerOrder.asMap().entries.map((entry) {
              final idx = entry.key;
              final prayerName = entry.value;
              final isCurrent = eval.activePrayerName == prayerName;
              final prayerTime = all[prayerName];
              final isPast = eval.completedPrayerNames.contains(prayerName);

              return _PrayerStation(
                prayerName: prayerName,
                prayerTime: prayerTime,
                isCurrent: isCurrent,
                isPast: isPast,
                isLast: idx == AppStrings.prayerOrder.length - 1,
                prayerColor: prayerColor,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// A single prayer station column in the 5-prayer horizontal strip.
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
    return _PrayerStation(
      prayerName: prayerName,
      prayerTime: prayerTime,
      isCurrent: isCurrent,
      isPast: isPast,
      isLast: false,
      prayerColor: palette.prayer(prayerName),
    );
  }
}

class _PrayerStation extends StatelessWidget {
  final String prayerName;
  final DateTime? prayerTime;
  final bool isCurrent;
  final bool isPast;
  final bool isLast;
  final Color prayerColor;

  const _PrayerStation({
    required this.prayerName,
    required this.prayerTime,
    required this.isCurrent,
    required this.isPast,
    required this.isLast,
    required this.prayerColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final timeStr = prayerTime != null ? formatPrayerTime12h(prayerTime!) : '--:--';

    final nameColor = isCurrent
        ? prayerColor
        : isPast
            ? palette.textMuted
            : palette.text;
    final timeColor = isCurrent
        ? prayerColor
        : isPast
            ? palette.textMuted.withValues(alpha: 0.75)
            : palette.text;

    return Expanded(
      child: Container(
        // Active station gets a subtle background highlight
        decoration: isCurrent
            ? BoxDecoration(
                color: prayerColor.withValues(alpha: 0.09),
                borderRadius: AppRadius.smRadius,
              )
            : null,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 2,
          vertical: AppSpace.xxs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prayer name
            Text(
              prayerName,
              style: textTheme.caption.copyWith(
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: nameColor,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            // Prayer time  — active gets golden pill badge (Salaat First style)
            if (isCurrent)
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: prayerColor,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Text(
                  timeStr,
                  style: textTheme.caption.copyWith(
                    fontWeight: FontWeight.w900,
                    color: palette.onPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              )
            else
              Text(
                timeStr,
                style: textTheme.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: timeColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
