import 'package:flutter/material.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../app/theme/app_ui.dart';
import '../models/prayer_time.dart';

class PrayerTimeTile extends StatelessWidget {
  final PrayerTime item;
  final VoidCallback? onBeforeAdhkar;
  final VoidCallback? onAfterAdhkar;

  const PrayerTimeTile({
    super.key,
    required this.item,
    this.onBeforeAdhkar,
    this.onAfterAdhkar,
  });

  @override
  Widget build(BuildContext context) {
    final isNext = item.isNext;
    final isCurrent = item.isCurrent;
    final showStatus = isNext || isCurrent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppUi.gapMD,
        vertical: AppUi.gapSM,
      ),
      margin: const EdgeInsets.only(bottom: AppUi.gapSM),
      decoration: BoxDecoration(
        // 🔑 Normal surface only (no elevation)
        gradient: AppColors.surfaceGradient,
        borderRadius: BorderRadius.circular(AppUi.radiusMD),

        // Subtle structure without depth
        border: Border.all(
          color: AppColors.stroke,
          width: AppUi.dividerThickness,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: AppText.body,
                ),
              ),
              if (showStatus) ...[
                _StatusBadge(
                  label: isCurrent
                      ? AppStrings.prayerCurrentBadge
                      : AppStrings.prayerNextBadge,
                ),
                const SizedBox(width: AppUi.gapSM),
              ],
              Text(
                item.time,
                style: AppText.bodyMuted,
              ),
            ],
          ),
          const SizedBox(height: AppUi.gapXS),
          Row(
            children: [
              _AdhkarLink(
                label: AppStrings.beforePrayerDhikr,
                onTap: onBeforeAdhkar,
              ),
              const SizedBox(width: AppUi.gapMD),
              _AdhkarLink(
                label: AppStrings.afterPrayerDhikr,
                onTap: onAfterAdhkar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdhkarLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _AdhkarLink({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppUi.radiusXS),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppUi.gapXS,
          vertical: AppUi.gapXXS,
        ),
        child: Text(
          label,
          style: AppText.caption,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppUi.gapSM,
        vertical: AppUi.gapXXSPlus,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppUi.radiusPill),
        border: Border.all(
          color: AppColors.stroke,
          width: AppUi.dividerThickness,
        ),
      ),
      child: Text(
        label,
        style: AppText.caption,
      ),
    );
  }
}
