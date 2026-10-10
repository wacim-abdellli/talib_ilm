import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_progress.dart';
import '../../../../shared/widgets/app_tag.dart';
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
    final countdown =
        countdownText ?? AppStrings.prayerInMinutes(prayer.minutesRemaining);

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.xl),
      onTap: onTap,
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
                  child: AppTag(
                    label: AppStrings.prayerNext,
                    fg: palette.onPrimarySoft,
                    bg: palette.primarySoft,
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
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.smRadius,
                    border: Border.all(
                      color: palette.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: AppIcon.sm,
                        color: palette.textMuted,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        formatPrayerTime12h(prayer.time),
                        style: context.text.label.copyWith(
                          color: palette.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),

          // Prayer Title
          Center(
            child: Text(
              'صلاة ${prayer.prayer.labelAr}',
              style: context.text.sacredLarge.copyWith(
                color: palette.text,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xs),

          // Countdown text
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                countdown,
                style: context.text.display.copyWith(
                  color: palette.text,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          // Progress Bar
          AppProgress(
            progress: progress.clamp(0.0, 1.0),
          ),
        ],
      ),
    );
  }
}
