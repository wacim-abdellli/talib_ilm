import 'package:flutter/material.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_palette.dart';
import '../../features/favorites/presentation/favorites_page.dart';
import '../navigation/fade_page_route.dart';
import 'app_button.dart';
import 'app_list_tile.dart';
import 'app_sheet.dart';

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
  const AppOverflowMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final menuItems = _defaultItems(context);

    return AppIconButton(
      tooltip: AppStrings.tooltipMenu,
      icon: Icons.menu,
      onPressed: () => _showSheet(context, menuItems),
    );
  }

  List<AppMenuItem> _defaultItems(BuildContext context) {
    return [
      AppMenuItem(
        label: AppStrings.navFavorites,
        icon: Icons.star_outline_rounded,
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
        icon: Icons.info_outline_rounded,
        onTap: () {
          Navigator.pop(context);
          _showAbout(context);
        },
      ),
    ];
  }

  void _showSheet(BuildContext context, List<AppMenuItem> items) {
    AppSheet.show(
      context: context,
      builder: (sheetContext) => AppSheet(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: items
              .map(
                (item) => AppListTile(
                  icon: item.icon,
                  title: item.label,
                  onTap: item.onTap,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    final textTheme = context.text;
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion: AppStrings.appVersion,
      children: [
        Text(AppStrings.appTagline, style: textTheme.body),
      ],
    );
  }

  void _showAppearance(BuildContext context) {
    AppSheet.show(
      context: context,
      builder: (sheetContext) {
        final palette = sheetContext.palette;
        final textTheme = sheetContext.text;

        return AppSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette_outlined, color: palette.text, size: AppIcon.lg),
                  const SizedBox(width: AppSpace.sm),
                  Text(AppStrings.moreThemeTitle, style: textTheme.titleSmall),
                  const Spacer(),
                  AppIconButton(
                    tooltip: AppStrings.actionClose,
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                AppStrings.moreThemeInfo,
                style: textTheme.body.copyWith(color: palette.textMuted),
              ),
              const SizedBox(height: AppSpace.lg),
            ],
          ),
        );
      },
    );
  }
}
