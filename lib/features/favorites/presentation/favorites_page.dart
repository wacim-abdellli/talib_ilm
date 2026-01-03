import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/models/favorite_item.dart';
import '../../../core/services/favorites_service.dart';
import '../../../shared/widgets/primary_app_bar.dart';

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
      backgroundColor: AppColors.background,
      appBar: const PrimaryAppBar(
        title: 'المفضلة',
        showBack: true,
      ),
      body: FutureBuilder<List<FavoriteItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return _EmptyFavorites(onReload: _reload);
          }

          final grouped = <FavoriteType, List<FavoriteItem>>{};
          for (final item in items) {
            grouped.putIfAbsent(item.type, () => []).add(item);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: FavoriteType.values
                .where(grouped.containsKey)
                .map((type) {
                  final list = grouped[type]!;
                  return _Section(
                    title: type.labelAr,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.heading),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppUi.cardShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: AppText.body),
                      if (item.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(item.subtitle, style: AppText.caption),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'إزالة من المفضلة',
                  onPressed: () => onRemove(item),
                  icon: const Icon(Icons.star, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  final VoidCallback onReload;

  const _EmptyFavorites({required this.onReload});

  @override
  Widget build(BuildContext context) {
    const secondary = AppColors.textSecondary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_border, size: 40, color: AppColors.primary),
            const SizedBox(height: 12),
            Text('لا توجد عناصر مفضلة', style: AppText.heading),
            const SizedBox(height: 6),
            Text(
              'اضغط على النجمة لحفظ العناصر المهمة.',
              style: AppText.body.copyWith(color: secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onReload,
              child: const Text('تحديث'),
            ),
          ],
        ),
      ),
    );
  }
}
