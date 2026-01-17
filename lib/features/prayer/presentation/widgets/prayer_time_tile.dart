import 'package:flutter/material.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';

import '../models/prayer_time.dart';

class PrayerTimeTile extends StatelessWidget {
  final PrayerTime item;
  final VoidCallback? onTap;

  const PrayerTimeTile({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCurrent = item.isCurrent;
    final isPassed = _isPassed(item);

    // Determine colors based on prayer name
    final prayerColor = _getPrayerColor(item.name, isDark);
    final iconData = _getPrayerIcon(item.name);

    return Opacity(
      opacity: isPassed && !isCurrent ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? (isCurrent ? null : const Color(0xFF0A0A0A))
              : (isCurrent
                    ? prayerColor.withValues(alpha: 0.15)
                    : Colors.white),
          gradient: (isDark && isCurrent)
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    prayerColor.withValues(alpha: 0.15),
                    const Color(0xFF0A0A0A),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? (isCurrent
                      ? prayerColor.withValues(alpha: 0.4)
                      : const Color(0xFF1F1F1F))
                : (isCurrent ? prayerColor : const Color(0xFFE7E5E4)),
            width: isCurrent ? (isDark ? 1.5 : 2.0) : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Prayer Icon Circle
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDark && !isCurrent)
                          ? const Color(0xFF141414)
                          : null,
                      gradient: (isDark && !isCurrent)
                          ? null
                          : LinearGradient(
                              colors: [
                                prayerColor.withValues(alpha: 0.2),
                                prayerColor.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                    ),
                    child: Icon(
                      isPassed && !isCurrent ? Icons.check_circle : iconData,
                      size: 28,
                      color: (isDark && !isCurrent)
                          ? const Color(0xFF666666)
                          : (isPassed && !isCurrent
                                ? const Color(0xFF059669) // Green for completed
                                : prayerColor),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Prayer Name & Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isDark
                                ? (isPassed && !isCurrent
                                      ? const Color(
                                          0xFFA1A1A1,
                                        ).withValues(alpha: 0.7)
                                      : (isCurrent
                                            ? Colors.white
                                            : const Color(0xFFA1A1A1)))
                                : (isPassed && !isCurrent
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary),
                            decoration: isPassed && !isCurrent
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (isCurrent) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: prayerColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "الصلاة الحالية",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : prayerColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Time
                  Text(
                    item.time,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      decoration: isPassed && !isCurrent
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isPassed(PrayerTime item) {
    if (item.isCurrent) return false;
    try {
      final now = DateTime.now();
      final parts = item.time.split(':');
      final pTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      return pTime.isBefore(now);
    } catch (e) {
      return false;
    }
  }

  Color _getPrayerColor(String name, bool isDark) {
    if (isDark) {
      if (name == 'الفجر' || name.contains(AppStrings.prayerFajr)) {
        return const Color(0xFF818CF8);
      }
      if (name == 'الشروق') return const Color(0xFFFCD34D); // Sunrise
      if (name == 'الظهر' || name.contains(AppStrings.prayerDhuhr)) {
        return const Color(0xFF00D9C0);
      }
      if (name == 'العصر' || name.contains(AppStrings.prayerAsr)) {
        return const Color(0xFFFF8A3D);
      }
      if (name == 'المغرب' || name.contains(AppStrings.prayerMaghrib)) {
        return const Color(0xFFFF4D9E);
      }
      if (name == 'العشاء' || name.contains(AppStrings.prayerIsha)) {
        return const Color(0xFFA855F7);
      }
    }

    // Using exact Arabic strings for matching
    if (name == 'الفجر') return const Color(0xFF6366F1); // Indigo
    if (name == 'الشروق') return const Color(0xFFFBBF24); // Amber
    if (name == 'الظهر') return const Color(0xFF10B981); // Emerald
    if (name == 'العصر') return const Color(0xFFF59E0B); // Amber
    if (name == 'المغرب') return const Color(0xFFEC4899); // Pink
    if (name == 'العشاء') return const Color(0xFF8B5CF6); // Purple

    // Fallback to AppColors if available
    if (name.contains(AppStrings.prayerFajr)) return AppColors.fajr;
    if (name.contains(AppStrings.prayerDhuhr)) return AppColors.dhuhr;
    if (name.contains(AppStrings.prayerAsr)) return AppColors.asr;
    if (name.contains(AppStrings.prayerMaghrib)) return AppColors.maghrib;
    if (name.contains(AppStrings.prayerIsha)) return AppColors.isha;

    return const Color(0xFF0D9488); // Default teal
  }

  IconData _getPrayerIcon(String name) {
    if (name.contains(AppStrings.prayerFajr) || name == 'الفجر') {
      return Icons.wb_twilight;
    }
    if (name.contains(AppStrings.prayerDhuhr) || name == 'الظهر') {
      return Icons.wb_sunny;
    }
    if (name.contains(AppStrings.prayerAsr) || name == 'العصر') {
      return Icons.wb_sunny_outlined;
    }
    if (name.contains(AppStrings.prayerMaghrib) || name == 'المغرب') {
      return Icons.wb_twilight;
    }
    if (name.contains(AppStrings.prayerIsha) || name == 'العشاء') {
      return Icons.nights_stay;
    }
    return Icons.access_time;
  }
}
