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

    return AppBar(
      backgroundColor: palette.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: height,
      leading: _buildLeading(context),
      title: Text(
        title,
        style: textTheme.titleSmall.copyWith(color: palette.text),
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
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final icon =
        leadingIcon ??
        (isRtl
            ? Icons.arrow_forward_ios_rounded
            : Icons.arrow_back_ios_new_rounded);
    final tap = onLeadingTap ?? () => Navigator.maybePop(context);
    return IconButton(
      tooltip: AppStrings.tooltipBack,
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
