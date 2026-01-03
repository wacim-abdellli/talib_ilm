import 'package:flutter/material.dart';
import '../../app/theme/app_text.dart';
import '../../features/favorites/presentation/favorites_page.dart';
import '../../features/more/presentation/more_page.dart';
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
  final List<AppMenuItem> items;
  final List<AppMenuItem> extraItems;
  final bool includeDefaults;

  const AppOverflowMenu({
    super.key,
    this.items = const [],
    this.extraItems = const [],
    this.includeDefaults = false,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = <AppMenuItem>[
      if (includeDefaults) ..._defaultItems(context),
      ...items,
      ...extraItems,
    ];

    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () => _showSheet(context, menuItems),
    );
  }

  List<AppMenuItem> _defaultItems(BuildContext context) {
    return [
      AppMenuItem(
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
      AppMenuItem(
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
      AppMenuItem(
        label: 'عن التطبيق',
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
      applicationName: 'طالب العلم',
      applicationVersion: '1.0.0',
      children: const [
        Text('تطبيق هادئ لخدمة طالب العلم.', style: AppText.body),
      ],
    );
  }
}
