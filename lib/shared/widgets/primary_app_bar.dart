import 'package:flutter/material.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_palette.dart';
import 'app_overflow_menu.dart';

class PrimaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final bool showBack;
  final bool showMenu;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingTap;
  final VoidCallback? onMenuTap;
  final double height;
  final PreferredSizeWidget? bottom;

  const PrimaryAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.showBack = false,
    this.showMenu = false,
    this.leadingIcon,
    this.onLeadingTap,
    this.onMenuTap,
    this.height = AppSize.navH,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final hasManyActions = actions.length > 1;

    return AppBar(
      backgroundColor: palette.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: hasManyActions ? false : true,
      toolbarHeight: height,
      leadingWidth: (showBack || showMenu || leadingIcon != null) ? 44.0 : null,
      titleSpacing: hasManyActions ? AppSpace.xs : null,
      leading: _buildLeading(context),
      title: Tooltip(
        message: title,
        child: Text(
          title,
          style: (hasManyActions ? textTheme.bodySmall : textTheme.body).copyWith(
            color: palette.text,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          maxLines: 2,
          textAlign: hasManyActions ? TextAlign.start : TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: actions.isEmpty ? [const SizedBox(width: AppSize.tap)] : actions,
      shape: Border(bottom: BorderSide(color: palette.border, width: 1)),
      bottom: bottom,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    final palette = context.palette;
    if (!showBack && !showMenu && leadingIcon == null) return null;
    if (showMenu && !showBack && leadingIcon == null) {
      if (onMenuTap != null) {
        return IconButton(
          tooltip: AppStrings.tooltipMenu,
          onPressed: onMenuTap,
          icon: Icon(Icons.menu, color: palette.text, size: AppIcon.lg),
        );
      }
      return const AppOverflowMenu();
    }
    final icon = leadingIcon ?? Icons.arrow_back_ios_new_rounded;
    final tap = onLeadingTap ?? () => Navigator.maybePop(context);
    return IconButton(
      tooltip: AppStrings.tooltipBack,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onPressed: tap,
      icon: Icon(
        icon,
        size: AppIcon.md,
        color: palette.text,
      ),
    );
  }
}

class UnifiedAppBar extends PrimaryAppBar {
  const UnifiedAppBar({
    super.key,
    required super.title,
    super.actions,
    super.showBack,
    super.showMenu,
    super.leadingIcon,
    super.onLeadingTap,
    super.onMenuTap,
    super.height,
    super.bottom,
  });
}
