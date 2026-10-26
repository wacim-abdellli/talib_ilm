import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../data/models/mutun_models.dart';

/// Clean, unified Level Selector bar for the academic curriculum (متون طالب العلم).
class IlmFilterBar extends StatelessWidget {
  final List<IlmLevel> levels;
  final String selectedLevelId;
  final ValueChanged<String> onSelectLevel;
  final Map<String, double> levelCompletion;

  const IlmFilterBar({
    super.key,
    required this.levels,
    required this.selectedLevelId,
    required this.onSelectLevel,
    required this.levelCompletion,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      height: AppSize.tap,
      child: ListView.separated(
        padding: AppSpace.screenPadding,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: levels.length,
        separatorBuilder: (_, index) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (context, index) {
          final level = levels[index];
          final isSelected = level.id == selectedLevelId;
          final completion = levelCompletion[level.id] ?? 0.0;
          final isComplete = completion >= 1.0;

          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.tap),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelectLevel(level.id),
                borderRadius: AppRadius.pillRadius,
                child: AnimatedContainer(
                  duration: AppMotion.base,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? palette.primarySoft : palette.surface,
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(
                      color: isSelected ? palette.primary : palette.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        level.label.isNotEmpty ? level.label : level.title,
                        style: (isSelected
                                ? context.text.labelBold
                                : context.text.labelMedium)
                            .copyWith(
                          color: isSelected ? palette.primary : palette.text,
                        ),
                      ),
                      if (isComplete) ...[
                        const SizedBox(width: AppSpace.xs),
                        Icon(
                          Icons.check_circle_rounded,
                          size: AppIcon.sm,
                          color: palette.gold,
                        ),
                      ] else if (completion > 0) ...[
                        const SizedBox(width: AppSpace.xs),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: palette.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
