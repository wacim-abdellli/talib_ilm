import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';

/// A scholarly compact preview row for classical library books and mutun.
/// Designed for overview pages to make book titles readable at a glance without truncation.
class IlmBookPreviewRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? author;
  final String? progressBadge;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isCompleted;

  const IlmBookPreviewRow({
    super.key,
    required this.title,
    required this.subtitle,
    this.author,
    this.progressBadge,
    required this.accentColor,
    required this.onTap,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      button: true,
      label: 'فتح $title',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.tap),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpace.md,
                AppSpace.sm,
                AppSpace.md,
                AppSpace.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: AppSpace.xs,
                    height: AppSpace.xxxl,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: AppRadius.pillRadius,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: context.text.body.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        if (progressBadge != null)
                          Row(
                            children: [
                              if (author != null)
                                Expanded(
                                  child: Text(
                                    author!,
                                    style: context.text.caption.copyWith(
                                      color: palette.textMuted,
                                      height: 1.25,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              const SizedBox(width: AppSpace.xs),
                              Container(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpace.sm,
                                  vertical: AppSpace.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? palette.success.withValues(alpha: 0.12)
                                      : palette.primarySoft,
                                  borderRadius: AppRadius.pillRadius,
                                  border: Border.all(
                                    color: isCompleted
                                        ? palette.success.withValues(alpha: 0.35)
                                        : palette.primary.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isCompleted
                                          ? Icons.check_circle_rounded
                                          : Icons.auto_stories_rounded,
                                      size: AppIcon.xs,
                                      color: isCompleted
                                          ? palette.success
                                          : palette.primary,
                                    ),
                                    const SizedBox(width: AppSpace.xxs),
                                    Text(
                                      progressBadge!,
                                      style: context.text.caption.copyWith(
                                        color: isCompleted
                                            ? palette.success
                                            : palette.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            subtitle,
                            style: context.text.caption.copyWith(
                              color: isCompleted
                                  ? palette.success
                                  : palette.textMuted,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  if (isCompleted)
                    Icon(
                      Icons.check_circle_rounded,
                      size: AppIcon.xs,
                      color: palette.success,
                    )
                  else
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: AppIcon.xs,
                      color: palette.textSubtle,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A full-width tap target row to view all books in a category or level.
class IlmViewAllRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const IlmViewAllRow({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.tap),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: context.text.label.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: AppIcon.xs,
                    color: palette.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
