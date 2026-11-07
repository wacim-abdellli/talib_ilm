import 'package:flutter/material.dart';
import '../../app/theme/app_palette.dart';

class AppProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color? color;
  final Color? backgroundColor;
  final double height;

  const AppProgress({
    super.key,
    required this.progress,
    this.color,
    this.backgroundColor,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final clamped = progress.clamp(0.0, 1.0);
    final isComplete = clamped >= 1.0;
    final fillColor = color ?? (isComplete ? palette.gold : palette.primary);
    final trackBg = backgroundColor ?? palette.progressTrackFor(color);
    final trackBorder = palette.progressTrackBorderFor(color);

    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: trackBg,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(
          color: trackBorder,
          width: 0.8,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final activeWidth = clamped > 0
              ? (constraints.maxWidth * clamped).clamp(height, constraints.maxWidth)
              : 0.0;
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: AnimatedContainer(
              duration: AppMotion.base,
              curve: AppMotion.easeOut,
              height: height,
              width: activeWidth,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
          );
        },
      ),
    );
  }
}
