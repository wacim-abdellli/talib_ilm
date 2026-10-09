import 'package:flutter/material.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_palette.dart';
import '../../../core/models/favorite_item.dart';
import '../../../core/services/favorites_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
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
    final palette = context.palette;
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: palette.bg,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xl,
              AppSpace.lg,
              AppSpace.xl,
              AppSpace.xl,
            ),
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border(
                bottom: BorderSide(color: palette.border, width: 1),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    width: AppSize.tap,
                    height: AppSize.tap,
                    decoration: BoxDecoration(
                      color: palette.goldSoft,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: palette.gold.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.bookmark_rounded,
                      color: palette.gold,
                      size: AppIcon.lg,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المفضلة',
                          style: textTheme.title.copyWith(
                            color: palette.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$_itemCount عنصر محفوظ',
                          style: textTheme.bodySmall.copyWith(
                            color: palette.textMuted,
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
            child: FutureBuilder<List<FavoriteItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingIndicator();
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpace.xl),
                    child: AppEmptyState.favorites(),
                  );
                }

                final grouped = <FavoriteType, List<FavoriteItem>>{};
                for (final item in items) {
                  grouped.putIfAbsent(item.type, () => []).add(item);
                }

                final sections = FavoriteType.values
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
                    .toList();

                return ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.xl,
                    vertical: AppSpace.lg,
                  ),
                  children: [
                    ...sections,
                    SizedBox(height: AppSize.navClearance(context)),
                  ],
                );
              },
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
    final palette = context.palette;
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleSmall.copyWith(color: palette.text),
        ),
        const SizedBox(height: AppSpace.sm),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: textTheme.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.text,
                          ),
                        ),
                        if (item.subtitle.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            item.subtitle,
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AppIconButton(
                    tooltip: AppStrings.favoritesRemoveTooltip,
                    onPressed: () => onRemove(item),
                    icon: Icons.bookmark_remove_rounded,
                    color: palette.gold,
                    iconSize: AppIcon.md,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
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
