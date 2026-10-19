import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../data/models/islamic_quiz_models.dart';
import '../../data/services/quiz_progress_service.dart';

/// Card representing a sequential level in the Islamic science curriculum roadmap.
class FanQuizLevelCard extends StatelessWidget {
  final QuizLevel level;
  final bool isUnlocked;
  final bool isCompleted;
  final bool hasActiveSession;
  final QuizActiveSession? activeSession;
  final int stars;
  final int highScore;
  final VoidCallback onTap;

  const FanQuizLevelCard({
    super.key,
    required this.level,
    required this.isUnlocked,
    required this.isCompleted,
    required this.hasActiveSession,
    this.activeSession,
    required this.stars,
    required this.highScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final fanId = level.id.split('_').first;
    final fanTheme = palette.fanColor(fanId);

    final cardBorderColor = hasActiveSession
        ? fanTheme.primary.withValues(alpha: 0.6)
        : (isCompleted ? fanTheme.border.withValues(alpha: 0.6) : palette.border);

    return Material(
      color: palette.surface,
      borderRadius: AppRadius.xlRadius,
      child: InkWell(
        borderRadius: AppRadius.xlRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.xlRadius,
            border: Border.all(
              color: cardBorderColor,
              width: (hasActiveSession || isCompleted) ? 1.3 : 1.0,
            ),
            boxShadow: palette.shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Level Step Node
                  Container(
                    width: AppSpace.xxl * 1.3,
                    height: AppSpace.xxl * 1.3,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hasActiveSession
                          ? fanTheme.softBg
                          : (isCompleted
                              ? fanTheme.softBg
                              : (isUnlocked
                                  ? fanTheme.softBg.withValues(alpha: 0.5)
                                  : palette.surfaceMuted)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasActiveSession
                            ? fanTheme.primary
                            : (isCompleted
                                ? fanTheme.border
                                : (isUnlocked
                                    ? fanTheme.border.withValues(alpha: 0.7)
                                    : palette.border)),
                        width: 1.5,
                      ),
                    ),
                    child: hasActiveSession
                        ? Icon(Icons.play_arrow_rounded, color: fanTheme.primary, size: AppIcon.sm)
                        : (isCompleted
                            ? Icon(Icons.check_rounded, color: fanTheme.primary, size: AppIcon.sm)
                            : Text(
                                '${level.levelNumber}',
                                style: textTheme.label.copyWith(
                                  color: isUnlocked ? fanTheme.primary : palette.textSubtle,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.title,
                          style: textTheme.titleSmall.copyWith(
                            color: isUnlocked ? palette.text : palette.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.xs,
                            vertical: AppSpace.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceMuted,
                            borderRadius: AppRadius.pillRadius,
                          ),
                          child: Text(
                            '${level.totalQuestions} سؤالاً منهجياً · شروحات وأدلة',
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isUnlocked)
                    Icon(
                      Icons.lock_rounded,
                      color: palette.textSubtle,
                      size: AppIcon.sm,
                    )
                  else if (isCompleted)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        return Icon(
                          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: i < stars ? palette.gold : palette.border,
                          size: AppIcon.xs,
                        );
                      }),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                level.description,
                style: textTheme.bodySmall.copyWith(
                  color: palette.textMuted,
                  height: 1.5,
                ),
              ),

              // Active Resume Box on Level Card (Shows exact stop point e.g. 5/20)
              if (hasActiveSession && activeSession != null) ...[
                const SizedBox(height: AppSpace.md),
                Container(
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: palette.goldSoft,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(
                      color: palette.gold.withAlpha(90),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timelapse_rounded,
                                color: palette.gold,
                                size: AppIcon.xs,
                              ),
                              const SizedBox(width: AppSpace.xs),
                              Text(
                                'توقفت عند السؤال ${activeSession!.currentIndex + 1} من ${level.totalQuestions}',
                                style: textTheme.caption.copyWith(
                                  color: palette.gold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${activeSession!.currentIndex + 1} / ${level.totalQuestions}',
                            style: textTheme.caption.copyWith(
                              color: palette.gold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xs),
                      ClipRRect(
                        borderRadius: AppRadius.pillRadius,
                        child: LinearProgressIndicator(
                          value: (activeSession!.currentIndex + 1) / level.totalQuestions,
                          backgroundColor: palette.surfaceMuted,
                          color: fanTheme.primary,
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpace.md),

              // Card Bottom Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isCompleted && highScore > 0)
                    Text(
                      'أفضل نتيجة: $highScore / ${level.totalQuestions}',
                      style: textTheme.caption.copyWith(
                        color: fanTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (hasActiveSession)
                    Text(
                      'جلسة غير مكتملة',
                      style: textTheme.caption.copyWith(
                        color: fanTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Interactive CTA Button
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: hasActiveSession
                          ? fanTheme.primary
                          : (isCompleted
                              ? fanTheme.softBg
                              : (isUnlocked ? fanTheme.primary : palette.surfaceMuted)),
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: hasActiveSession
                            ? fanTheme.primary
                            : (isCompleted
                                ? fanTheme.border
                                : (isUnlocked ? fanTheme.primary : palette.border)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasActiveSession
                              ? 'متابعة الاختبار'
                              : (isCompleted
                                  ? 'إعادة الاختبار'
                                  : (isUnlocked ? 'بدء الاختبار' : 'مستوى مقفل')),
                          style: textTheme.caption.copyWith(
                            color: hasActiveSession
                                ? palette.onPrimary
                                : (isCompleted
                                    ? fanTheme.primary
                                    : (isUnlocked
                                        ? palette.onPrimary
                                        : palette.textSubtle)),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isUnlocked) ...[
                          const SizedBox(width: AppSpace.xs),
                          Icon(
                            hasActiveSession
                                ? Icons.play_arrow_rounded
                                : (isCompleted
                                    ? Icons.refresh_rounded
                                    : Icons.arrow_forward_rounded),
                            color: hasActiveSession
                                ? palette.onPrimary
                                : (isCompleted
                                    ? fanTheme.primary
                                    : palette.onPrimary),
                            size: AppIcon.xs,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
