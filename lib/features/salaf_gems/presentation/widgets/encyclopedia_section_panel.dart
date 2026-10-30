import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../data/models/encyclopedia_section.dart';

class EncyclopediaSectionPanel extends StatelessWidget {
  final EncyclopediaGroup group;
  final ValueChanged<EncyclopediaSection> onSelectSection;

  const EncyclopediaSectionPanel({
    super.key,
    required this.group,
    required this.onSelectSection,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Optional Quranic Banner (Screenshots 1 & 2)
        if (group.quranAyah != null) ...[
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.md,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceRaised,
              borderRadius: AppRadius.lgRadius,
              border: Border.all(
                color: palette.gold.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: palette.shadow,
            ),
            child: Column(
              children: [
                Text(
                  '«${group.quranAyah}»',
                  textAlign: TextAlign.center,
                  style: textTheme.sacred.copyWith(
                    color: palette.gold,
                    height: 1.9,
                  ),
                ),
                if (group.quranSurah != null) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    group.quranSurah!,
                    style: textTheme.caption.copyWith(
                      color: palette.textMuted,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
        ],

        // Group Title
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpace.xs,
            bottom: AppSpace.sm,
          ),
          child: Text(
            group.title,
            style: textTheme.titleSmall.copyWith(
              color: palette.text,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
        ),

        // Group Container with Section Rows
        Container(
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(
              color: palette.border,
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.sections.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: palette.border,
            ),
            itemBuilder: (context, index) {
              final section = group.sections[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSelectSection(section);
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.sm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: palette.surfaceMuted,
                            borderRadius: AppRadius.mdRadius,
                            border: Border.all(
                              color: palette.border,
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            section.icon,
                            color: palette.gold,
                            size: AppIcon.sm,
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                section.title,
                                style: textTheme.titleSmall.copyWith(
                                  color: palette.text,
                                ),
                              ),
                              const SizedBox(height: AppSpace.xs / 2),
                              Text(
                                section.description,
                                style: textTheme.caption.copyWith(
                                  color: palette.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: AppIcon.xs,
                          color: palette.textSubtle,
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
    );
  }
}
