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
    final countdown = countdownText ??
        AppStrings.prayerInMinutes(prayer.minutesRemaining);

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: responsive.wp(92)),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(responsive.wp(5)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFFFFBF5), Color(0xFFFFF8E7)],
            ),
            borderRadius: BorderRadius.circular(AppUi.radiusMD),
            border: Border.all(
              color: const Color(0xFFE8DCC8),
              width: AppUi.dividerThickness,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B7355).withValues(alpha: 0.08),
                blurRadius: responsive.sp(12),
                offset: Offset(0, responsive.sp(3)),
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
                        color: const Color(0xFF8B7355),
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
                          color: const Color(0xFF8B7355),
                        ),
                        SizedBox(width: responsive.smallGap * 0.5),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.wp(2.2),
                            vertical: responsive.hp(0.6),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFB8860B,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppUi.radiusPill,
                            ),
                          ),
                          child: Text(
                            _formatTime(prayer.time),
                            style: TextStyle(
                              fontSize: responsive.sp(13),
                              color: const Color(0xFF2C1810),
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
                  color: const Color(0xFF2C1810),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: responsive.smallGap * 0.5),
              Text(
                countdown,
                style: TextStyle(
                  fontSize: responsive.sp(26),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFB8860B),
                  height: 1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: responsive.smallGap),
              ClipRRect(
                borderRadius: BorderRadius.circular(responsive.sp(2)),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(
                    0xFFE8DCC8,
                  ).withValues(alpha: 0.5),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFB8860B)),
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
