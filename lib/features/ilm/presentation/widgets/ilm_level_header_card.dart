import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_progress.dart';
import '../../data/models/mutun_models.dart';

/// A scholarly header card introducing the selected level in the curriculum.
class IlmLevelHeaderCard extends StatelessWidget {
  final IlmLevel level;
  final double completion;
  final int totalBooks;
  final int completedBooks;

  const IlmLevelHeaderCard({
    super.key,
    required this.level,
    required this.completion,
    required this.totalBooks,
    required this.completedBooks,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final levelColors = palette.mutunLevel(level.title);

    return Padding(
      padding: AppSpace.screenPadding,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpace.lg),
        border: Border.all(
          color: levelColors.border,
          width: 1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Level Title & Duration
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: levelColors.bg,
                    borderRadius: AppRadius.smRadius,
                    border: Border.all(color: levelColors.border, width: 0.8),
                  ),
                  child: Text(
                    level.label.isNotEmpty ? level.label : level.title,
                    style: context.text.label.copyWith(
                      color: levelColors.fg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    level.title,
                    style: context.text.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (level.duration.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: AppIcon.sm,
                        color: palette.textMuted,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        level.duration,
                        style: context.text.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            if (level.goal.isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                level.goal,
                style: context.text.bodySmall.copyWith(
                  color: palette.text,
                  height: 1.4,
                ),
              ),
            ],

            if (level.focus.isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.xs,
                runSpacing: AppSpace.xs,
                children: level.focus.map((focusItem) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(color: palette.border),
                    ),
                    child: Text(
                      focusItem,
                      style: context.text.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: AppSpace.md),

            // Level Completion Progress
            Row(
              children: [
                Expanded(
                  child: AppProgress(
                    progress: completion.clamp(0.0, 1.0),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Text(
                  '$completedBooks من $totalBooks متون (${(completion * 100).round()}%)',
                  style: context.text.caption.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
