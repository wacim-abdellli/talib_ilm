import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_palette.dart';
import '../navigation/app_shell.dart';
import '../navigation/fade_page_route.dart';
import '../../features/favorites/presentation/favorites_page.dart';
import '../../features/quran/presentation/quran_page.dart';

class AppDrawer extends StatelessWidget {
  final int? selectedIndex;

  const AppDrawer({super.key, this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: palette.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.lg),
          bottomLeft: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Column(
        children: [
          // Calm Scholar Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.xl,
              vertical: AppSpace.xxl,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              border: Border(bottom: BorderSide(color: palette.border, width: 1)),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: palette.primarySoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.border, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.sm),
                      child: Image.asset(
                        palette.logoSymbol,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => Icon(
                          Icons.menu_book_rounded,
                          size: AppIcon.lg,
                          color: palette.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.appName,
                          style: textTheme.titleSmall.copyWith(color: palette.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'v${AppStrings.appVersion}',
                          style: textTheme.caption.copyWith(color: palette.textSubtle),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // MENU ITEMS
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.md, horizontal: AppSpace.sm),
              children: [
                _DrawerItem(
                  icon: Icons.home_rounded,
                  label: AppStrings.navHome,
                  isActive: selectedIndex == 0,
                  onTap: () => _goShell(context, 0),
                ),
                _DrawerItem(
                  icon: Icons.access_time_rounded,
                  label: AppStrings.navPrayer,
                  isActive: selectedIndex == 1,
                  onTap: () => _goShell(context, 1),
                ),
                _DrawerItem(
                  icon: Icons.auto_stories_rounded,
                  label: 'طلب العلم',
                  isActive: selectedIndex == 2,
                  onTap: () => _goShell(context, 2),
                ),
                _DrawerItem(
                  icon: Icons.spa_rounded,
                  label: 'الأذكار والأدعية',
                  isActive: selectedIndex == 3,
                  onTap: () => _goShell(context, 3),
                ),
                _DrawerItem(
                  icon: Icons.menu_book_rounded,
                  label: 'القرآن الكريم',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      buildFadeRoute(page: const QuranPage()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.bookmark_border_rounded,
                  label: AppStrings.navFavorites,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      buildFadeRoute(page: const FavoritesPage()),
                    );
                  },
                ),
                Divider(
                  height: AppSpace.xxl,
                  indent: AppSpace.md,
                  endIndent: AppSpace.md,
                  color: palette.border,
                ),
                _DrawerItem(
                  icon: Icons.settings_rounded,
                  label: AppStrings.navSettings,
                  isActive: selectedIndex == 4,
                  onTap: () => _goShell(context, 4),
                ),
                ListenableBuilder(
                  listenable: themeService,
                  builder: (context, _) {
                    final isDark = themeService.isDark ||
                        (themeService.isSystem &&
                            Theme.of(context).brightness == Brightness.dark);
                    return _DrawerItem(
                      icon: isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      label: 'الوضع الداكن',
                      trailing: Switch(
                        value: isDark,
                        onChanged: (_) => themeService.toggleTheme(),
                      ),
                      onTap: () => themeService.toggleTheme(),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.share_rounded,
                  label: 'مشاركة التطبيق',
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(
                      'تطبيق طالب العلم - رفيقك اليومي في طلب العلم الشرعي والصلاة والأذكار.',
                    );
                  },
                ),
              ],
            ),
          ),
          // FOOTER
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
            child: Text(
              'وفق منهج أهل السنة والجماعة',
              style: textTheme.caption.copyWith(color: palette.textSubtle),
            ),
          ),
        ],
      ),
    );
  }

  void _goShell(BuildContext context, int index) {
    Navigator.pop(context);
    final handled = AppShell.switchToTab(context, index);
    if (!handled) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, anim1, anim2) => AppShell(initialIndex: index),
          transitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isActive;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Material(
        color: isActive ? palette.primarySoft : Colors.transparent,
        borderRadius: AppRadius.mdRadius,
        child: InkWell(
          borderRadius: AppRadius.mdRadius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.tap),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: AppIcon.md,
                    color: isActive ? palette.primary : palette.textMuted,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Text(
                      label,
                      style: textTheme.body.copyWith(
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? palette.primary : palette.text,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
