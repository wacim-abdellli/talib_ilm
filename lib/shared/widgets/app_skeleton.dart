import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/theme/app_palette.dart';

class AppSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final Widget? child;

  const AppSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.child,
  });

  const AppSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null,
        shape = BoxShape.circle,
        child = null;

  const AppSkeleton.line({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
  })  : shape = BoxShape.rectangle,
        child = null;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final content = child ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            shape: shape,
            borderRadius: shape == BoxShape.circle
                ? null
                : (borderRadius ?? AppRadius.smRadius),
          ),
        );

    return Shimmer.fromColors(
      baseColor: palette.surfaceMuted,
      highlightColor: palette.border,
      child: content,
    );
  }
}
