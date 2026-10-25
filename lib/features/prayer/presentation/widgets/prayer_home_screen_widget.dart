import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../data/models/prayer_models.dart';
import 'prayer_widget_standard_view.dart';
import 'prayer_widget_state_evaluator.dart';
import 'prayer_widget_tall_view.dart';

export 'prayer_widget_state_evaluator.dart';
export 'prayer_widget_standard_view.dart' show WidgetPrayerStation;

/// PrayerHomeScreenWidget — Multi-size Android Home Screen widget container.
///
/// Layout zones (based on rendered size):
///  • Ribbon   height < 100dp → single row: [name + countdown | time pill]
///  • Compact  width  < 230dp → focused card: title + time + badge + next prayer
///  • Standard 100 ≤ h < 160 AND w ≥ 230 → 2-row: header + 5-prayer strip
///  • Tall     height ≥ 160dp AND w ≥ 230 → 3-section: topbar + hero + strip
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
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final now = referenceTime ?? DateTime.now();

    final all = prayerDay?.prayers ?? _fallbackPrayers(now);
    final eval = PrayerWidgetStateEvaluator.evaluate(now: now, all: all);
    final prayerColor = palette.prayer(eval.activePrayerName);

    // Resolve banner styling from liturgical phase
    final Color bannerBg;
    final Color bannerBorder;
    final Color bannerText;
    switch (eval.phase) {
      case PrayerWidgetPhase.atAdhan:
        bannerBg = palette.goldSoft;
        bannerBorder = palette.gold.withValues(alpha: 0.5);
        bannerText = palette.gold;
        break;
      case PrayerWidgetPhase.betweenAdhanAndIqama:
        bannerBg = prayerColor.withValues(alpha: 0.16);
        bannerBorder = prayerColor.withValues(alpha: 0.45);
        bannerText = prayerColor;
        break;
      case PrayerWidgetPhase.inSalah:
        bannerBg = palette.success.withValues(alpha: 0.14);
        bannerBorder = palette.success.withValues(alpha: 0.45);
        bannerText = palette.success;
        break;
      case PrayerWidgetPhase.postSalah:
        bannerBg = palette.surfaceMuted;
        bannerBorder = palette.border;
        bannerText = palette.textMuted;
        break;
      case PrayerWidgetPhase.beforeAdhan:
        bannerBg = prayerColor.withValues(alpha: 0.10);
        bannerBorder = prayerColor.withValues(alpha: 0.28);
        bannerText = prayerColor;
        break;
    }

    // Pick layout zone
    final isRibbon = height < 100;
    final isCompact = !isRibbon && width < 230;
    final isTall = !isRibbon && !isCompact && height >= 160;

    Widget content;
    if (isTall) {
      content = PrayerWidgetTallView(
        prayerDay: prayerDay,
        eval: eval,
        all: all,
        prayerColor: prayerColor,
        bannerBgColor: bannerBg,
        bannerBorderColor: bannerBorder,
        bannerTextColor: bannerText,
        now: now,
      );
    } else if (isCompact) {
      content = _buildCompact(palette, textTheme, eval, prayerColor, bannerBg, bannerBorder, bannerText);
    } else if (isRibbon) {
      content = _buildRibbon(palette, textTheme, eval, prayerColor, bannerBg, bannerBorder, bannerText);
    } else {
      content = PrayerWidgetStandardView(
        eval: eval,
        all: all,
        prayerColor: prayerColor,
        bannerBgColor: bannerBg,
        bannerBorderColor: bannerBorder,
        bannerTextColor: bannerText,
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
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpace.md,
            AppSpace.sm,
            AppSpace.md,
            AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: palette.border, width: 1.2),
          ),
          child: ClipRect(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(
                width: width - (AppSpace.md * 2),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ── Compact mode (narrow widget, ≈ 2×2) ───────────────────────────────
  Widget _buildCompact(
    AppPalette palette,
    AppTextTheme textTheme,
    EvaluatedPrayerWidgetState eval,
    Color prayerColor,
    Color bannerBg,
    Color bannerBorder,
    Color bannerText,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Prayer name
        Text(
          eval.displayTitle,
          style: textTheme.label.copyWith(color: palette.text),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpace.xxs),
        // Large time
        Text(
          eval.timePillLabel,
          style: textTheme.titleSmall.copyWith(
            color: prayerColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpace.xxs),
        // Countdown badge
        Container(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xs, vertical: AppSpace.xxs),
          decoration: BoxDecoration(
            color: bannerBg,
            borderRadius: AppRadius.smRadius,
            border: Border.all(color: bannerBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  eval.statusLabel,
                  style: textTheme.label.copyWith(color: bannerText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpace.xxs),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  eval.countdownFormatted,
                  style: textTheme.label.copyWith(
                    color: palette.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        // Next prayer
        if (eval.nextPrayerName != null && eval.nextPrayerTime != null) ...[
          const SizedBox(height: AppSpace.xxs),
          Text(
            'التالي: ${eval.nextPrayerName} ${formatPrayerTime12h(eval.nextPrayerTime!)}',
            style: textTheme.caption.copyWith(
              color: palette.textMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// ── Ribbon mode (short widget, height < 100) ───────────────────────────
  Widget _buildRibbon(
    AppPalette palette,
    AppTextTheme textTheme,
    EvaluatedPrayerWidgetState eval,
    Color prayerColor,
    Color bannerBg,
    Color bannerBorder,
    Color bannerText,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Prayer name + time (right side in RTL)
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eval.displayTitle,
                style: textTheme.label.copyWith(color: palette.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                eval.timePillLabel,
                style: textTheme.label.copyWith(
                  color: prayerColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        // Countdown badge (left side in RTL)
        Container(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
          decoration: BoxDecoration(
            color: bannerBg,
            borderRadius: AppRadius.smRadius,
            border: Border.all(color: bannerBorder, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eval.statusLabel,
                style: textTheme.label.copyWith(color: bannerText),
                maxLines: 1,
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  eval.countdownFormatted,
                  style: textTheme.label.copyWith(
                    color: palette.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Map<String, DateTime> _fallbackPrayers(DateTime now) {
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
