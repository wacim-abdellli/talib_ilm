import 'package:flutter/material.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/theme_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/models/prayer_models.dart';

class NextPrayerCard extends StatelessWidget {
  final NextPrayer prayer;
  final VoidCallback onTap;
  final String? countdownText;
  final double progress;

  const NextPrayerCard({
    super.key,
    required this.prayer,
    required this.onTap,
    this.countdownText,
    this.progress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = context.goldColor;
    final primary = context.primaryColor;

    final countdown =
        countdownText ?? AppStrings.prayerInMinutes(prayer.minutesRemaining);

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: responsive.wp(94)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF1E2B2A),
                      const Color(0xFF141F1E),
                    ]
                  : [
                      const Color(0xFFFFFDF8),
                      const Color(0xFFF7F2E7),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: gold.withValues(alpha: isDark ? 0.35 : 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Row: Next Prayer Badge & Time Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 14,
                          color: gold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppStrings.prayerNext,
                          style: TextStyle(
                            fontSize: 12,
                            color: gold,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withValues(
                        alpha: isDark ? 0.2 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(prayer.time),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? context.textPrimaryColor : primary,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Prayer Title
              Text(
                'صلاة ${prayer.prayer.labelAr}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                  fontFamily: 'Amiri',
                ),
              ),
              const SizedBox(height: 2),

              // Countdown text
              Text(
                countdown,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: gold,
                  fontFamily: 'Cairo',
                  letterSpacing: 1.5,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 16),

              // Smooth Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Container(
                      height: 7,
                      width: double.infinity,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 7,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primary,
                              gold,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: gold.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
