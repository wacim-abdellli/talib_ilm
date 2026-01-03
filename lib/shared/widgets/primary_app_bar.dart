import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';

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
    this.height = 64,
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
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 8,
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
      shadowColor: Colors.transparent,
    );
  }

  PreferredSizeWidget _buildBottomDivider() {
    final divider = Container(
      height: 0.8,
      color: AppColors.textMuted.withValues(alpha: 0.12),
    );

    final bottomWidget = bottom;
    if (bottomWidget == null) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: divider,
      );
    }

    return PreferredSize(
      preferredSize: Size.fromHeight(bottomWidget.preferredSize.height + 1),
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
      return Builder(
        builder: (context) {
          return IconButton(
            tooltip: 'القائمة',
            onPressed: onMenuTap ?? () => Scaffold.maybeOf(context)?.openDrawer(),
            icon: const Icon(Icons.menu),
          );
        },
      );
    }
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final icon = leadingIcon ??
        (isRtl
            ? Icons.arrow_forward_ios_rounded
            : Icons.arrow_back_ios_new_rounded);
    final tap = onLeadingTap ?? () => Navigator.maybePop(context);
    return IconButton(
      tooltip: 'رجوع',
      onPressed: tap,
      icon: Icon(icon, size: 18),
    );
  }
}
