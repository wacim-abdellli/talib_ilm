import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';

/// Selectable tile representing a Dhikr content category.
class DhikrContentOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme colors;

  const DhikrContentOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? colors.primaryContainer : colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.mdRadius,
      side: BorderSide(
        color: selected ? colors.primary : colors.outline,
        width: selected ? 1.5 : 1,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.lg,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppIcon.sm,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  size: AppIcon.sm,
                  color: colors.primary,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

