import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../data/models/islamic_quiz_models.dart';

/// Educational assistance tools ("وسائل المساعدة العلمية") for Islamic quizzes:
/// 1. 50:50 (حذف خيارين غير صحيحين)
/// 2. Scholarly Clue / Hint (إضاءة وتلميح من المصادر المعتمدة)
class QuizLifelinesBar extends StatelessWidget {
  final QuizQuestion question;
  final bool isAnswered;
  final int fiftyFiftyRemaining;
  final bool isFiftyFiftyUsedOnCurrent;
  final VoidCallback onUseFiftyFifty;
  final int hintRemaining;
  final bool isHintRevealed;
  final VoidCallback onUseHint;

  const QuizLifelinesBar({
    super.key,
    required this.question,
    required this.isAnswered,
    required this.fiftyFiftyRemaining,
    required this.isFiftyFiftyUsedOnCurrent,
    required this.onUseFiftyFifty,
    required this.hintRemaining,
    required this.isHintRevealed,
    required this.onUseHint,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final canFiftyFifty =
        !isAnswered && !isFiftyFiftyUsedOnCurrent && fiftyFiftyRemaining > 0;
    final canHint = !isAnswered && !isHintRevealed && hintRemaining > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lifelines Action Buttons Row
        Row(
          children: [
            // 50:50 Lifeline Button
            Expanded(
              child: Semantics(
                button: true,
                label: 'حذف خيارين، المتبقي $fiftyFiftyRemaining',
                child: Material(
                  color: canFiftyFifty ? palette.surface : palette.surfaceMuted,
                  borderRadius: AppRadius.mdRadius,
                  child: InkWell(
                    borderRadius: AppRadius.mdRadius,
                    onTap: canFiftyFifty
                        ? () {
                            HapticFeedback.selectionClick();
                            onUseFiftyFifty();
                          }
                        : null,
                    child: Container(
                      height: AppSize.buttonH,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.sm,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.mdRadius,
                        border: Border.all(
                          color: canFiftyFifty
                              ? palette.primary.withAlpha(120)
                              : palette.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pie_chart_outline_rounded,
                            size: AppIcon.sm,
                            color: canFiftyFifty
                                ? palette.primary
                                : palette.textSubtle,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            'حذف إجابتين',
                            style: textTheme.caption.copyWith(
                              color: canFiftyFifty
                                  ? palette.text
                                  : palette.textSubtle,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.xs,
                              vertical: AppSpace.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: canFiftyFifty
                                  ? palette.primarySoft
                                  : palette.surface,
                              borderRadius: AppRadius.pillRadius,
                            ),
                            child: Text(
                              '$fiftyFiftyRemaining',
                              style: textTheme.caption.copyWith(
                                color: canFiftyFifty
                                    ? palette.primary
                                    : palette.textSubtle,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),

            // Scholarly Clue / Hint Button
            Expanded(
              child: Semantics(
                button: true,
                label: 'إضاءة وتلميح، المتبقي $hintRemaining',
                child: Material(
                  color: canHint ? palette.goldSoft : palette.surfaceMuted,
                  borderRadius: AppRadius.mdRadius,
                  child: InkWell(
                    borderRadius: AppRadius.mdRadius,
                    onTap: canHint
                        ? () {
                            HapticFeedback.selectionClick();
                            onUseHint();
                          }
                        : null,
                    child: Container(
                      height: AppSize.buttonH,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.sm,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.mdRadius,
                        border: Border.all(
                          color: canHint
                              ? palette.gold.withAlpha(140)
                              : palette.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: AppIcon.sm,
                            color: canHint ? palette.gold : palette.textSubtle,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            'إضاءة وتلميح',
                            style: textTheme.caption.copyWith(
                              color:
                                  canHint ? palette.text : palette.textSubtle,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.xs,
                              vertical: AppSpace.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: canHint
                                  ? palette.surface
                                  : palette.surfaceMuted,
                              borderRadius: AppRadius.pillRadius,
                            ),
                            child: Text(
                              '$hintRemaining',
                              style: textTheme.caption.copyWith(
                                color:
                                  canHint ? palette.gold : palette.textSubtle,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Hint Reveal Card (Shown when requested)
        if (isHintRevealed) ...[
          const SizedBox(height: AppSpace.sm),
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            decoration: BoxDecoration(
              color: palette.goldSoft,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: palette.gold.withAlpha(150),
                width: 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: AppIcon.sm,
                  color: palette.gold,
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إضاءة علمية للاستنباط والتأمل:',
                        style: textTheme.caption.copyWith(
                          color: palette.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        'موضع المسألة مستفاد من: ${question.reference}. تأمل النص واقترب من المعنى الأوفق بالدليل.',
                        style: textTheme.caption.copyWith(
                          color: palette.text,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
