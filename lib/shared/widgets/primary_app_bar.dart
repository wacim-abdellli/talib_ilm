import 'package:flutter/material.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_ui.dart';
import '../../app/theme/theme_colors.dart';
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
    this.height = AppUi.appBarHeight,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.backgroundColor, // BackgroundMain
      elevation: 0,
      centerTitle: true,
      toolbarHeight: height,
      leading: _buildLeading(context),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: context.textPrimaryColor,
        ),
      ),
      actions: actions.isEmpty ? [const SizedBox(width: 48)] : actions,
      shape: Border(bottom: BorderSide(color: context.borderColor, width: 1)),
      bottom: bottom,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (!showBack && !showMenu && leadingIcon == null) return null;
    if (showMenu && !showBack && leadingIcon == null) {
      if (onMenuTap != null) {
        return IconButton(
          tooltip: AppStrings.tooltipMenu,
          onPressed: onMenuTap,
          icon: Icon(Icons.menu, color: context.textPrimaryColor),
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
        size: 20,
        color: context.primaryColor, // PrimaryAccent
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
