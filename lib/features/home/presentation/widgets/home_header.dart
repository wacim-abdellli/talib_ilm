import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../../app/theme/theme_colors.dart';

class HomeHeader extends StatelessWidget {
  final String city;
  final String greeting;

  const HomeHeader({
    super.key,
    required this.city,
    required this.greeting,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.now();
    String hijriStr = '';
    try {
      HijriCalendar.setLocal('ar');
      final h = HijriCalendar.fromDate(date);
      hijriStr = '${h.hDay} ${h.longMonthName} ${h.hYear} هـ';
    } catch (_) {}

    return Column(
      children: [
        // Row 1: Dates (Gregorian + Hijri)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Gregorian Date
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: TextStyle(
                fontSize: 14,
                color: context.textPrimaryColor,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
              ),
            ),

            // Hijri Date - Spiritual Context
            if (hijriStr.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: context.islamicGreenMutedColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: context.islamicGreenLightColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: context.islamicGreenLightColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hijriStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Row 2: Logo + Greeting + Location
        Row(
          children: [
            // App Logo
            Image.asset(
              'assets/images/logo.png',
              width: 52,
              height: 52,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),

            // Greeting
            Text(
              greeting,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
                fontFamily: 'Cairo',
              ),
            ),

            const Spacer(),

            // Location with enhanced icon
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: context.islamicGreenLightColor,
                ),
                const SizedBox(width: 6),
                Text(
                  city,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondaryColor,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
