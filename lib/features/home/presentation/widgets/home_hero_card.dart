import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class HomeHeroCard extends StatefulWidget {
  final String nextPrayerName;
  final DateTime nextPrayerTime;

  const HomeHeroCard({
    super.key,
    required this.nextPrayerName,
    required this.nextPrayerTime,
  });

  @override
  State<HomeHeroCard> createState() => _HomeHeroCardState();
}

class _HomeHeroCardState extends State<HomeHeroCard> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTimeLeft(),
    );
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    final diff = widget.nextPrayerTime.difference(now);
    if (mounted) {
      setState(() {
        _timeLeft = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');
    final timeString = '$hours:$minutes:$seconds';
    final prayerTimeDisplay = intl.DateFormat.jm(
      'ar',
    ).format(widget.nextPrayerTime);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Light Mode Defaults
    const lightPrimaryTeal = Color(0xFF5A8A8A);
    const lightPrimaryMint = Color(0xFF7AB5A8);

    // Dark Mode Styling (User Request)
    final containerBg = isDark ? const Color(0xFF0A0A0A) : null;
    final containerGradient = isDark
        ? null
        : const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [lightPrimaryTeal, lightPrimaryMint],
          );
    final containerBorder = isDark
        ? Border.all(color: const Color(0xFF1F1F1F), width: 1)
        : null;
    final shadowColor = isDark
        ? const Color(0xFF00D9C0).withValues(alpha: 0.25)
        : lightPrimaryTeal.withValues(alpha: 0.25);
    final shadowBlur = isDark ? 20.0 : 16.0;
    final shadowOffset = isDark ? const Offset(0, 8) : const Offset(0, 6);
    final shadowSpread = isDark ? -4.0 : 0.0;

    // Icon Stylng
    final iconDecoration = BoxDecoration(
      gradient: isDark
          ? const LinearGradient(colors: [Color(0xFF00D9C0), Color(0xFF00BFA5)])
          : null,
      color: isDark
          ? null
          : Colors.white.withValues(alpha: 0.2), // Light mode glass
      shape: BoxShape.circle,
    );

    // Text & Element Colors
    final prayerNameColor = isDark ? const Color(0xFFA1A1A1) : Colors.white;
    final countdownColor = isDark
        ? const Color(0xFFFFFFFF)
        : Colors.white; // Pure white
    final labelColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.8);

    // Time Pill Styling
    final pillBg = isDark
        ? const Color(0xFF141414)
        : Colors.white.withValues(alpha: 0.2);
    final pillBorder = isDark
        ? Border.all(
            color: const Color(0xFF00D9C0).withValues(alpha: 0.4),
            width: 1.5,
          )
        : null;
    final clockIconColor = isDark
        ? const Color(0xFF00D9C0)
        : Colors.white.withValues(alpha: 0.9);
    final pillTextColor = isDark
        ? const Color(0xFFFFFFFF)
        : Colors.white.withValues(alpha: 0.9);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: containerBg,
        gradient: containerGradient,
        borderRadius: BorderRadius.circular(20),
        border: containerBorder,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: shadowBlur,
            offset: shadowOffset,
            spreadRadius: shadowSpread,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Left: Mosque icon with soft glow
            Container(
              width: 52,
              height: 52,
              decoration: iconDecoration,
              child: const Icon(
                Icons.mosque_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),

            const SizedBox(width: 16),

            // Center: Prayer info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Prayer name - prominent
                  Text(
                    widget.nextPrayerName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: prayerNameColor,
                      fontFamily: 'Cairo',
                    ),
                  ),

                  const SizedBox(height: 6), // Increased spacing slightly
                  // Prayer time pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(8),
                      border: pillBorder,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: clockIconColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          prayerTimeDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: pillTextColor,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Right: Countdown timer
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // "باقي" label
                Text(
                  'باقي',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),

                const SizedBox(height: 2),

                // Countdown
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: countdownColor,
                    fontFamily: 'Roboto',
                    letterSpacing: 0.5,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
