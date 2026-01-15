import 'package:flutter/material.dart';
import '../../features/ilm/data/models/progress_models.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/app_ui.dart';

class ProgressPill extends StatelessWidget {
  final BookProgress progress;

  const ProgressPill({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final _Config config = _map(progress.status);

    return AnimatedContainer(
      duration: AppUi.animationMedium,
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(
        horizontal: AppUi.gapMD,
        vertical: AppUi.gapXSPlus,
      ),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(AppUi.radiusPill),
      ),
      child: AnimatedSwitcher(
        duration: AppUi.animationShort,
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Row(
          key: ValueKey(config.label),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: AppUi.iconSizeXS, color: config.foreground),
            const SizedBox(width: AppUi.gapXSPlus),
            Text(
              config.label,
              style: AppText.caption.copyWith(color: config.foreground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  _Config _map(BookProgressStatus status) {
    switch (status) {
      case BookProgressStatus.completed:
        return _Config(
          label: AppStrings.progressStatusCompleted,
          icon: Icons.check,
          foreground: AppColors.primary,
          background: AppColors.primary.withValues(alpha: 0.12),
        );

      case BookProgressStatus.inProgress:
        return _Config(
          label: AppStrings.progressStatusInProgress,
          icon: Icons.play_arrow,
          foreground: AppColors.primary,
          background: AppColors.primary.withValues(alpha: 0.12),
        );

      case BookProgressStatus.notStarted:
        return _Config(
          label: AppStrings.progressStatusNotStarted,
          icon: Icons.circle_outlined,
          foreground: AppColors.textMuted,
          background: AppColors.textMuted.withValues(alpha: 0.12),
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
