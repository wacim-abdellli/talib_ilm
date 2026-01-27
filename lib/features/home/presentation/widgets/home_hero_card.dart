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

    // === M3 ANTICIPATION-DRIVEN STYLING ===
    // Surface: High container (Anchor)
    final backgroundColor = context.surfaceHigh;

    // Border: Subtle outline, gets slightly thicker when very near
    final borderColor = isVeryNear
        ? context.primaryColor.withValues(alpha: 0.5)
        : context.outlineVariantColor;

    // Shadow: Soft elevation
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.05);
    final elevationBlur = isVeryNear ? 16.0 : 8.0;
    final elevationOffset = isVeryNear ? 4.0 : 2.0;

    // Gold ring (Sacred accent) - Keep clean
    // unused: final goldRing = context.goldRingColor;

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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16), // Aligned margins
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
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: borderColor,
                  width: 1, // Keep thin and elegant
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
                padding: const EdgeInsets.all(24), // More air
                child: Column(
                  children: [
                    // Top Row: Status Chip + Mosque Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Chip (M3 Secondary Container)
                        if (nearnessLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.isDark
                                  ? context.goldColor.withValues(alpha: 0.15)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              nearnessLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.isDark
                                    ? context.goldColor
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          const Spacer(),

                        // Sacred Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.outlineVariantColor,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.mosque_outlined,
                            size: 24,
                            color: context.textSecondaryColor,
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
                              // FIXED: Cairo font, NOT Roboto
                              ExcludeSemantics(
                                child: Text(
                                  timeString,
                                  style: TextStyle(
                                    fontSize: 36, // Larger, premium
                                    color: context.textPrimaryColor,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                    letterSpacing:
                                        0, // No letter spacing for numbers in Arabic context
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
                                fontSize: 24,
                                color: context
                                    .primaryColor, // Use primary brand color
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
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
    if (minutes <= 0) return 'حان الوقت';
    if (minutes <= 5)
      return 'قريبًا جدا'; // No tanween to avoid font issues maybe? kept simple
    if (minutes <= 15) return 'قريب';
    if (minutes <= 30) return 'يقترب';
    return 'القادمة'; // Always show status
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
