import 'package:flutter/material.dart';
import '../../app/theme/app_palette.dart';

class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color? bg;
  final Color? fg;
  final double size;
  final double iconSize;

  const IconBadge({
    super.key,
    required this.icon,
    this.bg,
    this.fg,
    this.size = 44.0,
    this.iconSize = AppIcon.md,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final effectiveBg = bg ?? palette.primarySoft;
    final effectiveFg = fg ?? palette.onPrimarySoft;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: effectiveFg,
        ),
      ),
    );
  }
}
