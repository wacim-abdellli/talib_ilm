import 'package:flutter/material.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../data/models/salaf_filter_models.dart';

class SalafFilterCapsuleBar extends StatelessWidget {
  final SalafScholarItem selectedScholar;
  final SalafTopicItem selectedTopic;
  final List<String> categories;
  final String selectedCategory;
  final VoidCallback onOpenScholarPicker;
  final VoidCallback onOpenTopicPicker;
  final VoidCallback onClearScholar;
  final VoidCallback onClearTopic;
  final ValueChanged<String> onSelectCategory;

  const SalafFilterCapsuleBar({
    super.key,
    required this.selectedScholar,
    required this.selectedTopic,
    required this.categories,
    required this.selectedCategory,
    required this.onOpenScholarPicker,
    required this.onOpenTopicPicker,
    required this.onClearScholar,
    required this.onClearTopic,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final hasScholarFilter = selectedScholar.id != 'all';
    final hasTopicFilter = selectedTopic.id != 'all';

    return Container(
      color: palette.surface,
      padding: const EdgeInsetsDirectional.fromSTEB(
        0,
        AppSpace.xxs,
        0,
        AppSpace.sm,
      ),
      height: AppSize.tap,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md),
        children: [
          // 1. Scholar Filter Capsule Pill
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppRadius.pillRadius,
              onTap: onOpenScholarPicker,
              child: Container(
                alignment: AlignmentDirectional.center,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: hasScholarFilter ? palette.goldSoft : palette.surfaceRaised,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: hasScholarFilter ? palette.gold : palette.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: hasScholarFilter ? palette.gold : palette.textMuted,
                    ),
                    const SizedBox(width: AppSpace.xxs),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Text(
                        hasScholarFilter ? selectedScholar.displayName : 'القائل ▾',
                        style: textTheme.label.copyWith(
                          color: hasScholarFilter ? palette.gold : palette.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasScholarFilter) ...[
                      const SizedBox(width: AppSpace.xxs),
                      InkWell(
                        onTap: onClearScholar,
                        child: Icon(
                          Icons.cancel_rounded,
                          color: palette.gold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.xs),

          // 2. Topic Filter Capsule Pill
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppRadius.pillRadius,
              onTap: onOpenTopicPicker,
              child: Container(
                alignment: AlignmentDirectional.center,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: hasTopicFilter ? palette.primarySoft : palette.surfaceRaised,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: hasTopicFilter ? palette.primary : palette.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasTopicFilter ? selectedTopic.icon : Icons.category_outlined,
                      color: hasTopicFilter ? palette.primary : palette.textMuted,
                    ),
                    const SizedBox(width: AppSpace.xxs),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Text(
                        hasTopicFilter ? selectedTopic.title : 'الموضوع ▾',
                        style: textTheme.label.copyWith(
                          color: hasTopicFilter ? palette.primary : palette.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasTopicFilter) ...[
                      const SizedBox(width: AppSpace.xxs),
                      InkWell(
                        onTap: onClearTopic,
                        child: Icon(
                          Icons.cancel_rounded,
                          color: palette.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.xs),

          // 3. Category Pills
          ...categories.map((cat) {
            final isSelected = selectedCategory == cat;
            return Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpace.xs),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: AppRadius.pillRadius,
                  onTap: () => onSelectCategory(cat),
                  child: Container(
                    alignment: AlignmentDirectional.center,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? palette.primarySoft : palette.surfaceRaised,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: isSelected ? palette.primary : palette.border,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: textTheme.label.copyWith(
                        color: isSelected ? palette.primary : palette.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
