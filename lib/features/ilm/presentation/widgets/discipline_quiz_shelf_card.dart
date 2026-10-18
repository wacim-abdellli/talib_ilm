import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../data/models/islamic_quiz_models.dart';
import 'mutun_rosette_icon.dart';

/// An inspiring challenge card featured directly on the horizontal bookshelf.
/// Encourages students to test and solidify their mastery in the specific discipline.
class DisciplineQuizShelfCard extends StatelessWidget {
  final FanQuiz fan;
  final VoidCallback onOpenQuiz;

  const DisciplineQuizShelfCard({
    super.key,
    required this.fan,
    required this.onOpenQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return SizedBox(
      width: 172,
      child: Semantics(
        button: true,
        label: 'تحدي واختبار ${fan.title}',
        child: Material(
          color: palette.goldSoft,
          borderRadius: AppRadius.mdRadius,
          child: InkWell(
            borderRadius: AppRadius.mdRadius,
            onTap: () {
              HapticFeedback.selectionClick();
              onOpenQuiz();
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.mdRadius,
                border: Border.all(
                  color: palette.gold.withAlpha(160),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsetsDirectional.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Emblem & Trophy
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                        decoration: BoxDecoration(
                          color: palette.gold.withAlpha(40),
                          borderRadius: AppRadius.smRadius,
                        ),
                        child: Icon(
                          Icons.emoji_events_rounded,
                          size: AppIcon.sm,
                          color: palette.gold,
                        ),
                      ),
                      const Spacer(),
                      MutunRosetteIcon(
                        size: AppIcon.sm,
                        color: palette.gold,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpace.sm),

                  // Title: Discipline Quiz
                  Text(
                    'اختبار ${fan.title}',
                    style: textTheme.titleSmall.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppSpace.xxs),

                  // Question count & levels
                  Expanded(
                    child: Text(
                      '${fan.totalQuestions} سؤالاً موثقاً • ${fan.levels.length} مستويات',
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: AppSpace.xs),

                  // Bottom Action Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: palette.gold.withAlpha(120),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ابدأ الاختبار',
                          style: textTheme.caption.copyWith(
                            color: palette.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: AppIcon.xs,
                          color: palette.gold,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
