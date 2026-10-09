import 'package:flutter/material.dart';
import '../../features/ilm/data/models/progress_models.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_palette.dart';

class ProgressPill extends StatelessWidget {
  final BookProgress progress;

  const ProgressPill({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final config = _map(context, progress.status);

    return AnimatedContainer(
      duration: AppMotion.base,
      curve: AppMotion.easeOut,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: AppRadius.pillRadius,
      ),
      child: AnimatedSwitcher(
        duration: AppMotion.fast,
        switchInCurve: AppMotion.easeOut,
        switchOutCurve: AppMotion.easeOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Row(
          key: ValueKey(config.label),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: AppIcon.sm, color: config.foreground),
            const SizedBox(width: AppSpace.xs),
            Text(
              config.label,
              style: textTheme.caption.copyWith(
                color: config.foreground,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  _Config _map(BuildContext context, BookProgressStatus status) {
    final palette = context.palette;

    switch (status) {
      case BookProgressStatus.completed:
        return _Config(
          label: AppStrings.progressStatusCompleted,
          icon: Icons.check_rounded,
          foreground: palette.onPrimarySoft,
          background: palette.primarySoft,
        );

      case BookProgressStatus.inProgress:
        return _Config(
          label: AppStrings.progressStatusInProgress,
          icon: Icons.play_arrow_rounded,
          foreground: palette.primary,
          background: palette.primarySoft,
        );

      case BookProgressStatus.notStarted:
        return _Config(
          label: AppStrings.progressStatusNotStarted,
          icon: Icons.circle_outlined,
          foreground: palette.textMuted,
          background: palette.surfaceMuted,
        );
    }
  }
}

class _Config {
  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  const _Config({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });
}
