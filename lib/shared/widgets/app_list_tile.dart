import 'package:flutter/material.dart';
import '../../app/theme/app_palette.dart';
import 'icon_badge.dart';

class AppListTile extends StatelessWidget {
  final Widget? leading;
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool showChevron;
  final EdgeInsetsGeometry padding;

  const AppListTile({
    super.key,
    this.leading,
    this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = false,
    this.showChevron = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpace.lg,
      vertical: AppSpace.sm,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final leadingWidget = leading ??
        (icon != null ? IconBadge(icon: icon!) : null);

    final chevronIcon = isRtl
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;

    final effectiveTrailing = trailing ??
        (showChevron && onTap != null
            ? Icon(chevronIcon, size: AppIcon.md, color: palette.textSubtle)
            : null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: padding,
                child: Row(
                  children: [
                    if (leadingWidget != null) ...[
                      leadingWidget,
                      const SizedBox(width: AppSpace.md),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: textTheme.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: palette.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpace.xs / 2),
                            Text(
                              subtitle!,
                              style: textTheme.bodySmall.copyWith(
                                color: palette.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (effectiveTrailing != null) ...[
                      const SizedBox(width: AppSpace.sm),
                      effectiveTrailing,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: palette.border,
            indent: leadingWidget != null ? 60 : AppSpace.lg,
          ),
      ],
    );
  }
}
