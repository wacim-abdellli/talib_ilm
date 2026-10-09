import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_colors.dart';
import '../../../../shared/widgets/pressable_scale.dart';
/// HomeHeroCard - Celestial Prayer Time Centerpiece
class HomeHeroCard extends StatefulWidget {
  final String nextPrayerName;
  final DateTime nextPrayerTime;
  final bool isEstimated;
  final Map<String, DateTime>? allPrayers;
  final VoidCallback? onTap;
  const HomeHeroCard({
    super.key,
    required this.nextPrayerName,
    required this.nextPrayerTime,
    this.isEstimated = false,
    this.allPrayers,
    this.onTap,
  });
  @override
  State<HomeHeroCard> createState() => _HomeHeroCardState();
}
class _HomeHeroCardState extends State<HomeHeroCard> {
  late Timer _timer;
  late Duration _timeLeft;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(_getTimerDuration(), (_) {
      _updateTimeLeft();
      if (_timeLeft.inMinutes < 1 && _timer.tick % 60 != 0) {
        _resetTimer();
      }
    });
  }

  Duration _getTimerDuration() {
    return _timeLeft.inMinutes < 1
        ? const Duration(seconds: 1)
        : const Duration(minutes: 1);
  }

  void _resetTimer() {
    _timer.cancel();
    _startTimer();
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    final diff = widget.nextPrayerTime.difference(now);
    if (mounted) {
      final newTime = diff.isNegative ? Duration.zero : diff;
      setState(() => _timeLeft = newTime);
    }
  }

  @override
  void dispose() {
    if (_timer.isActive) _timer.cancel();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_isPressed != value) {
      if (value) HapticFeedback.lightImpact();
      setState(() => _isPressed = value);
    }
  }
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isVeryNear = _timeLeft.inMinutes < 15;
    // Spiritual Serenity gradients
    final gradient = isDark
        ? LinearGradient(
            colors: [
              context.surfaceContainerHigh,
              context.surfaceContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              Colors.white,
              context.surfaceContainerLow,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final borderColor = isVeryNear
        ? AppColors.gold.withValues(alpha: 0.8)
        : (isDark
            ? AppColors.gold.withValues(alpha: 0.25)
            : context.outlineVariantColor);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : AppColors.primaryDark.withValues(alpha: 0.08);
    // Time formatting
    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    final prayerTimeDisplay = intl.DateFormat.jm(
      'ar',
    ).format(widget.nextPrayerTime);
    final nearnessLabel = _getNearnessLabel();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Semantics(
        label: 'الصلاة القادمة: ${widget.nextPrayerName}',
        hint: 'المتبقي ${_getReadableDuration()}',
        button: true,
        onTapHint: 'اضغط لعرض تفاصيل الصلاة',
        child: PressableScale(
          pressedScale: 0.985,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: borderColor,
                  width: isVeryNear ? 1.5 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: isVeryNear ? 20 : 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    // Top Row: Status Chip + Mosque Medallion
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Status Chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isVeryNear
                                ? AppColors.gold.withValues(alpha: isDark ? 0.25 : 0.18)
                                : AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isVeryNear
                                  ? AppColors.gold.withValues(alpha: 0.4)
                                  : AppColors.primary.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isVeryNear
                                      ? AppColors.gold
                                      : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                nearnessLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isVeryNear
                                      ? AppColors.gold
                                      : (isDark ? AppColors.primaryLight : AppColors.primaryDark),
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Sacred Mosque Medallion
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(
                              alpha: isDark ? 0.18 : 0.12,
                            ),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.15),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mosque_rounded,
                            size: 22,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Main Middle Row: Countdown & Prayer Name
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Countdown Display
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الوقت المتبقي',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.textTertiaryColor,
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  _TimeDigitBadge(value: hours, label: 'ساعة', isDark: isDark),
                                  const SizedBox(width: 4),
                                  Text(
                                    ':',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gold,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  _TimeDigitBadge(value: minutes, label: 'دقيقة', isDark: isDark),
                                  const SizedBox(width: 4),
                                  Text(
                                    ':',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gold,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  _TimeDigitBadge(value: seconds, label: 'ثانية', isDark: isDark),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Next Prayer Name & Absolute Time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.nextPrayerName,
                              style: TextStyle(
                                fontSize: 26,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: isDark ? 0.16 : 0.08,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: isDark
                                        ? AppColors.primaryLight
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    prayerTimeDisplay,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.primaryLight
                                          : AppColors.primaryDark,
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Bottom: 5 Daily Prayers Timeline Strip
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? context.surfaceContainerLow
                            : context.surfaceLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.outlineColor.withValues(alpha: isDark ? 0.18 : 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTimelinePrayer(AppStrings.prayerFajr, Icons.nightlight_round, isDark),
                          _buildTimelinePrayer(AppStrings.prayerDhuhr, Icons.wb_sunny_rounded, isDark),
                          _buildTimelinePrayer(AppStrings.prayerAsr, Icons.wb_sunny_outlined, isDark),
                          _buildTimelinePrayer(AppStrings.prayerMaghrib, Icons.wb_twilight_rounded, isDark),
                          _buildTimelinePrayer(AppStrings.prayerIsha, Icons.bedtime_rounded, isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelinePrayer(String prayerName, IconData icon, bool isDark) {
    final isCurrent = widget.nextPrayerName == prayerName;
    final prayerTime = widget.allPrayers?[prayerName];
    final timeStr = prayerTime != null
        ? intl.DateFormat.jm('ar').format(prayerTime)
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: isCurrent
          ? BoxDecoration(
              color: AppColors.gold.withValues(alpha: isDark ? 0.22 : 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.4),
                width: 1,
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: isCurrent
                ? context.goldColor
                : context.textTertiaryColor,
          ),
          const SizedBox(height: 3),
          Text(
            prayerName,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Cairo',
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
              color: isCurrent
                  ? (isDark ? Colors.white : context.goldColor)
                  : context.textSecondaryColor,
            ),
          ),
          if (timeStr.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 9,
                fontFamily: 'Cairo',
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                color: isCurrent
                    ? context.goldColor
                    : context.textTertiaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getNearnessLabel() {
    final minutes = _timeLeft.inMinutes;
    if (minutes <= 0) {
      return 'حان وقت الأذان';
    }
    if (minutes <= 5) {
      return 'يقترب جداً (٥ دقائق)';
    }
    if (minutes <= 15) {
      return 'يقترب وقت الصلاة';
    }
    if (minutes <= 30) {
      return 'خلال نصف ساعة';
    }
    return 'الصلاة القادمة';
  }

  String _getReadableDuration() {
    final hours = _timeLeft.inHours;
    final minutes = _timeLeft.inMinutes % 60;
    if (hours > 0) {
      return '$hours ساعة و $minutes دقيقة';
    }
    return '$minutes دقيقة';
  }
}

class _TimeDigitBadge extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;

  const _TimeDigitBadge({
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? context.surfaceContainerLow
                : context.surfaceLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: context.outlineVariantColor,
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'Cairo',
              color: context.textPrimaryColor,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'Cairo',
            color: context.textTertiaryColor,
          ),
        ),
      ],
    );
  }
}
