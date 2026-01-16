import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:talib_ilm/shared/widgets/app_snackbar.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_ui.dart';
import '../navigation/app_shell.dart';
import '../../features/favorites/presentation/favorites_page.dart';
import '../../features/more/presentation/more_page.dart';
import '../navigation/fade_page_route.dart';

class AppDrawer extends StatelessWidget {
  final int? selectedIndex;

  const AppDrawer({super.key, this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    // Standard drawer width usually 304 on mobile or widthFactor
    // User requested "App Name 24sp bold white"
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppUi.radiusLG),
          bottomLeft: Radius.circular(AppUi.radiusLG),
        ),
      ),
      child: Column(
        children: [
          // ═══════════════════════════════════════════════════════════════════
          // HEADER: 200 height, Gradient Teal -> Dark Teal
          // ═══════════════════════════════════════════════════════════════════
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo 80 size
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        color: Colors.white,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.menu_book_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // App Name 24sp bold white
                  Text(
                    AppStrings.appName,
                    style: AppTextStyles.heading1.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Version 12sp white 70%
                  Text(
                    'v${AppStrings.appVersion}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════════════════════
          // MENU ITEMS
          // ═══════════════════════════════════════════════════════════════════
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                _DrawerItem(
                  icon: Icons.home_rounded,
                  label: AppStrings.navHome,
                  isActive: selectedIndex == 0,
                  onTap: () => _goShell(context, 0),
                ),
                _DrawerItem(
                  icon: Icons.bar_chart_rounded, // My Progress
                  label: 'تقدمي',
                  isActive: selectedIndex == 2,
                  onTap: () => _goShell(context, 2), // Ilm Page
                ),
                _DrawerItem(
                  icon: Icons.favorite_border_rounded,
                  label: AppStrings.navFavorites,
                  badge:
                      'جديد', // Logic would be dynamic, hardcoded for design as requested "with badge"
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      buildFadeRoute(page: const FavoritesPage()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.download_outlined,
                  label: 'التنزيلات',
                  isActive: selectedIndex == 4,
                  onTap: () =>
                      _goShell(context, 4), // Library page has downloads
                ),
                const Divider(height: 32, indent: 24, endIndent: 24),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: AppStrings.navSettings,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      buildFadeRoute(page: const MorePage()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.dark_mode_outlined,
                  label: 'الوضع الداكن',
                  trailing: Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: false, // TODO: Connect to theme provider
                      onChanged: (val) {
                        AppSnackbar.show(
                          context,
                          message: 'سيتم تفعيل الوضع الداكن قريباً',
                        );
                      },
                      activeThumbColor: AppColors.primary,
                    ),
                  ),
                  onTap: () {
                    // Toggle action handled by Switch, but tapping row can also toggle
                    AppSnackbar.show(
                      context,
                      message: 'سيتم تفعيل الوضع الداكن قريباً',
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.language,
                  label: 'اللغة: العربية',
                  onTap: () {
                    AppSnackbar.show(
                      context,
                      message: 'إعدادات اللغة قادمة قريباً',
                    );
                  },
                ),
                const Divider(height: 32, indent: 24, endIndent: 24),
                _DrawerItem(
                  icon: Icons.info_outline_rounded,
                  label: AppStrings.navAbout,
                  onTap: () {
                    Navigator.pop(context);
                    showAboutDialog(
                      context: context,
                      applicationName: AppStrings.appName,
                      applicationVersion: AppStrings.appVersion,
                      applicationIcon: Image.asset(
                        'assets/images/logo.png',
                        width: 48,
                        height: 48,
                      ),
                      children: [
                        Text(
                          AppStrings.appTagline,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.star_rate_rounded, // or outline
                  label: 'قيّم التطبيق',
                  onTap: () {
                    // Placeholder
                    Navigator.pop(context);
                    AppSnackbar.show(
                      context,
                      message: 'شكراً لدعمك! التقييم سيتوفر قريباً',
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.share_rounded,
                  label: 'مشاركة التطبيق',
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(
                      'حمل تطبيق طالب العلم وابدأ رحلة التعلم المنهجي!',
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.mail_outline_rounded,
                  label: 'تواصل معنا',
                  onTap: () {
                    Navigator.pop(context);
                    // Placeholder
                    AppSnackbar.show(
                      context,
                      message: 'تواصل معنا عبر البريد: contact@talibalilm.com',
                    );
                  },
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════════════════
          // FOOTER: Social icons + Privacy Policy
          // ═══════════════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialIcon(
                      icon: Icons.facebook,
                      onTap: () {},
                    ), // Placeholder social
                    const SizedBox(width: 16),
                    _SocialIcon(
                      icon: Icons.smart_display_rounded,
                      onTap: () {},
                    ), // Youtube
                    const SizedBox(width: 16),
                    _SocialIcon(
                      icon: Icons.alternate_email_rounded,
                      onTap: () {},
                    ), // Twitter/X replacement idea or just @
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    // Privacy Policy Link
                    AppSnackbar.show(context, message: 'سياسة الخصوصية');
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      'سياسة الخصوصية',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goShell(BuildContext context, int index) {
    Navigator.pop(context); // Close drawer
    // If we are already in AppShell, we might need a way to switch index via context or global key.
    // However, pushing a new AppShell works but resets state. Ideally we use a provider or callback.
    // For now, consistent with previous implementation: PushAndRemoveUntil
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

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final Widget? trailing;
  final bool isActive;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.trailing,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        size: 24,
        color: isActive ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: AppTextStyles.bodyLarge.copyWith(
          color: isActive ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing:
          trailing ??
          (badge != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      horizontalTitleGap: 16,
      minVerticalPadding: 0,
      dense: true,
      tileColor: isActive ? AppColors.primary.withValues(alpha: 0.1) : null,
      shape: isActive
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
            )
          : null,
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}
