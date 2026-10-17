import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import 'mutun_rosette_icon.dart';

/// Clean scholarly partition header for categorized sections of the Ilm library.
class IlmPartitionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String countLabel;
  final VoidCallback? onShowAll;

  const IlmPartitionHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.countLabel,
    this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Islamic 8-Point Rosette Icon ───────────────────────────
          MutunRosetteIcon(
            size: AppIcon.md,
            color: palette.primary,
          ),
          const SizedBox(width: AppSpace.sm),

          // ── Title & Optional Subtitle ──────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    subtitle!,
                    style: textTheme.caption.copyWith(
                      color: palette.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // ── Count Pill or "عرض الكل" ───────────────────────────────
          if (onShowAll != null)
            Semantics(
              button: true,
              label: 'عرض كل كتب $title',
              child: Material(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.pillRadius,
                child: InkWell(
                  borderRadius: AppRadius.pillRadius,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onShowAll!();
                  },
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(color: palette.border, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          countLabel,
                          style: textTheme.caption.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpace.xxs),
                        Icon(
                          Icons.chevron_left_rounded,
                          size: AppIcon.sm,
                          color: palette.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.sm,
                vertical: AppSpace.xxs,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.pillRadius,
                border: Border.all(color: palette.border, width: 0.8),
              ),
              child: Text(
                countLabel,
                style: textTheme.caption.copyWith(
                  color: palette.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
