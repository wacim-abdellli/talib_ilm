import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../data/catalogs/islamic_quiz_catalog.dart';
import '../../data/models/islamic_quiz_models.dart';

/// Hero banner displaying the student's Islamic scholarly rank, XP, and mastery stats.
class QuizHeroStatsBanner extends StatelessWidget {
  final UserQuizStats? stats;

  const QuizHeroStatsBanner({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final stars = stats?.totalStars ?? 0;
    final completed = stats?.completedLevelsCount ?? 0;
    final totalLevels = IslamicQuizCatalog.totalLevelsCount;
    final rank = stats?.rankTitle ?? 'مبتدئ في طلب العلم';
    final rankIcon = stats?.rankIconData ?? Icons.spa_rounded;
    final xp = stats?.totalXp ?? 0;

    final masteryProgress = totalLevels > 0
        ? (completed / totalLevels).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: palette.gold.withAlpha(70), width: 1.2),
        boxShadow: palette.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSpace.xxl * 1.4,
                height: AppSpace.xxl * 1.4,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.gold.withAlpha(100),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  rankIcon,
                  color: palette.gold,
                  size: AppIcon.md,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رتبة طالب العلم المنهجي',
                      style: textTheme.caption.copyWith(color: palette.textSubtle),
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      rank,
                      style: textTheme.titleSmall.copyWith(
                        color: palette.text,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xxs,
                ),
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: palette.gold.withAlpha(80),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      color: palette.gold,
                      size: AppIcon.xs,
                    ),
                    const SizedBox(width: AppSpace.xxs),
                    Text(
                      '$xp XP',
                      style: textTheme.caption.copyWith(
                        color: palette.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          ClipRRect(
            borderRadius: AppRadius.pillRadius,
            child: LinearProgressIndicator(
              value: masteryProgress,
              backgroundColor: palette.surfaceMuted,
              color: palette.gold,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.sm,
              vertical: AppSpace.md,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.lgRadius,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetric(
                  icon: Icons.star_rounded,
                  iconColor: palette.gold,
                  primaryText: '$stars',
                  secondaryText: '',
                  label: 'نجوم الإتقان',
                  palette: palette,
                  textTheme: textTheme,
                ),
                Container(
                  width: 1,
                  height: AppSpace.xl,
                  color: palette.border,
                ),
                _buildMetric(
                  icon: Icons.military_tech_rounded,
                  iconColor: palette.primary,
                  primaryText: '$completed',
                  secondaryText: ' من $totalLevels',
                  label: 'المستويات المتقنة',
                  palette: palette,
                  textTheme: textTheme,
                ),
                Container(
                  width: 1,
                  height: AppSpace.xl,
                  color: palette.border,
                ),
                _buildMetric(
                  icon: Icons.verified_rounded,
                  iconColor: palette.primary,
                  primaryText: '${stats?.totalCorrectAnswers ?? 0}',
                  secondaryText: '',
                  label: 'إجابة صحيحة',
                  palette: palette,
                  textTheme: textTheme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required Color iconColor,
    required String primaryText,
    required String secondaryText,
    required String label,
    required AppPalette palette,
    required dynamic textTheme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            Icon(icon, color: iconColor, size: AppIcon.sm),
            const SizedBox(width: AppSpace.xxs),
            Text(
              primaryText,
              style: textTheme.label.copyWith(
                color: palette.text,
              ),
            ),
            if (secondaryText.isNotEmpty)
              Text(
                secondaryText,
                style: textTheme.caption.copyWith(
                  color: palette.textSubtle,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xxs),
        Text(
          label,
          style: textTheme.caption.copyWith(
            color: palette.textSubtle,
          ),
        ),
      ],
    );
  }
}
