import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../app/theme/theme_colors.dart';
import '../../../../shared/widgets/pressable_scale.dart';

/// HomeHeroCard - Prayer Time Hero Card (ANTICIPATION-DRIVEN)
class HomeHeroCard extends StatefulWidget {
  final String nextPrayerName;
  final DateTime nextPrayerTime;
  final bool isEstimated;
  final VoidCallback? onTap;

  const HomeHeroCard({
    super.key,
    required this.nextPrayerName,
    required this.nextPrayerTime,
    this.isEstimated = false,
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

    // Start with smart timer frequency
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(_getTimerDuration(), (_) {
      _updateTimeLeft();

      // Check if we need to switch frequency
      // If we entered the last minute, reset to second-level precision
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

    // Thresholds
    final isVeryNear = _timeLeft.inMinutes < 5;

    // === SPIRITUAL SERENITY LUXURY CARD ===
    final gradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF1B2626), Color(0xFF131C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Colors.white, Color(0xFFF9F7F4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final borderColor = isVeryNear
        ? context.goldColor.withValues(alpha: 0.8)
        : (isDark
            ? context.goldColor.withValues(alpha: 0.22)
            : context.outlineVariantColor);

    // Shadow: Soft elevation
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.05);
    final elevationBlur = isVeryNear ? 20.0 : 12.0;
    final elevationOffset = isVeryNear ? 6.0 : 3.0;

    // Time formatting
    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');
    final timeString = '$hours:$minutes:$seconds';

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
          pressedScale: 0.98,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: borderColor,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: elevationBlur,
                    offset: Offset(0, elevationOffset),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Top Row: Status Chip + Mosque Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Chip
                        if (nearnessLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.goldColor.withValues(
                                alpha: isDark ? 0.2 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: context.goldColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              nearnessLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.goldColor,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          const Spacer(),

                        // Sacred Mosque Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.goldColor.withValues(
                              alpha: isDark ? 0.15 : 0.1,
                            ),
                            border: Border.all(
                              color: context.goldColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.mosque_rounded,
                            size: 24,
                            color: context.goldColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Main Content: Time & Name
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Countdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المتبقي',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.textTertiaryColor,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(height: 4),
                              ExcludeSemantics(
                                child: Text(
                                  timeString,
                                  style: TextStyle(
                                    fontSize: 38,
                                    color: isVeryNear
                                        ? context.goldColor
                                        : context.textPrimaryColor,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Prayer Name & Time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.nextPrayerName,
                              style: TextStyle(
                                fontSize: 26,
                                color: context.primaryColor,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: context.textSecondaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  prayerTimeDisplay,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.textSecondaryColor,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
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

  /// Get nearness label logic (aligned to 30min)
  String? _getNearnessLabel() {
    final minutes = _timeLeft.inMinutes;
    if (minutes <= 0) {
      return 'حان الوقت';
    }
    if (minutes <= 5) {
      return 'قريبًا جدا';
    }
    if (minutes <= 15) {
      return 'قريب';
    }
    if (minutes <= 30) {
      return 'يقترب';
    }
    return 'القادمة';
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
