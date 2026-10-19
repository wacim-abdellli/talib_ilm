import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../data/catalogs/islamic_quiz_catalog.dart';
import '../../data/models/islamic_quiz_models.dart';
import '../pages/fan_quiz_levels_page.dart';
import '../pages/islamic_quiz_hub_page.dart';

/// Banner card embedded in the main Ilm screen to invite the student to take quizzes and tests.
class IlmQuizBannerCard extends StatelessWidget {
  final String? currentCategory;
  final UserQuizStats? userStats;
  final VoidCallback? onReturnFromQuiz;

  const IlmQuizBannerCard({
    super.key,
    this.currentCategory,
    this.userStats,
    this.onReturnFromQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    // Check if the current category maps directly to a specific fan
    final currentFan = currentCategory != null && currentCategory != 'all'
        ? IslamicQuizCatalog.getFan(currentCategory!)
        : null;

    final totalStars = userStats?.totalStars ?? 0;
    final totalXp = userStats?.totalXp ?? 0;

    return Container(
      margin: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: palette.primary.withAlpha(90)),
        boxShadow: palette.shadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.lgRadius,
        child: InkWell(
          borderRadius: AppRadius.lgRadius,
          onTap: () async {
            HapticFeedback.selectionClick();
            if (currentFan != null) {
              await Navigator.of(context).push(
                buildFadeRoute(
                  page: FanQuizLevelsPage(fan: currentFan),
                ),
              );
            } else {
              await Navigator.of(context).push(
                buildFadeRoute(
                  page: const IslamicQuizHubPage(),
                ),
              );
            }
            onReturnFromQuiz?.call();
          },
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpace.lg),
            child: Row(
              children: [
                Container(
                  width: AppSpace.xxl * 1.3,
                  height: AppSpace.xxl * 1.3,
                  decoration: BoxDecoration(
                    color: palette.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    currentFan?.icon ?? Icons.school_rounded,
                    color: palette.primary,
                    size: AppIcon.lg,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentFan != null
                                  ? 'اختبارات ومستويات ${currentFan.title}'
                                  : 'مسابقات واختبارات العلوم الشرعية',
                              style: textTheme.titleSmall.copyWith(
                                color: palette.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (totalXp > 0)
                            Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.xs,
                                vertical: AppSpace.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: palette.goldSoft,
                                borderRadius: AppRadius.pillRadius,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: palette.gold,
                                    size: AppIcon.xs,
                                  ),
                                  const SizedBox(width: AppSpace.xxs),
                                  Text(
                                    '$totalStars نجوم',
                                    style: textTheme.caption.copyWith(
                                      color: palette.gold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        currentFan != null
                          ? '3 مستويات متدرجة مع الدروس والأدلة الشرعية'
                          : 'اختبر حفظك وفهمك في العقيدة، الفقه، الحديث، والتفسير مع الشروحات',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Container(
                  width: AppSpace.xxl,
                  height: AppSpace.xxl,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: palette.primary,
                    size: AppIcon.sm,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
