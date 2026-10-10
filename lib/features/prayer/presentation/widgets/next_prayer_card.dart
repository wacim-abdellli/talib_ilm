import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_progress.dart';
import '../../data/models/prayer_models.dart';

class NextPrayerCard extends StatelessWidget {
  final NextPrayer prayer;
  final VoidCallback onTap;
  final String? countdownText;
  final double progress;

  const NextPrayerCard({
    super.key,
    required this.prayer,
    required this.onTap,
    this.countdownText,
    this.progress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final prayerColor = palette.prayer(prayer.prayer.labelAr);
    final countdown =
        countdownText ?? AppStrings.prayerInMinutes(prayer.minutesRemaining);

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      border: Border.all(
        color: prayerColor.withValues(alpha: 0.32),
        width: 1.5,
      ),
      child: Container(
        padding: const EdgeInsetsDirectional.all(AppSpace.xl),
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgRadius,
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              prayerColor.withValues(alpha: 0.10),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Next Prayer Badge & Time Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.md,
                        vertical: AppSpace.xs,
                      ),
                      decoration: BoxDecoration(
                        color: prayerColor.withValues(alpha: 0.14),
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(
                          color: prayerColor.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: prayerColor,
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            AppStrings.prayerNext,
                            style: context.text.caption.copyWith(
                              color: prayerColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          prayerColor.withValues(alpha: 0.16),
                          prayerColor.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: prayerColor.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: AppIcon.sm,
                          color: prayerColor,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          formatPrayerTime12h(prayer.time),
                          style: context.text.label.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),

            // Prayer Title with Accent Color
            Center(
              child: Text(
                'صلاة ${prayer.prayer.labelAr}',
                style: context.text.sacredLarge.copyWith(
                  color: palette.text,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xs),

            // Countdown text with Tabular Figures
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  countdown,
                  style: context.text.display.copyWith(
                    color: prayerColor,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),

            // Progress Bar with Prayer Color
            AppProgress(
              progress: progress.clamp(0.0, 1.0),
              color: prayerColor,
            ),
          ],
        ),
      ),
    );
  }
}
