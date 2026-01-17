import 'package:flutter/material.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_ui.dart';
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

    final countdown =
        countdownText ?? AppStrings.prayerInMinutes(prayer.minutesRemaining);

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: responsive.wp(92)),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(responsive.wp(5)),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0A0A0A)
                : const Color(0xFFF5F3F0), // SurfaceCard
            borderRadius: BorderRadius.circular(AppUi.radiusMD),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF1F1F1F)
                  : const Color(0xFFE8E6E3), // BorderSubtle
              width: AppUi.dividerThickness,
            ),
            boxShadow: [
              if (isDark)
                BoxShadow(
                  color: const Color(0xFF00D9C0).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                )
              else
                BoxShadow(
                  color: const Color(0xFF3A3A3A).withValues(alpha: 0.04),
                  blurRadius: responsive.sp(10),
                  offset: Offset(0, responsive.sp(2)),
                ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.prayerNext,
                      style: TextStyle(
                        fontSize: responsive.sp(12),
                        color: isDark
                            ? const Color(0xFFA1A1A1)
                            : const Color(0xFF6E6E6E), // TextSecondary
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: responsive.smallGap),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: responsive.sp(13),
                          color: isDark
                              ? const Color(0xFFA1A1A1)
                              : const Color(0xFF9A9A9A), // Muted icon
                        ),
                        SizedBox(width: responsive.smallGap * 0.5),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.wp(2.2),
                            vertical: responsive.hp(0.6),
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF141414)
                                : const Color(
                                    0xFF5B8A8A,
                                  ).withValues(alpha: 0.1), // Muted teal bg
                            borderRadius: BorderRadius.circular(
                              AppUi.radiusPill,
                            ),
                          ),
                          child: Text(
                            _formatTime(prayer.time),
                            style: TextStyle(
                              fontSize: responsive.sp(13),
                              color: isDark
                                  ? const Color(0xFF00D9C0)
                                  : const Color(0xFF3A3A3A),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.smallGap),
              Text(
                prayer.prayer.labelAr,
                style: TextStyle(
                  fontSize: responsive.sp(22),
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF3A3A3A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: responsive.smallGap * 0.5),
              Text(
                countdown,
                style: TextStyle(
                  fontSize: responsive.sp(26),
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFF00D9C0)
                      : const Color(0xFF2A2A2A),
                  height: 1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: responsive.smallGap),
              ClipRRect(
                borderRadius: BorderRadius.circular(responsive.sp(2)),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark
                      ? const Color(0xFF1F1F1F)
                      : const Color(0xFFE8E6E3),
                  valueColor: AlwaysStoppedAnimation(
                    isDark ? const Color(0xFF00D9C0) : const Color(0xFF6A9A9A),
                  ), // PrimaryAccent
                  minHeight: responsive.sp(3),
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
