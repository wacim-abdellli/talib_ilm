import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_palette.dart';
import '../../../core/models/favorite_item.dart';
import '../../../core/services/favorites_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/primary_app_bar.dart';
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
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: const PrimaryAppBar(
        title: AppStrings.duasTitle,
        showBack: true,
      ),
      body: _loading
          ? const Center(child: AppLoadingIndicator())
          : Column(
              children: [
                // Top Search Bar
                Container(
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: palette.border,
                        width: 1,
                      ),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: context.text.body.copyWith(
                      color: palette.text,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث في الأدعية والمأثورات...',
                      hintStyle: context.text.bodySmall.copyWith(
                        color: palette.textMuted,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: palette.primary,
                        size: AppIcon.md,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: AppIcon.sm),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: palette.surfaceMuted,
                      contentPadding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.lg,
                        vertical: AppSpace.sm,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.mdRadius,
                        borderSide: BorderSide(color: palette.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.mdRadius,
                        borderSide: BorderSide(color: palette.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.mdRadius,
                        borderSide: BorderSide(
                          color: palette.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                // Duas List
                Expanded(
                  child: _filteredItems.isEmpty
                      ? AppEmptyState(
                          icon: Icons.menu_book_outlined,
                          title: _searchQuery.isEmpty
                              ? AppStrings.duasEmptyTitle
                              : 'لا توجد نتائج',
                          subtitle: _searchQuery.isEmpty
                              ? AppStrings.duasEmptyMessage
                              : 'لم نعثر على أدعية مطابقة لبحثك',
                          action: AppButton(
                            label: _searchQuery.isEmpty
                                ? AppStrings.actionBack
                                : 'مسح البحث',
                            onPressed: () {
                              if (_searchQuery.isNotEmpty) {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              } else {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsetsDirectional.fromSTEB(
                            AppSpace.lg,
                            AppSpace.lg,
                            AppSpace.lg,
                            AppSize.navClearance(context),
                          ),
                          itemCount: _filteredItems.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpace.md),
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
      subtitle: widget.item.source.isNotEmpty
          ? widget.item.source
          : widget.item.meaning,
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

  void _share() {
    HapticFeedback.lightImpact();
    final text = StringBuffer()..writeln(widget.item.arabic);
    if (widget.item.meaning.isNotEmpty) {
      text.writeln('\n${widget.item.meaning}');
    }
    if (widget.item.source.isNotEmpty) {
      text.writeln('\n— ${widget.item.source}');
    }
    text.writeln('\n(من تطبيق طالب العلم)');
    Share.share(text.toString());
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AppCard(
      padding: EdgeInsetsDirectional.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with number badge and source
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpace.lg,
              AppSpace.md,
              AppSpace.lg,
              AppSpace.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: palette.goldSoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: palette.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index}',
                      style: context.text.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.gold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                if (widget.item.source.isNotEmpty)
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: palette.primarySoft,
                      borderRadius: AppRadius.smRadius,
                    ),
                    child: Text(
                      widget.item.source,
                      style: context.text.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.onPrimarySoft,
                      ),
                    ),
                  ),
                const Spacer(),
                // Actions
                AppIconButton(
                  icon: Icons.copy_rounded,
                  tooltip: 'نسخ الدعاء',
                  onPressed: _copy,
                ),
                AppIconButton(
                  icon: Icons.share_rounded,
                  tooltip: 'مشاركة الدعاء',
                  onPressed: _share,
                ),
                AppIconButton(
                  icon: _isFavorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  tooltip: _isFavorite ? 'في المفضلة' : 'إضافة للمفضلة',
                  color: _isFavorite ? palette.gold : null,
                  onPressed: _toggleFav,
                ),
              ],
            ),
          ),

          // Arabic Dua Content
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpace.xl,
              AppSpace.xs,
              AppSpace.xl,
              AppSpace.md,
            ),
            child: Text(
              widget.item.arabic,
              textAlign: TextAlign.right,
              style: context.text.sacred.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w700,
                height: 1.7,
              ),
            ),
          ),

          // Meaning & Fadl
          if (widget.item.meaning.isNotEmpty || widget.item.fadl.isNotEmpty) ...[
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpace.lg,
                AppSpace.md,
                AppSpace.lg,
                AppSpace.md,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.item.meaning.isNotEmpty)
                    Text(
                      widget.item.meaning,
                      style: context.text.bodySmall.copyWith(
                        color: palette.textMuted,
                        height: 1.5,
                      ),
                    ),
                  if (widget.item.fadl.isNotEmpty) ...[
                    if (widget.item.meaning.isNotEmpty)
                      const SizedBox(height: AppSpace.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          size: AppIcon.sm,
                          color: palette.gold,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Expanded(
                          child: Text(
                            widget.item.fadl,
                            style: context.text.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: palette.gold,
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
