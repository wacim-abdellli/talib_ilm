import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/pressable_card.dart';

class HomeHeroCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const HomeHeroCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppUi.radiusXL);

    return PressableCard(
      onTap: onTap,
      padding: AppUi.cardPadding.copyWith(
        top: AppUi.gapXXL,
        bottom: AppUi.gapXXL,
      ),
      borderRadius: radius,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: radius,
        border: Border.all(
          color: AppColors.stroke,
          width: AppUi.dividerThickness,
        ),
      ),
      child: child,
    );
  }
}
