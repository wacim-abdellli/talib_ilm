import 'package:flutter/material.dart';
import '../../app/theme/app_palette.dart';

class AppProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color? color;

  const AppProgress({super.key, required this.progress, this.color});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final clamped = progress.clamp(0.0, 1.0);
    final isComplete = clamped >= 1.0;
    final fillColor = color ?? (isComplete ? palette.gold : palette.primary);

    return Container(
      height: 6,
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.border,
        borderRadius: AppRadius.pillRadius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: AnimatedContainer(
              duration: AppMotion.base,
              curve: AppMotion.easeOut,
              height: 6,
              width: constraints.maxWidth * clamped,
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
