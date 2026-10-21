import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/models/prayer_models.dart';
import 'prayer_widget_state_evaluator.dart';

/// PrayerStrip — 5 fixed-width prayer columns.
/// [totalWidth] = canvas width minus horizontal padding (e.g. 360 - 32 = 328)
class PrayerStrip extends StatelessWidget {
  final double totalWidth;
  final EvaluatedPrayerWidgetState eval;
  final Map<String, DateTime> all;

  const PrayerStrip({
    super.key,
    required this.totalWidth,
    required this.eval,
    required this.all,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final colWidth = totalWidth / 5.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: AppStrings.prayerOrder.map((name) {
          final isCurrent = eval.activePrayerName == name;
          final isPast = eval.completedPrayerNames.contains(name);
          final prayerColor = palette.prayer(name);
          final time = all[name];
          final timeStr = time != null ? formatPrayerTime12h(time) : '--:--';

          final nameColor = isCurrent
              ? prayerColor
              : (isPast ? palette.textMuted : palette.text);

          return SizedBox(
            width: colWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: textTheme.caption.copyWith(
                    color: nameColor,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpace.xxs),
                if (isCurrent)
                  Container(
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
                      style: textTheme.caption.copyWith(
                        color: palette.onPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  Text(
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
        }).toList(),
      ),
    );
  }
}

/// FixedCountdownBadge — status label + countdown in a container.
/// [maxWidth] = total width budget for this badge.
class FixedCountdownBadge extends StatelessWidget {
  final double maxWidth;
  final String statusLabel;
  final String countdown;
  final Color bgColor;
  final Color borderColor;
  final Color labelColor;
  final Color countdownColor;
  final bool isVertical;

  const FixedCountdownBadge({
    super.key,
    required this.maxWidth,
    required this.statusLabel,
    required this.countdown,
    required this.bgColor,
    required this.borderColor,
    required this.labelColor,
    required this.countdownColor,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    if (isVertical) {
      return Container(
        width: maxWidth,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.xs,
          vertical: AppSpace.xxs,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.smRadius,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              statusLabel,
              style: textTheme.caption.copyWith(color: labelColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpace.xxs),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                countdown,
                style: textTheme.label.copyWith(
                  color: countdownColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final labelWidth = maxWidth * 0.52;
    final countdownWidth = maxWidth * 0.48 - AppSpace.xs;

    return Container(
      width: maxWidth,
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
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              statusLabel,
              style: textTheme.caption.copyWith(color: labelColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          SizedBox(
            width: countdownWidth,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                countdown,
                style: textTheme.caption.copyWith(
                  color: countdownColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// FixedTimePill — rounded pill with prayer time.
class FixedTimePill extends StatelessWidget {
  final double maxWidth;
  final String label;
  final Color color;

  const FixedTimePill({
    super.key,
    required this.maxWidth,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    return Container(
      width: maxWidth,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.xs,
        vertical: AppSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(
        label,
        style: textTheme.caption.copyWith(
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// WidgetCard — the outer container shell.
/// [width], [height] — canvas dimensions.
/// [isDark] — dark or light background.
class WidgetCard extends StatelessWidget {
  final double width;
  final double height;
  final bool isDark;
  final EdgeInsetsDirectional? padding;
  final Widget child;

  const WidgetCard({
    super.key,
    required this.width,
    required this.height,
    this.isDark = false,
    this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = isDark == true ? AppTheme.dark() : AppTheme.light();
    return Theme(
      data: effectiveTheme,
      child: Builder(
        builder: (ctx) {
          final palette = ctx.palette;
          return MediaQuery(
            data: MediaQuery.of(ctx).copyWith(
              textScaler:
                  MediaQuery.textScalerOf(ctx).clamp(maxScaleFactor: 1.25),
            ),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: palette.surfaceRaised,
                borderRadius: AppRadius.lgRadius,
                border: Border.all(color: palette.border, width: 1),
              ),
              padding: padding ??
                  const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.lg,
                    vertical: AppSpace.sm,
                  ),
              child: ClipRect(
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Helper returning the canonical celestial icon for an Arabic prayer name.
IconData iconForPrayer(String name) {
  final p = name.trim();
  if (p.contains('الجمعة')) {
    return Icons.mosque_rounded;
  }
  if (p.contains(AppStrings.prayerFajr) || p == 'الفجر') {
    return Icons.wb_twilight_rounded;
  }
  if (p.contains(AppStrings.prayerDhuhr) || p == 'الظهر') {
    return Icons.wb_sunny_rounded;
  }
  if (p.contains(AppStrings.prayerAsr) || p == 'العصر') {
    return Icons.sunny_snowing;
  }
  if (p.contains(AppStrings.prayerMaghrib) || p == 'المغرب') {
    return Icons.nights_stay_rounded;
  }
  if (p.contains(AppStrings.prayerIsha) || p == 'العشاء') {
    return Icons.nightlight_round;
  }
  return Icons.access_time_rounded;
}

