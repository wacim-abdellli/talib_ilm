import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_ui.dart';
import '../../app/theme/app_spacing.dart';
import 'pressable_scale.dart';

class PressableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const PressableCard({
    super.key,
    required this.child,
    required this.decoration,
    required this.padding,
    required this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      enabled: onTap != null,
      child: AnimatedContainer(
        duration: AppSpacing.animQuick,
        curve: Curves.easeOut,
        decoration: decoration.copyWith(boxShadow: AppShadows.card),
        child: Material(
          color: AppColors.surfaceElevated.withValues(alpha: 0),
          child: InkWell(
            borderRadius: borderRadius,
            splashColor: AppColors.clear,
            highlightColor: AppColors.clear,
            overlayColor: WidgetStatePropertyAll(AppColors.clear),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppUi.buttonMinHeight,
              ),
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
