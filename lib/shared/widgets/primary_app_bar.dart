import 'package:flutter/material.dart';
import '../../app/constants/app_strings.dart';
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
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Leading
            if (showBack || showMenu || leadingIcon != null)
              _buildLeading(context) ?? const SizedBox(width: 40)
            else
              const SizedBox(width: 40),

            // Title (centered)
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  fontFamily: 'Cairo',
                ),
              ),
            ),

            // Actions
            if (actions.isNotEmpty)
              Row(mainAxisSize: MainAxisSize.min, children: actions)
            else
              const SizedBox(width: 40),
          ],
        ),
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
    final icon =
        leadingIcon ??
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
