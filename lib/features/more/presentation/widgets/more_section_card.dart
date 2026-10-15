import 'package:flutter/material.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';

class MoreSection {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;
  final String? badge;

  MoreSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.trailing,
    this.badge,
  });
}

class MoreSectionCard extends StatelessWidget {
  final MoreSection section;

  const MoreSectionCard({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final color = section.color;

    return AppCard(
      onTap: section.onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(
              section.icon,
              color: color,
              size: AppIcon.md,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        section.title,
                        style: textTheme.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.text,
                        ),
                      ),
                    ),
                    if (section.badge != null) ...[
                      const SizedBox(width: AppSpace.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: palette.gold.withValues(alpha: 0.15),
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(
                            color: palette.gold.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          section.badge!,
                          style: textTheme.caption.copyWith(
                            color: palette.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  section.subtitle,
                  style: textTheme.caption.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (section.trailing != null) ...[
            const SizedBox(width: AppSpace.xs),
            section.trailing!,
            const SizedBox(width: AppSpace.xs),
          ],
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: palette.textMuted,
            size: AppIcon.sm,
          ),
        ],
      ),
    );
  }
}
