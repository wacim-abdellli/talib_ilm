import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';

/// Interactive multiple choice option tile for Islamic quiz sessions.
/// Displays option letter (أ، ب، ج، د), content, eliminated state (50:50), and verification indicators.
class QuizOptionTile extends StatelessWidget {
  final int index;
  final String text;
  final bool isAnswered;
  final bool isSelected;
  final bool isCorrect;
  final bool isEliminated;
  final VoidCallback? onTap;

  const QuizOptionTile({
    super.key,
    required this.index,
    required this.text,
    required this.isAnswered,
    required this.isSelected,
    required this.isCorrect,
    required this.isEliminated,
    required this.onTap,
  });

  String _getOptionLetter(int index) {
    switch (index) {
      case 0:
        return 'أ';
      case 1:
        return 'ب';
      case 2:
        return 'ج';
      case 3:
        return 'د';
      default:
        return '${index + 1}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    Color bgColor = palette.surface;
    Color borderColor = palette.border;
    Color textColor = palette.text;
    Color medallionBg = palette.surfaceRaised;
    Color medallionBorder = palette.gold.withAlpha(100);
    Color medallionTextColor = palette.gold;
    Widget? trailingIcon;

    if (isEliminated) {
      bgColor = palette.surfaceMuted;
      borderColor = palette.border;
      textColor = palette.textSubtle;
      medallionBg = palette.surfaceMuted;
      medallionBorder = palette.border;
      medallionTextColor = palette.textSubtle;
    } else if (isAnswered) {
      if (isCorrect) {
        bgColor = palette.primarySoft;
        borderColor = palette.primary;
        textColor = palette.onPrimarySoft;
        medallionBg = palette.primary;
        medallionBorder = palette.primary;
        medallionTextColor = palette.onPrimary;
        trailingIcon = Container(
          padding: const EdgeInsetsDirectional.all(AppSpace.xxs),
          decoration: BoxDecoration(
            color: palette.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            color: palette.onPrimary,
            size: AppIcon.sm,
          ),
        );
      } else if (isSelected) {
        bgColor = palette.errorSoft;
        borderColor = palette.error;
        textColor = palette.error;
        medallionBg = palette.error;
        medallionBorder = palette.error;
        medallionTextColor = palette.onPrimary;
        trailingIcon = Container(
          padding: const EdgeInsetsDirectional.all(AppSpace.xxs),
          decoration: BoxDecoration(
            color: palette.error,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close_rounded,
            color: palette.onPrimary,
            size: AppIcon.sm,
          ),
        );
      }
    }

    final bool canTap = !isAnswered && !isEliminated && onTap != null;

    return Semantics(
      button: true,
      enabled: canTap,
      label: 'خيار ${_getOptionLetter(index)}: $text',
      child: AnimatedOpacity(
        duration: AppMotion.base,
        opacity: isEliminated ? 0.4 : 1.0,
        child: Material(
          color: bgColor,
          borderRadius: AppRadius.mdRadius,
          child: InkWell(
            borderRadius: AppRadius.mdRadius,
            onTap: canTap ? onTap : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSize.tap),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.md,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.mdRadius,
                border: Border.all(
                  color: borderColor,
                  width: (isAnswered && (isCorrect || isSelected)) ? 1.8 : 1.2,
                ),
              ),
              child: Row(
                children: [
                  // Scholarly Option Letter Medallion
                  Container(
                    width: AppSpace.xxl,
                    height: AppSpace.xxl,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.smRadius,
                      color: medallionBg,
                      border: Border.all(color: medallionBorder, width: 1.2),
                    ),
                    child: Text(
                      _getOptionLetter(index),
                      style: textTheme.caption.copyWith(
                        color: medallionTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),

                  // Option Content Text
                  Expanded(
                    child: Text(
                      text,
                      style: textTheme.bodyBold.copyWith(
                        color: textColor,
                        height: 1.45,
                        decoration: isEliminated
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),

                  if (trailingIcon != null) ...[
                    const SizedBox(width: AppSpace.sm),
                    trailingIcon,
                  ] else if (isEliminated) ...[
                    const SizedBox(width: AppSpace.sm),
                    Icon(
                      Icons.block_rounded,
                      size: AppIcon.xs,
                      color: palette.textSubtle,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
