import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../data/models/mutun_models.dart';

enum IlmViewMode {
  levels,
  disciplines,
}

/// A dual-lens view switcher and category/level filter bar for the Ilm library.
class IlmFilterBar extends StatelessWidget {
  final IlmViewMode currentMode;
  final ValueChanged<IlmViewMode> onModeChanged;
  final List<IlmLevel> levels;
  final String selectedLevelId;
  final ValueChanged<String> onSelectLevel;
  final Map<String, double> levelCompletion;
  final List<String> disciplines;
  final String selectedDiscipline;
  final ValueChanged<String> onSelectDiscipline;
  final Map<String, int> disciplineBookCounts;

  const IlmFilterBar({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.levels,
    required this.selectedLevelId,
    required this.onSelectLevel,
    required this.levelCompletion,
    required this.disciplines,
    required this.selectedDiscipline,
    required this.onSelectDiscipline,
    required this.disciplineBookCounts,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Dual-Lens Mode Switcher ───────────────────────────────
        Padding(
          padding: AppSpace.screenPadding,
          child: Container(
            height: 44,
            padding: AppSpace.insetXs,
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildModeTab(
                    context: context,
                    palette: palette,
                    title: 'سُلم المستويات',
                    icon: Icons.stairs_rounded,
                    isSelected: currentMode == IlmViewMode.levels,
                    onTap: () => onModeChanged(IlmViewMode.levels),
                  ),
                ),
                Expanded(
                  child: _buildModeTab(
                    context: context,
                    palette: palette,
                    title: 'الفنون والعلوم',
                    icon: Icons.category_rounded,
                    isSelected: currentMode == IlmViewMode.disciplines,
                    onTap: () => onModeChanged(IlmViewMode.disciplines),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpace.md),

        // ── Sub-navigation filter chips ───────────────────────────
        if (currentMode == IlmViewMode.levels)
          _buildLevelChips(context, palette)
        else
          _buildDisciplineChips(context, palette),
      ],
    );
  }

  Widget _buildModeTab({
    required BuildContext context,
    required AppPalette palette,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillRadius,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? palette.surface : Colors.transparent,
            borderRadius: AppRadius.pillRadius,
            border: isSelected
                ? Border.all(color: palette.gold.withAlpha(90))
                : null,
            boxShadow: isSelected ? palette.shadow : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppIcon.sm,
                color: isSelected ? palette.primary : palette.textMuted,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                title,
                style: context.text.label.copyWith(
                  color: isSelected ? palette.primary : palette.textMuted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelChips(BuildContext context, AppPalette palette) {
    return SizedBox(
      height: AppSize.tap,
      child: ListView.separated(
        padding: AppSpace.screenPadding,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: levels.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (context, index) {
          final level = levels[index];
          final isSelected = level.id == selectedLevelId;
          final completion = levelCompletion[level.id] ?? 0.0;
          final isComplete = completion >= 1.0;

          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.tap),
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
                      style: context.text.label.copyWith(
                        color: isSelected ? palette.primary : palette.text,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    if (isComplete) ...[
                      const SizedBox(width: AppSpace.xs),
                      Icon(
                        Icons.check_circle_rounded,
                        size: AppIcon.sm,
                        color: palette.success,
                      ),
                    ] else if (completion > 0) ...[
                      const SizedBox(width: AppSpace.xs),
                      Container(
                        padding: AppSpace.insetXs,
                        decoration: BoxDecoration(
                          color: palette.surfaceRaised,
                          borderRadius: AppRadius.smRadius,
                        ),
                        child: Text(
                          '${(completion * 100).round()}%',
                          style: context.text.caption.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDisciplineChips(BuildContext context, AppPalette palette) {
    return SizedBox(
      height: AppSize.tap,
      child: ListView.separated(
        padding: AppSpace.screenPadding,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: disciplines.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (context, index) {
          final discipline = disciplines[index];
          final isSelected = discipline == selectedDiscipline;
          final count = disciplineBookCounts[discipline] ?? 0;
          final catColors = palette.category(discipline == 'الكل' ? null : discipline);

          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.tap),
            child: InkWell(
              onTap: () => onSelectDiscipline(discipline),
              borderRadius: AppRadius.pillRadius,
              child: AnimatedContainer(
                duration: AppMotion.base,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? catColors.bg : palette.surface,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: isSelected ? catColors.fg : palette.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      discipline,
                      style: context.text.label.copyWith(
                        color: isSelected ? catColors.fg : palette.text,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    if (count > 0 && discipline != 'الكل') ...[
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        '($count)',
                        style: context.text.caption.copyWith(
                          color: isSelected ? catColors.fg : palette.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
