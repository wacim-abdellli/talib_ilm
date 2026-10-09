import 'package:flutter/material.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';

class MoreSection {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  MoreSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
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
                Text(
                  section.title,
                  style: textTheme.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
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
          Icon(
            Icons.arrow_back_ios_new_rounded,
            color: palette.textMuted,
            size: AppIcon.sm,
          ),
        ],
      ),
    );
  }
}
