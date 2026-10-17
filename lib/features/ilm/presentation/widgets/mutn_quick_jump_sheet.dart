import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_ui.dart';
import '../../data/catalogs/mutun_curriculum_catalog.dart';

/// Bottom sheet for quick jumping between scholarly sections in authentic mutun.
/// Mirrors the "الانتقال السريع" sheet in Hafed Mutun.
class MutunQuickJumpSheet extends StatelessWidget {
  final List<MutunSection> sections;
  final int? activeParagraph;
  final ValueChanged<int> onParagraphSelected;

  const MutunQuickJumpSheet({
    super.key,
    required this.sections,
    required this.activeParagraph,
    required this.onParagraphSelected,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final tokens = MutunThemeColors.getTokens(isDark: palette.isDark);

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      child: SafeArea(
        top: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sheet Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.textMuted.withValues(alpha: 0.3),
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),

              // Title Header
              Row(
                children: [
                  Icon(
                    Icons.fast_forward_rounded,
                    color: tokens.rosetteGold,
                    size: AppIcon.sm,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    'الانتقال السريع بين أبواب وفصول المتن',
                    style: textTheme.titleSmall.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),

              // Sections List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sections.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpace.xs),
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    final firstPara = section.paragraphs.first.index;
                    final lastPara = section.paragraphs.last.index;
                    final isCurrent = activeParagraph != null &&
                        activeParagraph! >= firstPara &&
                        activeParagraph! <= lastPara;

                    return Material(
                      color: isCurrent
                          ? tokens.activeParagraphBg
                          : palette.surface,
                      borderRadius: AppRadius.mdRadius,
                      child: InkWell(
                        borderRadius: AppRadius.mdRadius,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                          onParagraphSelected(firstPara);
                        },
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.md,
                            vertical: AppSpace.sm,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.mdRadius,
                            border: Border.all(
                              color: isCurrent
                                  ? tokens.activeParagraphBorder
                                  : palette.border.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? tokens.rosetteGold
                                      : palette.surfaceMuted,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${index + 1}',
                                  style: textTheme.caption.copyWith(
                                    color: isCurrent
                                        ? palette.onPrimary
                                        : palette.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpace.md),
                              Expanded(
                                child: Text(
                                  section.title,
                                  style: textTheme.body.copyWith(
                                    color: isCurrent
                                        ? tokens.rosetteGold
                                        : palette.text,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
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
                                  firstPara == lastPara
                                      ? 'فقرة $firstPara'
                                      : 'فقرة $firstPara - $lastPara',
                                  style: textTheme.caption.copyWith(
                                    color: palette.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
