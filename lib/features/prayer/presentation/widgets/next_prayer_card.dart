import 'package:flutter/material.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_ui.dart';
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
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(AppUi.radiusMD),
            border: Border.all(
              color: context.outlineVariantColor,
              width: AppUi.dividerThickness,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
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
                        color: context.textSecondaryColor,
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
                          color: context.textSecondaryColor,
                        ),
                        SizedBox(width: responsive.smallGap * 0.5),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.wp(2.2),
                            vertical: responsive.hp(0.6),
                          ),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppUi.radiusPill,
                            ),
                          ),
                          child: Text(
                            _formatTime(prayer.time),
                            style: TextStyle(
                              fontSize: responsive.sp(13),
                              color: context.primaryColor,
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
                  color: context.textPrimaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: responsive.smallGap * 0.5),
              Text(
                countdown,
                style: TextStyle(
                  fontSize: responsive.sp(26),
                  fontWeight: FontWeight.w700,
                  color: context.goldColor,
                  height: 1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: responsive.smallGap),
              ClipRRect(
                borderRadius: BorderRadius.circular(responsive.sp(2)),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: context.outlineVariantColor,
                  valueColor: AlwaysStoppedAnimation(context.primaryColor),
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
