import 'package:flutter/material.dart';
import '../../app/theme/app_palette.dart';

class AppTag extends StatelessWidget {
  final String label;
  final String? subject;
  final Color? fg;
  final Color? bg;
  final VoidCallback? onTap;

  const AppTag({
    super.key,
    required this.label,
    this.subject,
    this.fg,
    this.bg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final cat = palette.category(subject ?? label);
    final effectiveFg = fg ?? cat.fg;
    final effectiveBg = bg ?? cat.bg;

    final tag = Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: AppRadius.smRadius,
      ),
      child: Center(
        child: Text(
          label,
          style: textTheme.caption.copyWith(
            color: effectiveFg,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    if (onTap != null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSize.tap,
          minWidth: AppSize.tap,
        ),
        child: InkWell(
          borderRadius: AppRadius.smRadius,
          onTap: onTap,
          child: Center(child: tag),
        ),
      );
    }

    return tag;
  }
}
