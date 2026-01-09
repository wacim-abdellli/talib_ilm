import 'package:flutter/material.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/pressable_card.dart';

class HomeSectionCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isPrimary;

  const HomeSectionCard({
    super.key,
    required this.child,
    this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppUi.radiusMD);

    return SizedBox(
      width: double.infinity,
      child: PressableCard(
        onTap: onTap,
        padding: AppUi.buttonPaddingCompact,
        borderRadius: radius,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.surfaceElevated : AppColors.surface,
          borderRadius: radius,
          border: Border.all(
            color: AppColors.stroke,
            width: AppUi.dividerThickness,
          ),
        ),
        child: child,
      ),
    );
  }
}
