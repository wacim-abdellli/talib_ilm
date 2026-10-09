import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../../app/theme/app_palette.dart';

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
              style: context.text.bodySmall.copyWith(
                color: context.palette.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),

            // Hijri Date - Spiritual Context
            if (hijriStr.isNotEmpty)
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: context.palette.primarySoft,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: context.palette.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: AppIcon.sm,
                      color: context.palette.primary,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      hijriStr,
                      style: context.text.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.palette.onPrimarySoft,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: AppSpace.md),

        // Row 2: Logo + Greeting + Location
        Row(
          children: [
            // App Logo
            Image.asset(
              'assets/images/logo.png',
              width: AppSize.buttonH,
              height: AppSize.buttonH,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: AppSpace.md),

            // Greeting
            Expanded(
              child: Text(
                greeting,
                style: context.text.titleSmall.copyWith(
                  color: context.palette.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Location
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: AppIcon.sm,
                  color: context.palette.primary,
                ),
                const SizedBox(width: AppSpace.xs),
                Text(
                  city,
                  style: context.text.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.palette.textMuted,
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
