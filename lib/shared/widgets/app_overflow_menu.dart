import 'package:flutter/material.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_text.dart';
import '../../app/theme/app_ui.dart';
import '../../features/favorites/presentation/favorites_page.dart';
import '../navigation/fade_page_route.dart';

class AppMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const AppMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class AppOverflowMenu extends StatelessWidget {
  const AppOverflowMenu({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = _defaultItems(context);

    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () => _showSheet(context, menuItems),
    );
  }

  List<AppMenuItem> _defaultItems(BuildContext context) {
    return [
      AppMenuItem(
        label: AppStrings.navFavorites,
        icon: Icons.star_outline,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            buildFadeRoute(page: const FavoritesPage()),
          );
        },
      ),
      AppMenuItem(
        label: AppStrings.moreThemeTitle,
        icon: Icons.palette_outlined,
        onTap: () {
          Navigator.pop(context);
          _showAppearance(context);
        },
      ),
      AppMenuItem(
        label: AppStrings.navAbout,
        icon: Icons.info_outline,
        onTap: () {
          Navigator.pop(context);
          _showAbout(context);
        },
      ),
    ];
  }

  void _showSheet(BuildContext context, List<AppMenuItem> items) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppUi.radiusMD),
        ),
      ),
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppUi.paddingMD,
              AppUi.gapMD,
              AppUi.paddingMD,
              AppUi.paddingMD,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items
                  .map(
                    (item) => ListTile(
                      leading: Icon(item.icon,
                          color: colors.onSurface.withValues(alpha: 0.7)),
                      title: Text(item.label, style: AppText.body),
                      onTap: item.onTap,
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion: AppStrings.appVersion,
      children: [
        Text(AppStrings.appTagline, style: AppText.body),
      ],
    );
  }

  void _showAppearance(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppUi.radiusMD),
        ),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppUi.paddingMD,
              AppUi.gapMD,
              AppUi.paddingMD,
              AppUi.paddingMD,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.palette_outlined,
                        color:
                            Theme.of(context).colorScheme.onSurface),
                    const SizedBox(width: AppUi.gapSM),
                    Text(AppStrings.moreThemeTitle,
                        style: AppText.heading),
                    const Spacer(),
                    IconButton(
                      tooltip: AppStrings.actionClose,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppUi.gapSM),
                Text(
                  AppStrings.moreThemeInfo,
                  style: AppText.body.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppUi.gapMD),
              ],
            ),
          ),
        );
      },
    );
  }
}
