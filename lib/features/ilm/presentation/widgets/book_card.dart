import 'package:flutter/material.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../app/theme/app_ui.dart';
import '../../data/models/mutun_models.dart';
import '../../../../shared/widgets/progress_pill.dart';
import '../../data/models/progress_models.dart';
import '../../../../shared/widgets/pressable_card.dart';

class BookCard extends StatelessWidget {
  final IlmBook book;
  final BookProgress progress;
  final VoidCallback onTap;

  const BookCard({
    super.key,
    required this.book,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = progress.status;
    final percent = _progressValue(progress);
    final percentLabel = _progressLabel(progress, percent);
    final statusLabel = switch (status) {
      BookProgressStatus.completed => AppStrings.progressStatusCompleted,
      BookProgressStatus.inProgress => AppStrings.progressStatusInProgress,
      _ => AppStrings.progressStatusNew,
    };
    final color = switch (status) {
      BookProgressStatus.completed => AppColors.primary,
      BookProgressStatus.inProgress => AppColors.primary,
      _ => AppColors.textMuted,
    };
    final radius = BorderRadius.circular(AppUi.radiusMD);

    return PressableCard(
      onTap: onTap,
      padding: AppUi.cardPadding,
      borderRadius: radius,
      decoration: BoxDecoration(
        gradient: AppColors.surfaceElevatedGradient,
        borderRadius: radius,
        border: Border.all(
          color: AppColors.stroke,
          width: AppUi.dividerThickness,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppUi.gapSM),
                child: _ProgressRing(
                  value: percent,
                  color: color,
                  label: percentLabel,
                ),
              ),
              const SizedBox(width: AppUi.gapMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: AppText.heading,
                    ),
                    const SizedBox(height: AppUi.gapXS),
                    Row(
                      children: [
                        ProgressPill(progress: progress),
                        const SizedBox(width: AppUi.gapSM),
                        Expanded(
                          child: Text(
                            statusLabel,
                            style: AppText.bodyMuted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppUi.gapSM),
                    Text(book.author, style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _progressValue(BookProgress progress) {
    if (progress.totalLessons > 0) {
      return (progress.completedLessons / progress.totalLessons).clamp(0, 1);
    }
    return progress.status == BookProgressStatus.completed ? 1 : 0;
  }

  String _progressLabel(BookProgress progress, double value) {
    if (progress.totalLessons > 0) {
      return AppStrings.percentLabel((value * 100).round());
    }
    if (progress.status == BookProgressStatus.completed) {
      return AppStrings.percentLabel(100);
    }
    if (progress.status == BookProgressStatus.notStarted) {
      return AppStrings.percentLabel(0);
    }
    return AppStrings.progressUnknown;
  }
}

class _ProgressRing extends StatelessWidget {
  final double value;
  final Color color;
  final String label;

  const _ProgressRing({
    required this.value,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppUi.progressRingSize,
      height: AppUi.progressRingSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: AppUi.progressRingSize,
            height: AppUi.progressRingSize,
            child: CircularProgressIndicator(
              value: value.clamp(0, 1),
              strokeWidth: AppUi.progressRingStroke,
              backgroundColor: AppColors.stroke,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            label,
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}
