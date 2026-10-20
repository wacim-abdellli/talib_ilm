import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../home/presentation/widgets/home_hero_timeline_station.dart';
import '../../data/models/prayer_models.dart';
import 'prayer_widget_state_evaluator.dart';

export 'prayer_widget_state_evaluator.dart';

/// PrayerHomeScreenWidget - High-Fidelity Representation of the
/// Talib Ilm Prayer Card / Widget for Android Home Screen and Hero Card.
class PrayerHomeScreenWidget extends StatelessWidget {
  final PrayerTimesDay? prayerDay;
  final DateTime? referenceTime;
  final String? nextPrayerName;
  final DateTime? nextPrayerTime;

  final double width;
  final double height;

  const PrayerHomeScreenWidget({
    super.key,
    this.prayerDay,
    this.referenceTime,
    this.nextPrayerName,
    this.nextPrayerTime,
    this.width = 380,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final now = referenceTime ?? DateTime.now();

    final all = prayerDay?.prayers ?? _buildFallbackPrayers(now);
    final eval = PrayerWidgetStateEvaluator.evaluate(now: now, all: all);

    final prayerColor = palette.prayer(eval.activePrayerName);

    // Dynamic banner styling adapting to the liturgical prayer phase
    final Color bannerBgColor;
    final Color bannerBorderColor;
    final Color bannerTextColor;

    switch (eval.phase) {
      case PrayerWidgetPhase.atAdhan:
        bannerBgColor = palette.goldSoft;
        bannerBorderColor = palette.gold.withValues(alpha: 0.5);
        bannerTextColor = palette.gold;
        break;
      case PrayerWidgetPhase.betweenAdhanAndIqama:
        bannerBgColor = prayerColor.withValues(alpha: 0.16);
        bannerBorderColor = prayerColor.withValues(alpha: 0.45);
        bannerTextColor = prayerColor;
        break;
      case PrayerWidgetPhase.inSalah:
        bannerBgColor = palette.success.withValues(alpha: 0.14);
        bannerBorderColor = palette.success.withValues(alpha: 0.45);
        bannerTextColor = palette.success;
        break;
      case PrayerWidgetPhase.postSalah:
        bannerBgColor = palette.surfaceMuted;
        bannerBorderColor = palette.border;
        bannerTextColor = palette.textMuted;
        break;
      case PrayerWidgetPhase.beforeAdhan:
        bannerBgColor = prayerColor.withValues(alpha: 0.10);
        bannerBorderColor = prayerColor.withValues(alpha: 0.28);
        bannerTextColor = prayerColor;
        break;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(
              color: palette.border,
              width: 1.2,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(
              width: width - (AppSpace.md * 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 1. Top Header Row: [Time Pill] Start, [Prayer Name + Medallion] End ──
                  Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Next / Current Prayer Time Pill with Contextual Icon
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

                  const SizedBox(width: AppSpace.xs),

                  // Prayer Title & Celestial Medallion (Right in RTL)
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        const SizedBox(width: AppSpace.sm),
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
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpace.xs),

              // ── 2. Middle Row: Status Banner with Countdown Pill and Label ──
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
                    // Digital Countdown Badge (Pill Box) on Left
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

                    const SizedBox(width: AppSpace.sm),

                    // Label with Status Icon on Right
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

                    return _WidgetPrayerStation(
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
          ),
        ),
      ),
    ),
  ),
);
  }

  static Map<String, DateTime> _buildFallbackPrayers(DateTime now) {
    final base = DateTime(now.year, now.month, now.day);
    return {
      AppStrings.prayerFajr: base.add(const Duration(hours: 5, minutes: 2)),
      AppStrings.prayerDhuhr: base.add(const Duration(hours: 12, minutes: 3)),
      AppStrings.prayerAsr: base.add(const Duration(hours: 15, minutes: 11)),
      AppStrings.prayerMaghrib: base.add(const Duration(hours: 17, minutes: 38)),
      AppStrings.prayerIsha: base.add(const Duration(hours: 19, minutes: 2)),
    };
  }
}

class _WidgetPrayerStation extends StatelessWidget {
  final String prayerName;
  final DateTime? prayerTime;
  final bool isCurrent;
  final bool isPast;
  final bool isInPrayerTime;

  const _WidgetPrayerStation({
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
            if (isCurrent)
              Container(
                width: AppSpace.sm - 2,
                height: AppSpace.sm - 2,
                margin: const EdgeInsets.only(bottom: AppSpace.xxs),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isInPrayerTime ? palette.success : palette.gold,
                ),
              )
            else if (isPast)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpace.xxs),
                child: Icon(
                  Icons.check_rounded,
                  size: AppIcon.xs,
                  color: palette.success,
                ),
              )
            else
              Container(
                width: AppSpace.xs,
                height: AppSpace.xs,
                margin: const EdgeInsets.only(bottom: AppSpace.xxs),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pColor.withValues(alpha: 0.35),
                ),
              ),

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
