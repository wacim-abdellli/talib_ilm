import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';

/// Reusable count pill button for Hifdh repetition counts (1x, 2x, 3x, etc.).
class HifdhCountPill extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const HifdhCountPill({
    super.key,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillRadius,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected ? palette.primary : palette.surfaceRaised,
            borderRadius: AppRadius.pillRadius,
            border: Border.all(
              color: isSelected ? palette.primary : palette.border,
            ),
          ),
          child: Text(
            label,
            style: textTheme.caption.copyWith(
              color: isSelected ? palette.surfaceRaised : palette.text,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// Stepper widget with plus/minus buttons to configure Hifdh ayah ranges.
class HifdhAyahStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const HifdhAyahStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpace.xs),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: textTheme.caption.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: AppSpace.xxs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'إنقاص الآية',
                icon: const Icon(Icons.remove_circle_outline_rounded),
                iconSize: AppIcon.sm,
                color: value > min ? palette.primary : palette.textMuted,
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xs,
                ),
                child: Text(
                  '$value',
                  style: textTheme.titleSmall.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'زيادة الآية',
                icon: const Icon(Icons.add_circle_outline_rounded),
                iconSize: AppIcon.sm,
                color: value < max ? palette.primary : palette.textMuted,
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
