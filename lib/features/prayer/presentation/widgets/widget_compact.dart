import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../data/models/prayer_models.dart';
import 'prayer_widget_state_evaluator.dart';
import 'widget_shared_components.dart';

const double kCompactW = 160.0;
const double kCompactH = 160.0;
const double kCompactPad = AppSpace.sm; // 8dp
const double kCompactBorder = 1.0;
const double kCompactContent =
    kCompactW - (kCompactPad * 2) - (kCompactBorder * 2); // 142dp

/// Compact widget (2×2) — 160×160dp fixed canvas.
/// Prayer name & icon, big prayer time, countdown badge, and upcoming prayer.
class WidgetCompact extends StatelessWidget {
  final EvaluatedPrayerWidgetState eval;
  final bool isDark;

  const WidgetCompact({
    super.key,
    required this.eval,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final nextName = eval.nextPrayerName;
    final nextTime = eval.nextPrayerTime;
    final nextLabel = nextName != null && nextTime != null
        ? 'التالي: $nextName ${formatPrayerTime12h(nextTime)}'
        : 'طالب العلم';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: WidgetCard(
        width: kCompactW,
        height: kCompactH,
        isDark: isDark,
        padding: const EdgeInsetsDirectional.all(kCompactPad),
        child: Builder(
          builder: (ctx) {
            final palette = ctx.palette;
            final textTheme = ctx.text;
            final prayerColor = palette.prayer(eval.activePrayerName);

            return Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Prayer Title + Icon
                SizedBox(
                  width: kCompactContent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        eval.prayerIcon,
                        size: AppIcon.xs,
                        color: prayerColor,
                      ),
                      const SizedBox(width: AppSpace.xs),
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
                    ],
                  ),
                ),

                // 2. Big Prayer Time
                SizedBox(
                  width: kCompactContent,
                  child: Text(
                    eval.timePillLabel,
                    style: textTheme.titleSmall.copyWith(
                      color: prayerColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),

                // 3. Countdown Badge
                FixedCountdownBadge(
                  maxWidth: kCompactContent,
                  statusLabel: eval.statusLabel,
                  countdown: eval.countdownFormatted,
                  bgColor: palette.surfaceMuted,
                  borderColor: palette.border,
                  labelColor: palette.gold,
                  countdownColor: palette.text,
                  isVertical: true,
                ),

                // 4. Next Prayer Footer
                SizedBox(
                  width: kCompactContent,
                  child: Text(
                    nextLabel,
                    style: textTheme.caption.copyWith(
                      color: palette.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
