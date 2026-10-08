import 'package:flutter/material.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../core/models/favorite_item.dart';
import '../../../core/services/favorites_service.dart';

import '../../../shared/widgets/app_states.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FavoritesService _service = FavoritesService();
  late Future<List<FavoriteItem>> _future;
  int _itemCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _service.getAll().then((items) {
      if (mounted) {
        setState(() => _itemCount = items.length);
      }
      return items;
    });
  }

  void _reload() {
    setState(() {
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(
                bottom: BorderSide(color: context.outlineVariantColor, width: 1),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.goldColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: context.goldColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.bookmark_rounded,
                      color: context.goldColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المفضلة',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$_itemCount عنصر محفوظ',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.textSecondaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: context.backgroundColor,
              child: FutureBuilder<List<FavoriteItem>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingIndicator();
                  }
                  final items = snapshot.data ?? const [];
                  if (items.isEmpty) {
                    return Padding(
                      padding: AppUi.screenPadding,
                      child: AppEmptyState.favorites(),
                    );
                  }

                  final grouped = <FavoriteType, List<FavoriteItem>>{};
                  for (final item in items) {
                    grouped.putIfAbsent(item.type, () => []).add(item);
                  }

                  return ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: AppUi.screenPadding,
                    children: FavoriteType.values
                        .where(grouped.containsKey)
                        .map((type) {
                          final list = grouped[type]!;
                          return _Section(
                            title: _labelFor(type),
                            items: list,
                            onRemove: (item) async {
                              await _service.remove(item.type, item.id);
                              _reload();
                            },
                          );
                        })
                        .toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<FavoriteItem> items;
  final void Function(FavoriteItem item) onRemove;

  const _Section({
    required this.title,
    required this.items,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppUi.radiusMD);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppText.heading.copyWith(color: context.textPrimaryColor),
        ),
        const SizedBox(height: AppUi.gapMD),
        ...items.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: AppUi.gapMD),
            padding: AppUi.cardPadding,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: radius,
              border: Border.all(
                color: context.outlineVariantColor,
                width: AppUi.dividerThickness,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppText.body.copyWith(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.subtitle.isNotEmpty) ...[
                        const SizedBox(height: AppUi.gapXSPlus),
                        Text(
                          item.subtitle,
                          style: AppText.caption.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.favoritesRemoveTooltip,
                  onPressed: () => onRemove(item),
                  icon: Icon(
                    Icons.bookmark_remove_rounded,
                    color: context.goldColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppUi.gapXL),
      ],
    );
  }
}

String _labelFor(FavoriteType type) {
  switch (type) {
    case FavoriteType.hadith:
      return AppStrings.favoriteTypeHadith;
    case FavoriteType.dhikr:
      return AppStrings.favoriteTypeDhikr;
    case FavoriteType.dua:
      return AppStrings.favoriteTypeDua;
    case FavoriteType.lesson:
      return AppStrings.favoriteTypeLesson;
    case FavoriteType.book:
      return AppStrings.favoriteTypeBook;
    case FavoriteType.quran:
      return AppStrings.favoriteTypeQuran;
    case FavoriteType.quote:
      return AppStrings.favoriteTypeQuote;
  }
}
