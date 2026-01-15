import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/app_ui.dart';
import 'pressable_scale.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: AppUi.cardPadding.copyWith(
          top: AppUi.gapXL,
          bottom: AppUi.gapXL,
        ),
        decoration: BoxDecoration(
          gradient: AppColors.surfaceElevatedGradient,
          borderRadius: BorderRadius.circular(AppUi.radiusMD),
          border: Border.all(
            color: AppColors.stroke,
            width: AppUi.dividerThickness,
          ),
          boxShadow: AppUi.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Illustration(icon: icon),
            const SizedBox(height: AppUi.gapLG),
            Text(title, style: AppText.heading),
            const SizedBox(height: AppUi.gapSM),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.bodyMuted,
            ),
            const SizedBox(height: AppUi.gapLG),
            PressableScale(
              enabled: onAction != null,
              child: FilledButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  final IconData icon;

  const _Illustration({required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppUi.emptyIllustrationSize,
      height: AppUi.emptyIllustrationSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: AppUi.emptyIllustrationSize,
            height: AppUi.emptyIllustrationSize,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppUi.radiusXXL),
              border: Border.all(
                color: AppColors.stroke,
                width: AppUi.dividerThickness,
              ),
            ),
          ),
          Container(
            width: AppUi.emptyIllustrationInnerSize,
            height: AppUi.emptyIllustrationInnerSize,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppUi.radiusSMPlus),
              border: Border.all(
                color: AppColors.stroke,
                width: AppUi.dividerThickness,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
