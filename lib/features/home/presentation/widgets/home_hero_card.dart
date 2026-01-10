import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/pressable_card.dart';

class HomeHeroCard extends StatelessWidget {
  final String greeting;
  final String countdown;
  final String dateLabel;
  final String locationLabel;
  final IconData locationIcon;
  final VoidCallback? onTap;

  const HomeHeroCard({
    super.key,
    required this.greeting,
    required this.countdown,
    required this.dateLabel,
    required this.locationLabel,
    this.locationIcon = Icons.location_on_outlined,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppUi.radiusLG);

    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: PressableCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppUi.paddingCard,
          vertical: AppUi.gapXL,
        ),
        borderRadius: radius,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
            ],
          ),
          borderRadius: radius,
          border: Border.all(
            color: AppColors.secondary.withOpacity(0.35),
            width: AppUi.dividerThickness,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  locationIcon,
                  size: AppUi.iconSizeSM,
                  color: Colors.white70,
                ),
                const SizedBox(width: AppUi.gapXS),
                Expanded(
                  child: Text(
                    locationLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppUi.gapMD),
            Text(
              greeting,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppUi.gapSM),
            Text(
              countdown,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: AppUi.gapSM),
            Text(
              dateLabel,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
