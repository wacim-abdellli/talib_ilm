import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_ui.dart';
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
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        decoration: decoration.copyWith(boxShadow: AppUi.cardShadow),
        child: Material(
          color: AppColors.surface.withValues(alpha: 0),
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onTap,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
