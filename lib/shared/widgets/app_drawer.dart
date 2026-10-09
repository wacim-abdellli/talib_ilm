import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_ui.dart';
import '../../app/theme/theme_colors.dart';
import '../navigation/app_shell.dart';
import '../navigation/fade_page_route.dart';
import '../../features/favorites/presentation/favorites_page.dart';
import '../../features/quran/presentation/quran_page.dart';

class AppDrawer extends StatelessWidget {
  final int? selectedIndex;

  const AppDrawer({super.key, this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: context.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppUi.radiusLG),
          bottomLeft: Radius.circular(AppUi.radiusLG),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primaryColor,
                  AppColors.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.25),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.menu_book_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.appName,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'v${AppStrings.appVersion}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // MENU ITEMS
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              physics: const BouncingScrollPhysics(),
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
                  icon: Icons.favorite_rounded,
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
                  height: 24,
                  indent: 20,
                  endIndent: 20,
                  color: context.outlineVariantColor,
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
                      trailing: Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: isDark,
                          onChanged: (_) => themeService.toggleTheme(),
                          activeThumbColor: context.primaryColor,
                        ),
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

          // ═══════════════════════════════════════════════════════════════════
          // FOOTER
          // ═══════════════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'وفق منهج أهل السنة والجماعة',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: context.textTertiaryColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goShell(BuildContext context, int index) {
    Navigator.pop(context); // Close drawer
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
    final activeColor = context.primaryColor;
    final textColor = isActive ? activeColor : context.textPrimaryColor;
    final iconColor = isActive ? activeColor : context.textSecondaryColor;

    return ListTile(
      leading: Icon(icon, size: 22, color: iconColor),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: textColor,
          fontFamily: 'Cairo',
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      horizontalTitleGap: 12,
      dense: true,
      tileColor: isActive
          ? activeColor.withValues(alpha: context.isDark ? 0.15 : 0.08)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
