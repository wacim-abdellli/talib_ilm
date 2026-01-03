import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../navigation/app_shell.dart';
import '../../features/favorites/presentation/favorites_page.dart';
import '../../features/more/presentation/more_page.dart';
import '../navigation/fade_page_route.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.78;
    return SizedBox(
      width: width,
      child: Drawer(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _DrawerItem(
              label: 'الرئيسية',
              icon: Icons.home_outlined,
              onTap: () => _goShell(context, 2),
            ),
            _DrawerItem(
              label: 'المكتبة',
              icon: Icons.local_library_outlined,
              onTap: () => _goShell(context, 4),
            ),
            _DrawerItem(
              label: 'المفضلة',
              icon: Icons.star_outline,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  buildFadeRoute(page: const FavoritesPage()),
                );
              },
            ),
            _DrawerItem(
              label: 'الإعدادات',
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
              label: 'حول التطبيق',
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
      applicationName: 'طالب العلم',
      applicationVersion: '1.0.0',
      children: const [
        Text('تطبيق هادئ لخدمة طالب العلم.', style: AppText.body),
      ],
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
