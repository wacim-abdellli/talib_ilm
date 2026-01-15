import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/pressable_scale.dart';

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppUi.radiusMD);
    final borderColor = AppColors.primary.withValues(alpha: 0.15);
    final baseShadow = [
      BoxShadow(
        color: AppColors.primaryDark.withValues(alpha: 0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
    final pressedShadow = [
      BoxShadow(
        color: AppColors.primaryDark.withValues(alpha: 0.12),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];

    var isPressed = false;
    return PressableScale(
      pressedScale: 0.94,
      duration: const Duration(milliseconds: 100),
      child: StatefulBuilder(
        builder: (context, setState) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: radius,
              border: Border.all(color: borderColor),
              boxShadow: isPressed ? pressedShadow : baseShadow,
            ),
            child: Material(
              color: AppColors.clear,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                onHighlightChanged: (value) {
                  setState(() => isPressed = value);
                },
                splashColor: AppColors.primary.withValues(alpha: 0.12),
                highlightColor: AppColors.primary.withValues(alpha: 0.04),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 28,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppUi.gapXSPlus),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
