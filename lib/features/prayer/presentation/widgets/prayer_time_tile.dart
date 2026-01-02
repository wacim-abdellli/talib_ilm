import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
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
    final icon = _iconFor(item.name);
    final isNext = item.isNext;
    final isCurrent = item.isCurrent;
    final statusColor = isNext
        ? AppColors.primaryAlt
        : isCurrent
            ? AppColors.success
            : AppColors.textSecondary;
    final backgroundGradient = LinearGradient(
      colors: [
        _tint(statusColor, isNext || isCurrent ? 0.18 : 0.04),
        _tint(AppColors.surface, 0.0),
      ],
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
    );
    final borderColor = isNext || isCurrent
        ? statusColor.withValues(alpha: 0.35)
        : AppColors.textPrimary.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: AppText.body.copyWith(
                    color: primary,
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

  IconData _iconFor(String name) {
    switch (name) {
      case 'الفجر':
        return Icons.wb_twilight_outlined;
      case 'الظهر':
        return Icons.wb_sunny_outlined;
      case 'العصر':
        return Icons.wb_sunny_outlined;
      case 'المغرب':
        return Icons.wb_twilight_outlined;
      case 'العشاء':
        return Icons.nights_stay_outlined;
    }
    return Icons.access_time;
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

Color _tint(Color color, double amount) {
  return Color.lerp(AppColors.surface, color, amount) ?? color;
}
