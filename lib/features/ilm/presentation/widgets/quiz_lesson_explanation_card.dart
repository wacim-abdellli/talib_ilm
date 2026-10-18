import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../data/models/islamic_quiz_models.dart';

/// Clean card presenting the lesson learned, proof (daleel), and scholarly reference
/// after an Islamic quiz question is answered.
class QuizLessonExplanationCard extends StatelessWidget {
  final QuizQuestion question;
  final bool isUserCorrect;

  const QuizLessonExplanationCard({
    super.key,
    required this.question,
    required this.isUserCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: isUserCorrect ? palette.primarySoft : palette.surfaceMuted,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: isUserCorrect
              ? palette.primary.withAlpha(90)
              : palette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isUserCorrect
                    ? Icons.lightbulb_outline_rounded
                    : Icons.menu_book_rounded,
                color: isUserCorrect ? palette.primary : palette.textMuted,
                size: AppIcon.md,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                'الدرس المستفاد والشرح التوضيحي:',
                style: textTheme.label.copyWith(
                  color: isUserCorrect ? palette.primary : palette.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            question.lesson,
            style: textTheme.bodySmall.copyWith(
              color: palette.text,
              height: 1.6,
            ),
          ),
          if (question.evidence.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.all(AppSpace.md),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadius.smRadius,
                border: Border.all(color: palette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        color: palette.gold,
                        size: AppIcon.sm,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        'الدليل الشرعي:',
                        style: textTheme.caption.copyWith(
                          color: palette.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    question.evidence,
                    style: textTheme.sacred.copyWith(
                      color: palette.text,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (question.reference.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                'المصدر: ${question.reference}',
                style: textTheme.caption.copyWith(
                  color: palette.textSubtle,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
