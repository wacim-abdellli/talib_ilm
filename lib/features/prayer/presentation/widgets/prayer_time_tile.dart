import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_colors.dart';

import '../models/prayer_time.dart';

class PrayerTimeTile extends StatefulWidget {
  final PrayerTime item;
  final VoidCallback? onTap;

  const PrayerTimeTile({super.key, required this.item, this.onTap});

  @override
  State<PrayerTimeTile> createState() => _PrayerTimeTileState();
}

class _PrayerTimeTileState extends State<PrayerTimeTile>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.item.isCurrent) {
      _pulseController = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      )..repeat(reverse: true);

      _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCurrent = widget.item.isCurrent;
    final isPassed = _isPassed(widget.item);

    final prayerColor = _getPrayerColor(widget.item.name);
    final iconData = _getPrayerIcon(widget.item.name);

    Widget buildTile(double pulseValue) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: isCurrent
              ? prayerColor.withValues(alpha: isDark ? 0.16 : 0.08)
              : context.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent
                ? prayerColor
                : context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08),
            width: isCurrent ? 1.5 : 1.0,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: prayerColor.withValues(
                      alpha: (isDark ? 0.35 : 0.18) * pulseValue,
                    ),
                    blurRadius: 16,
                    spreadRadius: -2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    widget.onTap!();
                  },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  // Prayer Icon Medallion
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: prayerColor.withValues(alpha: isDark ? 0.22 : 0.12),
                      border: Border.all(
                        color: prayerColor.withValues(alpha: isDark ? 0.4 : 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isPassed && !isCurrent ? Icons.check_circle_rounded : iconData,
                      size: 24,
                      color: isPassed && !isCurrent
                          ? context.textSecondaryColor
                          : prayerColor,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Prayer Name & Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.item.name,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 17,
                                fontWeight: isCurrent
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isPassed && !isCurrent
                                    ? context.textSecondaryColor
                                    : context.textPrimaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            if (isPassed && !isCurrent) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.done_all_rounded,
                                size: 16,
                                color: context.textTertiaryColor,
                              ),
                            ],
                          ],
                        ),
                        if (isCurrent) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: prayerColor.withValues(alpha: isDark ? 0.25 : 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "الصلاة الحالية",
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: prayerColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Time
                  Text(
                    widget.item.time,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isCurrent
                          ? prayerColor
                          : (isPassed
                              ? context.textSecondaryColor
                              : context.textPrimaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget content;
    if (isCurrent && _pulseAnimation != null) {
      content = AnimatedBuilder(
        animation: _pulseAnimation!,
        builder: (context, _) => buildTile(_pulseAnimation!.value),
      );
    } else {
      content = buildTile(1.0);
    }

    return Opacity(
      opacity: isPassed && !isCurrent ? 0.72 : 1.0,
      child: content,
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

  Color _getPrayerColor(String name) {
    if (name.contains(AppStrings.prayerFajr) || name == 'الفجر') {
      return AppColors.fajr;
    }
    if (name == 'الشروق') return AppColors.sunrise;
    if (name.contains(AppStrings.prayerDhuhr) || name == 'الظهر') {
      return AppColors.dhuhr;
    }
    if (name.contains(AppStrings.prayerAsr) || name == 'العصر') {
      return AppColors.asr;
    }
    if (name.contains(AppStrings.prayerMaghrib) || name == 'المغرب') {
      return AppColors.maghrib;
    }
    if (name.contains(AppStrings.prayerIsha) || name == 'العشاء') {
      return AppColors.isha;
    }
    return AppColors.primary;
  }

  IconData _getPrayerIcon(String name) {
    if (name.contains(AppStrings.prayerFajr) || name == 'الفجر') {
      return Icons.wb_twilight_rounded;
    }
    if (name.contains(AppStrings.prayerDhuhr) || name == 'الظهر') {
      return Icons.wb_sunny_rounded;
    }
    if (name.contains(AppStrings.prayerAsr) || name == 'العصر') {
      return Icons.wb_sunny_outlined;
    }
    if (name.contains(AppStrings.prayerMaghrib) || name == 'المغرب') {
      return Icons.wb_twilight_rounded;
    }
    if (name.contains(AppStrings.prayerIsha) || name == 'العشاء') {
      return Icons.nights_stay_rounded;
    }
    return Icons.access_time_rounded;
  }
}
