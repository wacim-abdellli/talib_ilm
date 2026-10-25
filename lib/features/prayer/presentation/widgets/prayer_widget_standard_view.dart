import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../data/models/prayer_models.dart';
import 'prayer_widget_state_evaluator.dart';

/// PrayerWidgetStandardView — 2-row card matching Salaat First's clean structure.
///
/// Row 1: [صلاة الفجر بعد 04:25:56]   ←→   [5:03 ص ⏰]
/// Row 2: 5 evenly-spaced prayer columns, active highlighted with golden pill.
///
/// All sizing is theme-derived — no raw pixels, no dynamic flex fights.
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
        // ── Row 1: Header ─────────────────────────────────────────────────
        // RIGHT (RTL start): Prayer title + countdown badge
        // LEFT  (RTL end)  : Time pill
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Prayer title + time pill — right side
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      eval.displayTitle,
                      style: textTheme.label.copyWith(
                        color: palette.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Flexible(
                    child: _TimePill(
                      label: eval.timePillLabel,
                      color: prayerColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpace.xs),

            // Countdown badge — left side
            _CountdownBadge(
              statusLabel: eval.statusLabel,
              countdown: eval.countdownFormatted,
              bgColor: bannerBgColor,
              borderColor: bannerBorderColor,
              textColor: bannerTextColor,
              countdownColor: palette.text,
            ),
          ],
        ),

        const SizedBox(height: AppSpace.sm),

        // ── Row 2: 5 Prayer Stations ───────────────────────────────────────
        Row(
          children: AppStrings.prayerOrder.map((name) {
            final isCurrent = eval.activePrayerName == name;
            final pTime = all[name];
            final isPast = eval.completedPrayerNames.contains(name);
            return _PrayerStation(
              name: name,
              time: pTime,
              isCurrent: isCurrent,
              isPast: isPast,
              prayerColor: prayerColor,
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Countdown badge: [بقي على الأذان  04:25:56]
/// Clean horizontal badge with comfortable sizing — zero text truncation dots.
class _CountdownBadge extends StatelessWidget {
  final String statusLabel;
  final String countdown;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final Color countdownColor;

  const _CountdownBadge({
    required this.statusLabel,
    required this.countdown,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.countdownColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.xs,
        vertical: AppSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: Text(
              statusLabel,
              style: textTheme.label.copyWith(
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 70),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                countdown,
                style: textTheme.label.copyWith(
                  color: countdownColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Time pill: e.g. "5:03 ص"
class _TimePill extends StatelessWidget {
  final String label;
  final Color color;

  const _TimePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.xs,
        vertical: AppSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillRadius,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 64),
        child: Text(
          label,
          style: textTheme.label.copyWith(
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Single prayer column in the 5-prayer strip.
class _PrayerStation extends StatelessWidget {
  final String name;
  final DateTime? time;
  final bool isCurrent;
  final bool isPast;
  final Color prayerColor;

  const _PrayerStation({
    required this.name,
    required this.time,
    required this.isCurrent,
    required this.isPast,
    required this.prayerColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final timeStr = time != null ? formatPrayerTime12h(time!) : '--:--';

    final nameColor = isCurrent
        ? prayerColor
        : isPast
            ? palette.textMuted
            : palette.text;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Prayer name
          Text(
            name,
            style: isCurrent
                ? textTheme.label.copyWith(color: nameColor)
                : textTheme.caption.copyWith(color: nameColor),
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpace.xxs),
          // Time — active gets golden rounded badge
          isCurrent
              ? Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.xs,
                    vertical: AppSpace.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: prayerColor,
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: Text(
                    timeStr,
                    style: textTheme.label.copyWith(
                      color: palette.onPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                )
              : Text(
                  timeStr,
                  style: textTheme.caption.copyWith(
                    color: isPast
                        ? palette.textMuted.withValues(alpha: 0.75)
                        : palette.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
        ],
      ),
    );
  }
}

/// Export for backward compatibility with other widget files.
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
      name: prayerName,
      time: prayerTime,
      isCurrent: isCurrent,
      isPast: isPast,
      prayerColor: palette.prayer(prayerName),
    );
  }
}
