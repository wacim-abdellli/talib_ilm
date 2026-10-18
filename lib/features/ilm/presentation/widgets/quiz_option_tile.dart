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
    Widget? trailingIcon;

    if (isEliminated) {
      bgColor = palette.surfaceMuted;
      borderColor = palette.border;
      textColor = palette.textSubtle;
    } else if (isAnswered) {
      if (isCorrect) {
        bgColor = palette.primarySoft;
        borderColor = palette.primary;
        textColor = palette.onPrimarySoft;
        trailingIcon = Icon(
          Icons.check_circle_rounded,
          color: palette.primary,
          size: AppIcon.md,
        );
      } else if (isSelected) {
        bgColor = palette.errorSoft;
        borderColor = palette.error;
        textColor = palette.error;
        trailingIcon = Icon(
          Icons.cancel_rounded,
          color: palette.error,
          size: AppIcon.md,
        );
      }
    }

    final bool canTap = !isAnswered && !isEliminated && onTap != null;

    return Semantics(
      button: true,
      enabled: canTap,
      label: 'خيار ${_getOptionLetter(index)}: $text',
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
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                // Option Letter Circle
                Container(
                  width: AppSpace.xxl,
                  height: AppSpace.xxl,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEliminated
                        ? palette.surface
                        : palette.surfaceMuted,
                    border: Border.all(color: palette.border),
                  ),
                  child: Text(
                    _getOptionLetter(index),
                    style: textTheme.caption.copyWith(
                      color: isEliminated
                          ? palette.textSubtle
                          : palette.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.md),

                // Option Content Text
                Expanded(
                  child: Text(
                    text,
                    style: textTheme.body.copyWith(
                      color: textColor,
                      height: 1.5,
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
    );
  }
}
