import 'package:flutter/material.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
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

  @override
  void initState() {
    super.initState();
    _future = _service.getAll();
  }

  void _reload() {
    setState(() {
      _future = _service.getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المفضلة',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '12 عنصر محفوظ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sort_rounded, size: 26),
                    color: const Color(0xFF64748B),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.backgroundGradient,
              ),
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
        Text(title, style: AppText.heading),
        const SizedBox(height: AppUi.gapMD),
        ...items.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: AppUi.gapMD),
            padding: AppUi.cardPadding,
            decoration: BoxDecoration(
              gradient: AppColors.surfaceGradient,
              borderRadius: radius,
              border: Border.all(
                color: AppColors.stroke,
                width: AppUi.dividerThickness,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: AppText.body),
                      if (item.subtitle.isNotEmpty) ...[
                        const SizedBox(height: AppUi.gapXSPlus),
                        Text(item.subtitle, style: AppText.caption),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.favoritesRemoveTooltip,
                  onPressed: () => onRemove(item),
                  icon: Icon(Icons.star, color: AppColors.textMuted),
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
