import 'package:flutter/material.dart';

import '../../../../app/theme/app_ui.dart';
import '../../data/catalogs/mutun_curriculum_catalog.dart';
import 'mutun_rosette_icon.dart';

class MutnCurriculumSectionHeader extends StatelessWidget {
  final MutunSection section;
  final bool isFirstSection;
  final ReaderSurfaceTokens surfaceTokens;
  final AppTextTheme textTheme;
  final MutunThemeTokens tokens;
  final String fontFamily;
  final VoidCallback? onToggleControls;

  const MutnCurriculumSectionHeader({
    super.key,
    required this.section,
    required this.isFirstSection,
    required this.surfaceTokens,
    required this.textTheme,
    required this.tokens,
    required this.fontFamily,
    this.onToggleControls,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: isFirstSection ? AppSpace.xs : AppSpace.xl,
        bottom: AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isFirstSection) ...[
            Divider(
              color: surfaceTokens.border.withValues(alpha: 0.5),
              height: 1,
            ),
            const SizedBox(height: AppSpace.md),
          ],
          Material(
            color: surfaceTokens.surfaceRaised,
            borderRadius: AppRadius.mdRadius,
            child: InkWell(
              borderRadius: AppRadius.mdRadius,
              onTap: () {
                onToggleControls?.call();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.sm,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: tokens.rosetteGold.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MutunRosetteIcon(
                      size: AppIcon.sm,
                      color: tokens.rosetteGold.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Flexible(
                      child: Text(
                        section.title,
                        textAlign: TextAlign.center,
                        style: textTheme.titleSmall.copyWith(
                          color: tokens.rosetteGold,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontFamily,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    MutunRosetteIcon(
                      size: AppIcon.sm,
                      color: tokens.rosetteGold.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
