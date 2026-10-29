import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_spacing.dart';
import '../data/models/salaf_gem.dart';
import '../data/repositories/salaf_gems_repository.dart';
import 'widgets/salaf_gem_card.dart';
import 'widgets/salaf_gem_share_sheet.dart';

class SalafGemsExplorerPage extends StatefulWidget {
  final String? initialCategory;
  final String? initialAuthor;

  const SalafGemsExplorerPage({
    super.key,
    this.initialCategory,
    this.initialAuthor,
  });

  @override
  State<SalafGemsExplorerPage> createState() => _SalafGemsExplorerPageState();
}

class _SalafGemsExplorerPageState extends State<SalafGemsExplorerPage> {
  final SalafGemsRepository _repository = SalafGemsRepository.instance;
  final TextEditingController _searchController = TextEditingController();

  List<SalafGem> _allGems = const [];
  List<SalafGem> _filteredGems = const [];
  List<String> _categories = const ['الكل'];
  List<String> _topAuthors = const ['الكل'];
  Set<String> _favoriteIds = const {};

  String _selectedCategory = 'الكل';
  String _selectedAuthor = 'الكل';
  bool _onlyFavorites = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'الكل';
    _selectedAuthor = widget.initialAuthor ?? 'الكل';
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final gems = await _repository.getAllGems();
    final categories = await _repository.getAllCategories();
    final authors = await _repository.getTopAuthors();
    final favs = await _repository.getFavoriteIds();

    if (!mounted) return;
    setState(() {
      _allGems = gems;
      _categories = categories;
      _topAuthors = authors;
      _favoriteIds = favs;
      _isLoading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    final results = _allGems.where((gem) {
      if (_onlyFavorites && !_favoriteIds.contains(gem.id)) {
        return false;
      }
      if (_selectedCategory != 'الكل' && gem.category != _selectedCategory) {
        return false;
      }
      if (_selectedAuthor != 'الكل' && !gem.author.contains(_selectedAuthor)) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesText = gem.text.toLowerCase().contains(query);
        final matchesAuthor = gem.author.toLowerCase().contains(query);
        final matchesTopic = gem.topic.toLowerCase().contains(query);
        final matchesRef = gem.sourceRef.toLowerCase().contains(query);
        if (!matchesText && !matchesAuthor && !matchesTopic && !matchesRef) {
          return false;
        }
      }
      return true;
    }).toList();

    setState(() {
      _filteredGems = results;
    });
  }

  Future<void> _toggleFavorite(SalafGem gem) async {
    HapticFeedback.lightImpact();
    final isFav = await _repository.toggleFavorite(gem.id);
    final updated = Set<String>.from(_favoriteIds);
    if (isFav) {
      updated.add(gem.id);
    } else {
      updated.remove(gem.id);
    }
    setState(() {
      _favoriteIds = updated;
    });
    if (_onlyFavorites) {
      _applyFilters();
    }
  }

