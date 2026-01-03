import 'package:flutter/material.dart';
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
    final colors = Theme.of(context).colorScheme;
    final primary = colors.onSurface;
    final secondary = colors.onSurface.withValues(alpha: 0.6);
    final isNext = item.isNext;
    final isCurrent = item.isCurrent;
    final statusColor = isNext
        ? AppColors.secondary
        : isCurrent
            ? AppColors.secondary
            : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppUi.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: AppText.body.copyWith(
                    color: isNext || isCurrent ? statusColor : primary,
                    fontWeight:
                        isNext || isCurrent ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (isCurrent)
                _StatusBadge(
                  label: 'الحالية',
                  color: statusColor,
                )
              else if (isNext)
                _StatusBadge(
                  label: 'القادمة',
                  color: statusColor,
                ),
              const SizedBox(width: 8),
              Text(
                item.time,
                style: AppText.body.copyWith(
                  color: isNext || isCurrent ? primary : secondary,
                  fontWeight:
                      isNext || isCurrent ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _AdhkarLink(
                label: 'أذكار قبل الصلاة',
                onTap: onBeforeAdhkar,
              ),
              const SizedBox(width: 12),
              _AdhkarLink(
                label: 'أذكار بعد الصلاة',
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
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: AppText.caption.copyWith(
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(color: color),
      ),
    );
  }
}
