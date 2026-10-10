import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../../app/theme/app_palette.dart';

class HomeHeader extends StatelessWidget {
  final String city;
  final String greeting;
  final String? greetingSubtitle;

  const HomeHeader({
    super.key,
    required this.city,
    required this.greeting,
    this.greetingSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final date = DateTime.now();

    String hijriStr = '';
    try {
      HijriCalendar.setLocal('ar');
      final h = HijriCalendar.fromDate(date);
      hijriStr = '${h.hDay} ${h.longMonthName} ${h.hYear} هـ';
    } catch (_) {}

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Start: Official Black Emblem + Spiritual Greeting + Location
        Expanded(
          child: Row(
            children: [
              // Premium Obsidian Emblem Badge with Subtle Gold Accent
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.brandDark,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: palette.gold.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: palette.shadow,
                ),
                padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                child: ClipRRect(
                  borderRadius: AppRadius.smRadius,
                  child: Image.asset(
                    palette.logoSymbol,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),

              // Dignified Islamic Greeting & Contextual Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      greeting,
                      style: textTheme.titleSmall.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: AppIcon.sm,
                          color: palette.primary,
                        ),
                        const SizedBox(width: AppSpace.xs / 2),
                        Flexible(
                          child: Text(
                            city,
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: AppSpace.sm),

        // End: Hijri Date Illuminated Jewel Pill
        if (hijriStr.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.xs + 2,
              ),
              decoration: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: AppRadius.pillRadius,
                border: Border.all(
                  color: palette.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: palette.shadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: AppIcon.sm,
                    color: palette.onPrimarySoft,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    hijriStr,
                    style: textTheme.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.onPrimarySoft,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
