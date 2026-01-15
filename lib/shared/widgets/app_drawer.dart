import 'package:flutter/material.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/app_ui.dart';
import '../navigation/app_shell.dart';
import '../../features/favorites/presentation/favorites_page.dart';
import '../../features/more/presentation/more_page.dart';
import '../navigation/fade_page_route.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * AppUi.drawerWidthFactor;
    return SizedBox(
      width: width,
      child: Drawer(
        backgroundColor: AppColors.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(AppUi.radiusLG),
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: AppUi.screenPadding,
            children: [
              Center(
                child: Container(
                  width: AppUi.handleWidth,
                  height: AppUi.handleHeight,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(AppUi.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: AppUi.gapMD),
              _DrawerItem(
                label: AppStrings.navHome,
                icon: Icons.home_outlined,
                onTap: () => _goShell(context, 2),
              ),
              _DrawerItem(
                label: AppStrings.navLibrary,
                icon: Icons.local_library_outlined,
                onTap: () => _goShell(context, 4),
              ),
              _DrawerItem(
                label: AppStrings.navFavorites,
                icon: Icons.star_outline,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) =>
                          const AppShell(initialIndex: 2),
                      transitionDuration: Duration.zero,
                    ),
                    (route) => false,
                  );
                  Navigator.push(
                    context,
                    buildFadeRoute(page: const FavoritesPage()),
                  );
                },
              ),
              _DrawerItem(
                label: AppStrings.navSettings,
                icon: Icons.settings_outlined,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    buildFadeRoute(page: const MorePage()),
                  );
                },
              ),
              _DrawerItem(
                label: AppStrings.navAbout,
                icon: Icons.info_outline,
                onTap: () {
                  Navigator.pop(context);
                  _showAbout(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goShell(BuildContext context, int index) {
    Navigator.pop(context);
    Navigator.pushAndRemoveUntil(
      context,
      buildFadeRoute(page: AppShell(initialIndex: index)),
      (route) => false,
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion: AppStrings.appVersion,
      children: [Text(AppStrings.appTagline, style: AppText.body)],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textPrimary.withValues(alpha: 0.8)),
      title: Text(label, style: AppText.body),
      onTap: onTap,
    );
  }
}
