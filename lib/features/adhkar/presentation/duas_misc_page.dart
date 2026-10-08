import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../core/models/favorite_item.dart';
import '../../../core/services/favorites_service.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../data/adhkar_models.dart';
import '../data/adhkar_service.dart';

class DuasMiscPage extends StatefulWidget {
  const DuasMiscPage({super.key});

  @override
  State<DuasMiscPage> createState() => _DuasMiscPageState();
}

class _DuasMiscPageState extends State<DuasMiscPage> {
  final AthkarService _service = AthkarService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<AthkarItem> _allItems = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDuas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDuas() async {
    final catalog = await _service.loadCatalog();
    if (!mounted) return;
    setState(() {
      _allItems = catalog.byId('duas')?.items ?? const [];
      _loading = false;
    });
  }

  List<AthkarItem> get _filteredItems {
    if (_searchQuery.trim().isEmpty) return _allItems;
    final query = _searchQuery.trim().toLowerCase();
    return _allItems.where((item) {
      return item.arabic.toLowerCase().contains(query) ||
          item.meaning.toLowerCase().contains(query) ||
          item.source.toLowerCase().contains(query) ||
          item.fadl.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: const UnifiedAppBar(
        title: AppStrings.duasTitle,
        showBack: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Search Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    border: Border(
                      bottom: BorderSide(
                        color: context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08),
                        width: 1,
                      ),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: context.textPrimaryColor,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث في الأدعية والمأثورات...',
                      hintStyle: TextStyle(
                        fontFamily: 'Cairo',
                        color: context.textTertiaryColor,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: context.goldColor,
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: context.surfaceContainer,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: context.outlineVariantColor.withValues(alpha: 0.5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: context.outlineVariantColor.withValues(alpha: 0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: context.goldColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // Duas List
                Expanded(
                  child: _filteredItems.isEmpty
                      ? EmptyState(
                          icon: Icons.menu_book_outlined,
                          title: _searchQuery.isEmpty ? AppStrings.duasEmptyTitle : 'لا توجد نتائج',
                          subtitle: _searchQuery.isEmpty
                              ? AppStrings.duasEmptyMessage
                              : 'لم نعثر على أدعية مطابقة لبحثك',
                          actionLabel: _searchQuery.isEmpty ? AppStrings.actionBack : 'مسح البحث',
                          onAction: () {
                            if (_searchQuery.isNotEmpty) {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: _filteredItems.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return _DuaCard(item: item, index: index + 1);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _DuaCard extends StatefulWidget {
  final AthkarItem item;
  final int index;

  const _DuaCard({required this.item, required this.index});

  @override
  State<_DuaCard> createState() => _DuaCardState();
}

class _DuaCardState extends State<_DuaCard> {
  final FavoritesService _favService = FavoritesService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFav();
  }

  String get _duaId => widget.item.id.isNotEmpty
      ? widget.item.id
      : widget.item.arabic.hashCode.toString();

  Future<void> _checkFav() async {
    final fav = await _favService.isFavorite(FavoriteType.dua, _duaId);
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFav() async {
    HapticFeedback.mediumImpact();
    final favItem = FavoriteItem(
      type: FavoriteType.dua,
      id: _duaId,
      title: widget.item.arabic,
      subtitle: widget.item.source.isNotEmpty ? widget.item.source : widget.item.meaning,
    );
    final nowFav = await _favService.toggle(favItem);
    if (mounted) {
      setState(() => _isFavorite = nowFav);
      if (nowFav) {
        AppSnackbar.success(context, 'تم حفظ الدعاء في المفضلة');
      } else {
        AppSnackbar.info(context, 'تمت إزالة الدعاء من المفضلة');
      }
    }
  }

  void _copy() {
    HapticFeedback.lightImpact();
    final text = StringBuffer()..writeln(widget.item.arabic);
    if (widget.item.meaning.isNotEmpty) {
      text.writeln('\n${widget.item.meaning}');
    }
    if (widget.item.source.isNotEmpty) {
      text.writeln('\n— ${widget.item.source}');
    }
    Clipboard.setData(ClipboardData(text: text.toString()));
    AppSnackbar.success(context, 'تم نسخ الدعاء إلى الحافظة');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.goldColor.withValues(alpha: isDark ? 0.25 : 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with number badge and source
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: context.goldColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.goldColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.goldColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (widget.item.source.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.item.source,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.primaryColor,
                      ),
                    ),
                  ),
                const Spacer(),
                // Actions
                IconButton(
                  tooltip: 'نسخ الدعاء',
                  icon: const Icon(Icons.copy_rounded, size: 19),
                  color: context.textSecondaryColor,
                  visualDensity: VisualDensity.compact,
                  onPressed: _copy,
                ),
                IconButton(
                  tooltip: _isFavorite ? 'في المفضلة' : 'إضافة للمفضلة',
                  icon: Icon(
                    _isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    size: 20,
                  ),
                  color: _isFavorite ? context.goldColor : context.textSecondaryColor,
                  visualDensity: VisualDensity.compact,
                  onPressed: _toggleFav,
                ),
              ],
            ),
          ),

          // Arabic Dua Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Text(
              widget.item.arabic,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
                height: 1.7,
              ),
            ),
          ),

          // Meaning & Fadl
          if (widget.item.meaning.isNotEmpty || widget.item.fadl.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: context.surfaceColor.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.item.meaning.isNotEmpty)
                    Text(
                      widget.item.meaning,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: context.textSecondaryColor,
                        height: 1.5,
                      ),
                    ),
                  if (widget.item.fadl.isNotEmpty) ...[
                    if (widget.item.meaning.isNotEmpty) const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          size: 15,
                          color: context.goldColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.item.fadl,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.goldColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
