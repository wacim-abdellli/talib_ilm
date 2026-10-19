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

    final xp = stats?.totalXp ?? 0;
    final stars = stats?.totalStars ?? 0;
    final completed = stats?.completedLevelsCount ?? 0;
    final rank = stats?.rankTitle ?? 'مبتدئ في طلب العلم';
    final rankIcon = stats?.rankIcon ?? '🌱';

    final rankProgress = ((xp % 250) / 250.0).clamp(0.08, 1.0);

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: palette.gold.withAlpha(60), width: 1.2),
        boxShadow: palette.shadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: AppSpace.xxl * 1.5,
                height: AppSpace.xxl * 1.5,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.gold.withAlpha(90),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  rankIcon,
                  style: textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رتبة طالب العلم',
                      style: textTheme.caption.copyWith(color: palette.textSubtle),
                    ),
                    Text(
                      rank,
                      style: textTheme.titleSmall.copyWith(color: palette.text),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(color: palette.gold.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: palette.gold,
                      size: AppIcon.sm,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      '$xp XP',
                      style: textTheme.label.copyWith(color: palette.gold),
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
              value: rankProgress,
              backgroundColor: palette.surfaceMuted,
              color: palette.gold,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  icon: Icons.star_rounded,
                  iconColor: palette.gold,
                  value: '$stars',
                  label: 'نجوم الإتقان',
                  palette: palette,
                  textTheme: textTheme,
                ),
                _buildMetric(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: palette.primary,
                  value: '$completed / ${IslamicQuizCatalog.totalLevelsCount}',
                  label: 'المستويات المتقنة',
                  palette: palette,
                  textTheme: textTheme,
                ),
                _buildMetric(
                  icon: Icons.verified_rounded,
                  iconColor: palette.primary,
                  value: '${stats?.totalCorrectAnswers ?? 0}',
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
    required String value,
    required String label,
    required AppPalette palette,
    required dynamic textTheme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: AppIcon.sm),
            const SizedBox(width: AppSpace.xxs),
            Text(value, style: textTheme.label.copyWith(color: palette.text)),
          ],
        ),
        const SizedBox(height: AppSpace.xxs),
        Text(label, style: textTheme.caption.copyWith(color: palette.textSubtle)),
      ],
    );
  }
}