  void _copyGem(SalafGem gem) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: gem.shareableText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ الأثر والمصدر إلى الحافظة',
          style: context.text.body.copyWith(
            color: context.palette.onPrimary,
          ),
        ),
        backgroundColor: context.palette.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getScholarInitial(String author) {
    final clean = author
        .replaceAll('قال', '')
        .replaceAll('بن', ' ')
        .replaceAll('أبي', ' ')
        .replaceAll('ابن', ' ')
        .replaceAll('رحمه الله', '')
        .replaceAll('رضي الله عنه', '')
        .trim();
    if (clean.isEmpty) return 'س';
    return clean.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'موسوعة درر السلف والآثار',
              style: textTheme.title.copyWith(
                color: palette.text,
              ),
            ),
            Text(
              '${_allGems.length} درة وأثر مسند وموثق',
              style: textTheme.caption.copyWith(
                color: palette.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _onlyFavorites ? 'عرض الكل' : 'المفضلة فقط',
            icon: Icon(
              _onlyFavorites ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _onlyFavorites ? palette.gold : palette.textMuted,
            ),
            onPressed: () {
              setState(() {
                _onlyFavorites = !_onlyFavorites;
              });
              _applyFilters();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: palette.primary,
              ),
            )
          : Column(
              children: [
                // Modern Capsule Search Header
                Container(
                  color: palette.surface,
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpace.md,
                    AppSpace.xs,
                    AppSpace.md,
                    AppSpace.xs,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.surfaceRaised,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: palette.border,
                      ),
                    ),
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: palette.primary,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => _applyFilters(),
                            style: textTheme.body.copyWith(
                              color: palette.text,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ابحث في نصوص الأحاديث وأقوال الصحابة والسلف...',
                              hintStyle: textTheme.body.copyWith(
                                color: palette.textSubtle,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsetsDirectional.symmetric(
                                vertical: AppSpace.sm,
                              ),
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: palette.textMuted,
                            ),
                            tooltip: 'مسح البحث',
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                // Category Selector Pill Row
                Container(
                  color: palette.surface,
                  padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.xs),
                  height: AppSize.tap,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md),
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: AppSpace.xs),
                    itemBuilder: (ctx, i) {
                      final cat = _categories[i];
                      final isSelected = _selectedCategory == cat;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: AppRadius.pillRadius,
                          onTap: () {
                            setState(() {
                              _selectedCategory = isSelected && cat != 'الكل' ? 'الكل' : cat;
                            });
                            _applyFilters();
                          },
                          child: Container(
                            alignment: AlignmentDirectional.center,
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.md,
                              vertical: AppSpace.xs,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? palette.primarySoft : palette.surfaceRaised,
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(
                                color: isSelected ? palette.primary : palette.border,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: textTheme.label.copyWith(
                                color: isSelected ? palette.primary : palette.textMuted,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Scholar / Author Monogram Bar
                Container(
                  color: palette.surface,
                  padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
                  height: AppSize.tap,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md),
                    itemCount: _topAuthors.length,
                    separatorBuilder: (context, index) => const SizedBox(width: AppSpace.xs),
                    itemBuilder: (ctx, i) {
                      final auth = _topAuthors[i];
                      final isSelected = _selectedAuthor == auth;
                      final isAll = auth == 'الكل';
                      final initial = isAll ? '✦' : _getScholarInitial(auth);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: AppRadius.pillRadius,
                          onTap: () {
                            setState(() {
                              _selectedAuthor = isSelected && !isAll ? 'الكل' : auth;
                            });
                            _applyFilters();
                          },
                          child: Container(
                            alignment: AlignmentDirectional.center,
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.sm,
                              vertical: AppSpace.xs,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? palette.goldSoft : palette.surfaceRaised,
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(
                                color: isSelected ? palette.gold : palette.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: AppSpace.xl,
                                  height: AppSpace.xl,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? palette.gold : palette.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? palette.gold : palette.border,
                                    ),
                                  ),
                                  child: Text(
                                    initial,
                                    style: textTheme.caption.copyWith(
                                      color: isSelected ? palette.onGold : palette.textMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Text(
                                  auth,
                                  style: textTheme.caption.copyWith(
                                    color: isSelected ? palette.gold : palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Results Count Strip
                Container(
                  color: palette.surfaceMuted,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.xs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'نتائج البحث: ${_filteredGems.length} درة',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      if (_selectedCategory != 'الكل' || _selectedAuthor != 'الكل' || _onlyFavorites)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'الكل';
                              _selectedAuthor = 'الكل';
                              _onlyFavorites = false;
                              _searchController.clear();
                            });
                            _applyFilters();
                          },
                          child: Text(
                            'إعادة ضبط المرشحات',
                            style: textTheme.caption.copyWith(
                              color: palette.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // List of Gems
                Expanded(
                  child: _filteredGems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                color: palette.textSubtle,
                              ),
                              const SizedBox(height: AppSpace.sm),
                              Text(
                                _onlyFavorites
                                    ? 'لا توجد آثار محفوظة في المفضلة'
                                    : 'لم يتم العثور على نتائج للبحث',
                                style: textTheme.body.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsetsDirectional.all(AppSpace.md),
                          itemCount: _filteredGems.length,
                          separatorBuilder: (context, index) => const SizedBox(height: AppSpace.md),
                          itemBuilder: (ctx, i) {
                            final gem = _filteredGems[i];
                            final isFav = _favoriteIds.contains(gem.id);
                            return SalafGemCard(
                              gem: gem,
                              isFavorite: isFav,
                              onToggleFavorite: () => _toggleFavorite(gem),
                              onCopy: () => _copyGem(gem),
                              onShare: () => SalafGemShareSheet.show(context, gem),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
