import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../data/adhkar_models.dart';
import '../data/adhkar_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/models/favorite_item.dart';

class DuasMiscPage extends StatelessWidget {
  DuasMiscPage({super.key});

  final AthkarService _service = AthkarService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PrimaryAppBar(
        title: 'أدعية وأذكار',
        showBack: true,
      ),
      body: FutureBuilder<AthkarCatalog>(
        future: _service.loadCatalog(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data?.byId('duas')?.items ?? const [];
          if (items.isEmpty) {
            return const SizedBox.shrink();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _DuaCard(item: item);
            },
          );
        },
      ),
    );
  }
}

class _DuaCard extends StatefulWidget {
  final AthkarItem item;

  const _DuaCard({required this.item});

  @override
  State<_DuaCard> createState() => _DuaCardState();
}

class _DuaCardState extends State<_DuaCard> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final saved = await _favoritesService.isFavorite(
      FavoriteType.dua,
      _favoriteId(),
    );
    if (!mounted) return;
    setState(() => _isFavorite = saved);
  }

  Future<void> _toggleFavorite() async {
    final saved = await _favoritesService.toggle(
      FavoriteItem(
        type: FavoriteType.dua,
        id: _favoriteId(),
        title: widget.item.arabic,
        subtitle: widget.item.source,
      ),
    );
    if (!mounted) return;
    setState(() => _isFavorite = saved);
  }

  String _favoriteId() {
    return widget.item.id.isNotEmpty ? widget.item.id : widget.item.arabic;
  }

  @override
  Widget build(BuildContext context) {
    const secondary = AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppUi.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.item.arabic,
                  style:
                      AppText.athkarBody.copyWith(color: AppColors.textPrimary),
                ),
              ),
              IconButton(
                tooltip: 'المفضلة',
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorite ? Icons.star : Icons.star_border,
                  color: _isFavorite
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (widget.item.transliteration.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.item.transliteration,
              style: AppText.body.copyWith(color: secondary),
            ),
          ],
          if (widget.item.meaning.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.item.meaning,
              style: AppText.body.copyWith(color: secondary),
            ),
          ],
        ],
      ),
    );
  }
}
