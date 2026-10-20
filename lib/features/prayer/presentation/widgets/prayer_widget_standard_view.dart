import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../home/presentation/widgets/home_hero_timeline_station.dart';
import '../../data/models/prayer_models.dart';
import 'prayer_widget_state_evaluator.dart';

/// PrayerWidgetStandardView - Canonical 4x2 Home Screen AppWidget layout.
class PrayerWidgetStandardView extends StatelessWidget {
  final EvaluatedPrayerWidgetState eval;
  final Map<String, DateTime> all;
  final Color prayerColor;
  final Color bannerBgColor;
  final Color bannerBorderColor;
  final Color bannerTextColor;

  const PrayerWidgetStandardView({
    super.key,
    required this.eval,
    required this.all,
    required this.prayerColor,
    required this.bannerBgColor,
    required this.bannerBorderColor,
    required this.bannerTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. Top Header Row: [Prayer Title + Medallion] on Right, [Time Pill] on Left ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Right (Start in RTL): Prayer Medallion & Title
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: prayerColor.withValues(alpha: 0.14),
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: prayerColor.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      eval.prayerIcon,
                      color: prayerColor,
                      size: AppIcon.sm,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Flexible(
                    child: Text(
                      eval.displayTitle,
                      style: textTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: palette.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpace.xs),

            // Left (End in RTL): Next / Current Prayer Time Pill
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.sm,
                vertical: AppSpace.xs,
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
                  Icon(
                    eval.timePillIcon,
                    size: AppIcon.sm,
                    color: prayerColor,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    eval.timePillLabel,
                    style: textTheme.label.copyWith(
                      fontWeight: FontWeight.w800,
                      color: palette.text,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpace.xs),

        // ── 2. Middle Row: Status Banner with Countdown and Status Label ──
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Right (Start in RTL): Status Icon and Label
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      eval.statusIcon,
                      size: AppIcon.xs,
                      color: bannerTextColor,
                    ),
                    const SizedBox(width: AppSpace.xs),
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
                  ],
                ),
              ),

              const SizedBox(width: AppSpace.sm),

              // Left (End in RTL): Digital Countdown Badge
              Directionality(
                textDirection: TextDirection.ltr,
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceRaised,
                    borderRadius: AppRadius.smRadius,
                    border: Border.all(
                      color: bannerBorderColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    eval.countdownFormatted,
                    style: textTheme.label.copyWith(
                      fontWeight: FontWeight.w800,
                      color: palette.text,
                      letterSpacing: 1.1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpace.xs),

        // ── 3. Bottom Row: Warm Journey Strip of 5 Daily Prayers ──
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpace.xs,
            horizontal: AppSpace.xxs,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: palette.border,
              width: 1,
            ),
          ),
          child: Row(
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
    final pColor = palette.prayer(prayerName);
    final timeStr = prayerTime != null ? formatPrayerTime12h(prayerTime!) : '';
    final icon = iconForPrayer(prayerName);

    return Expanded(
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.xxs,
          vertical: AppSpace.xxs,
        ),
        decoration: isCurrent
            ? BoxDecoration(
                color: palette.surfaceRaised,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: pColor,
                  width: isInPrayerTime ? 1.8 : 1.4,
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Pip
            SizedBox(
              height: AppSpace.sm,
              child: Center(
                child: isCurrent
                    ? Container(
                        width: AppSpace.xs + 2,
                        height: AppSpace.xs + 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isInPrayerTime ? palette.success : palette.gold,
                        ),
                      )
                    : isPast
                        ? Icon(
                            Icons.check_rounded,
                            size: AppIcon.xs,
                            color: palette.success,
                          )
                        : Container(
                            width: AppSpace.xs,
                            height: AppSpace.xs,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: pColor.withValues(alpha: 0.35),
                            ),
                          ),
              ),
            ),

            const SizedBox(height: AppSpace.xxs),

            // Prayer Icon
            Icon(
              icon,
              size: isCurrent ? AppIcon.md : AppIcon.sm,
              color: isCurrent
                  ? pColor
                  : (isPast
                      ? pColor.withValues(alpha: 0.45)
                      : pColor.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: AppSpace.xxs),

            // Prayer Name
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                prayerName,
                style: textTheme.caption.copyWith(
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  color: isCurrent
                      ? pColor
                      : (isPast ? palette.textMuted : palette.text),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xxs),

            // Prayer Time with Western Digits
            if (timeStr.isNotEmpty)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  timeStr,
                  softWrap: false,
                  style: textTheme.caption.copyWith(
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                    color: isCurrent
                        ? palette.text
                        : (isPast ? palette.textSubtle : palette.textMuted),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
