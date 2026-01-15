import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/pressable_card.dart';

class HomePrimaryZone extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const HomePrimaryZone({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Responsive max width (Quranly-style)
    final maxWidth = size.width >= 700 ? 560.0 : double.infinity;

    // Responsive padding (breathes on large screens)
    final padding = size.width >= 700
        ? AppUi.cardPadding * 1.2
        : AppUi.cardPadding;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: PressableCard(
          onTap: onTap,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(AppUi.radiusLG),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppUi.radiusLG),
            gradient: AppColors.primaryGradient, // 🔥 LIFE
            border: Border.all(
              color: AppColors.stroke, // subtle separation
            ),
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
