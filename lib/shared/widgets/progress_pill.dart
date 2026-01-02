import 'package:flutter/material.dart';
import '../../features/ilm/data/models/progress_models.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';

class ProgressPill extends StatelessWidget {
  final BookProgress progress;

  const ProgressPill({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final _Config config = _map(progress.status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Row(
          key: ValueKey(config.label),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: 14, color: config.foreground),
            const SizedBox(width: 6),
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
          label: 'مكتمل',
          icon: Icons.check,
          foreground: AppColors.success,
          background: AppColors.success.withValues(alpha: 0.12),
        );

      case BookProgressStatus.inProgress:
        return _Config(
          label: 'قيد التقدم',
          icon: Icons.play_arrow,
          foreground: AppColors.primaryAlt,
          background: AppColors.primaryAlt.withValues(alpha: 0.12),
        );

      case BookProgressStatus.notStarted:
        return _Config(
          label: 'لم يبدأ',
          icon: Icons.circle_outlined,
          foreground: AppColors.textSecondary,
          background: AppColors.textSecondary.withValues(alpha: 0.12),
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
