import 'package:flutter/material.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/app_ui.dart';
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
      toolbarHeight: height,
      elevation: 0,
      backgroundColor: AppColors.background,
      surfaceTintColor: AppColors.clear,
      automaticallyImplyLeading: false,
      titleSpacing: AppUi.gapSM,
      centerTitle: true,
      leading: _buildLeading(context),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.headline,
      ),
      actions: actions,
      bottom: _buildBottomDivider(),
      shadowColor: AppColors.clear,
    );
  }

  PreferredSizeWidget _buildBottomDivider() {
    final divider = Container(
      height: AppUi.dividerThickness,
      color: AppColors.textMuted.withValues(alpha: 0.12),
    );

    final bottomWidget = bottom;
    if (bottomWidget == null) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(AppUi.dividerThickness),
        child: divider,
      );
    }

    return PreferredSize(
      preferredSize: Size.fromHeight(
        bottomWidget.preferredSize.height + AppUi.dividerThickness,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          bottomWidget,
          divider,
        ],
      ),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (!showBack && !showMenu && leadingIcon == null) return null;
    if (showMenu && !showBack && leadingIcon == null) {
      if (onMenuTap != null) {
        return IconButton(
          tooltip: AppStrings.tooltipMenu,
          onPressed: onMenuTap,
          icon: const Icon(Icons.menu),
        );
      }
      return const AppOverflowMenu();
    }
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final icon = leadingIcon ??
        (isRtl
            ? Icons.arrow_forward_ios_rounded
            : Icons.arrow_back_ios_new_rounded);
    final tap = onLeadingTap ?? () => Navigator.maybePop(context);
    return IconButton(
      tooltip: AppStrings.tooltipBack,
      onPressed: tap,
      icon: Icon(icon, size: AppUi.iconSizeSM),
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
