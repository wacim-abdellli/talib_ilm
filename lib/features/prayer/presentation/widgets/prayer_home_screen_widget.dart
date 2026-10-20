import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../data/models/prayer_models.dart';
import 'prayer_widget_standard_view.dart';
import 'prayer_widget_state_evaluator.dart';
import 'prayer_widget_tall_view.dart';

export 'prayer_widget_state_evaluator.dart';
export 'prayer_widget_standard_view.dart' show WidgetPrayerStation;

/// PrayerHomeScreenWidget - Multi-size responsive representation of the
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
    this.height = 145,
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

    // Size-adaptive layout modes
    final isCompact = width < 275;
    final isTall = width >= 275 && height >= 260;
    final isRibbon = width >= 275 && height < 70;

    Widget content;
    if (isTall) {
      content = PrayerWidgetTallView(
        prayerDay: prayerDay,
        eval: eval,
        all: all,
        prayerColor: prayerColor,
        bannerBgColor: bannerBgColor,
        bannerBorderColor: bannerBorderColor,
        bannerTextColor: bannerTextColor,
        now: now,
      );
    } else if (isCompact) {
      content = _buildCompactLayout(
        palette: palette,
        textTheme: textTheme,
        eval: eval,
        prayerColor: prayerColor,
        bannerBgColor: bannerBgColor,
        bannerBorderColor: bannerBorderColor,
        bannerTextColor: bannerTextColor,
      );
    } else if (isRibbon) {
      content = _buildRibbonLayout(
        palette: palette,
        textTheme: textTheme,
        eval: eval,
        prayerColor: prayerColor,
        bannerBgColor: bannerBgColor,
        bannerBorderColor: bannerBorderColor,
        bannerTextColor: bannerTextColor,
      );
    } else {
      content = PrayerWidgetStandardView(
        eval: eval,
        all: all,
        prayerColor: prayerColor,
        bannerBgColor: bannerBgColor,
        bannerBorderColor: bannerBorderColor,
        bannerTextColor: bannerTextColor,
        referenceTime: now,
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsetsDirectional.all(AppSpace.sm),
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
              width: width - (AppSpace.sm * 2),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  /// ── Compact 2x2 Mode: Focused Single-Prayer Card ──
  Widget _buildCompactLayout({
    required AppPalette palette,
    required AppTextTheme textTheme,
    required EvaluatedPrayerWidgetState eval,
    required Color prayerColor,
    required Color bannerBgColor,
    required Color bannerBorderColor,
    required Color bannerTextColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Header: [Medallion + Title] Centered
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
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
            const SizedBox(width: AppSpace.xs),
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

        const SizedBox(height: AppSpace.xxs),

        // 2. Large Centered Prayer Time
        Center(
          child: Text(
            eval.timePillLabel,
            style: textTheme.title.copyWith(
              fontWeight: FontWeight.w900,
              color: prayerColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),

        const SizedBox(height: AppSpace.xxs),

        // 3. Status & Countdown Badge
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xxs + 1,
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
            mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(width: AppSpace.xs),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  eval.countdownFormatted,
                  style: textTheme.label.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 4. Bottom: Next Prayer Preview
        if (eval.nextPrayerName != null && eval.nextPrayerTime != null) ...[
          const SizedBox(height: AppSpace.xxs),
          Center(
            child: Text(
              'التالي: ${eval.nextPrayerName} ${formatPrayerTime12h(eval.nextPrayerTime!)}',
              style: textTheme.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  /// ── Ribbon 4x1 Mode: Streamlined Single Row ──
  Widget _buildRibbonLayout({
    required AppPalette palette,
    required AppTextTheme textTheme,
    required EvaluatedPrayerWidgetState eval,
    required Color prayerColor,
    required Color bannerBgColor,
    required Color bannerBorderColor,
    required Color bannerTextColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Right (Start in RTL): Medallion + Title + Time
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
              const SizedBox(width: AppSpace.xs),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      eval.displayTitle,
                      style: textTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: palette.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      eval.timePillLabel,
                      style: textTheme.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: prayerColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
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

        const SizedBox(width: AppSpace.xs),

        // Left (End in RTL): Status Banner with Countdown
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                eval.statusIcon,
                size: AppIcon.xs,
                color: bannerTextColor,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                eval.statusLabel,
                style: textTheme.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: bannerTextColor,
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  eval.countdownFormatted,
                  style: textTheme.label.copyWith(
                    fontWeight: FontWeight.w900,
                    color: palette.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
