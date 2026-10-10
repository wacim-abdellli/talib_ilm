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
  final VoidCallback? onOpenQibla;
  final VoidCallback? onOpenAdhkar;
  final VoidCallback? onOpenSettings;

  const NextPrayerCard({
    super.key,
    required this.prayer,
    required this.onTap,
    this.countdownText,
    this.progress = 0.0,
    this.onOpenQibla,
    this.onOpenAdhkar,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final prayerColor = palette.prayer(prayer.prayer.labelAr);
    final countdown =
        countdownText ?? AppStrings.prayerInMinutes(prayer.minutesRemaining);

    return AppCard(
      padding: EdgeInsets.zero,
      color: palette.surfaceRaised,
      border: Border.all(
        color: palette.border,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Next Prayer Pill & Time Badge
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
                        color: palette.surfaceMuted,
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(
                          color: palette.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: AppSpace.sm,
                            height: AppSpace.sm,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: prayerColor,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Text(
                            AppStrings.prayerNext,
                            style: context.text.label.copyWith(
                              color: palette.textMuted,
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
                      color: palette.surfaceMuted,
                      borderRadius: AppRadius.pillRadius,
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
                          color: palette.gold,
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

            // Prayer Title
            Center(
              child: Text(
                'صلاة ${prayer.prayer.labelAr}',
                style: context.text.sacredLarge.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xs),

            // Subtitle
            Center(
              child: Text(
                'الوقت المتبقي حتى الأذان',
                style: context.text.caption.copyWith(
                  color: palette.textMuted,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sm),

            // Tabular Digital Countdown
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  countdown,
                  style: context.text.display.copyWith(
                    color: palette.text,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),

            // Progress Bar with Gold accent fill
            AppProgress(
              progress: progress.clamp(0.0, 1.0),
              color: palette.gold,
            ),

            // Optional Quick Actions row
            if (onOpenQibla != null || onOpenAdhkar != null || onOpenSettings != null) ...[
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  if (onOpenQibla != null)
                    Expanded(
                      child: _HeroActionButton(
                        icon: Icons.explore_outlined,
                        label: 'القبلة',
                        onTap: onOpenQibla!,
                      ),
                    ),
                  if (onOpenQibla != null && (onOpenAdhkar != null || onOpenSettings != null))
                    const SizedBox(width: AppSpace.sm),
                  if (onOpenAdhkar != null)
                    Expanded(
                      child: _HeroActionButton(
                        icon: Icons.auto_stories_outlined,
                        label: 'الأذكار',
                        onTap: onOpenAdhkar!,
                      ),
                    ),
                  if (onOpenAdhkar != null && onOpenSettings != null)
                    const SizedBox(width: AppSpace.sm),
                  if (onOpenSettings != null)
                    Expanded(
                      child: _HeroActionButton(
                        icon: Icons.tune_rounded,
                        label: 'التنبيهات',
                        onTap: onOpenSettings!,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdRadius,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.sm,
          ),
          constraints: const BoxConstraints(
            minHeight: AppSize.tap,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: palette.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: palette.textMuted,
                size: AppIcon.sm,
              ),
              const SizedBox(width: AppSpace.xs),
              Flexible(
                child: Text(
                  label,
                  style: context.text.label.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
