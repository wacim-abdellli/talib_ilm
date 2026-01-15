import 'package:flutter/material.dart';
import 'package:talib_ilm/app/theme/app_text.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/pressable_card.dart';

class HomeHeroCard extends StatelessWidget {
  final String greeting;
  final String locationLabel;
  final IconData locationIcon;
  final String? userName;
  final String hijriDate;
  final VoidCallback? onLocationTap;
  final VoidCallback? onTap;

  const HomeHeroCard({
    super.key,
    required this.greeting,
    required this.locationLabel,
    required this.hijriDate,
    this.locationIcon = Icons.location_on_outlined,
    this.userName,
    this.onLocationTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppUi.radiusLG);

    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      child: PressableCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppUi.paddingLG,
          vertical: AppUi.gapLG,
        ),
        borderRadius: radius,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.primaryLight.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: radius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: onLocationTap,
                      borderRadius: BorderRadius.circular(AppUi.radiusPill),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppUi.gapSM,
                          vertical: AppUi.gapXXS,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              locationIcon,
                              size: AppUi.iconSizeSM,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppUi.gapXS),
                            Text(
                              locationLabel,
                              style: AppText.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppUi.gapMD),
            Text(
              'السلام عليكم',
              style: AppText.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppUi.gapSM),
            Text(
              userName?.trim().isNotEmpty == true
                  ? userName!.trim()
                  : greeting,
              style: AppText.body.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppUi.gapSM),
            Text(
              hijriDate,
              style: AppText.caption.copyWith(
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
