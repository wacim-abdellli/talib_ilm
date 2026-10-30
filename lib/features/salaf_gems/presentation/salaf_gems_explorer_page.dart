import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/islamic_typography_sheet.dart';
import '../data/models/salaf_filter_models.dart';
import '../data/models/salaf_gem.dart';
import '../data/repositories/salaf_gems_repository.dart';
import 'widgets/salaf_author_filter_sheet.dart';
import 'widgets/salaf_filter_capsule_bar.dart';
import 'widgets/salaf_gem_card.dart';
import 'widgets/salaf_gem_share_sheet.dart';
import 'widgets/salaf_quick_jump_sheet.dart';
import 'widgets/salaf_topic_filter_sheet.dart';

class SalafGemsExplorerPage extends StatefulWidget {
  final String? pageTitle;
  final String? initialCategory;
  final String? initialAuthor;
  final String? initialTopic;

  const SalafGemsExplorerPage({
    super.key,
    this.pageTitle,
    this.initialCategory,
    this.initialAuthor,
    this.initialTopic,
  });

  @override
  State<SalafGemsExplorerPage> createState() => _SalafGemsExplorerPageState();
}

class _SalafGemsExplorerPageState extends State<SalafGemsExplorerPage> {
  final SalafGemsRepository _repository = SalafGemsRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<SalafGem> _allGems = const [];
  List<SalafGem> _filteredGems = const [];
  List<String> _categories = const ['الكل'];
  Set<String> _favoriteIds = const {};

  SalafScholarItem _selectedScholar = SalafFilterData.scholars.first;
  SalafTopicItem _selectedTopic = SalafFilterData.topics.first;
  Map<String, int> _scholarCounts = const {};
  Map<String, int> _topicCounts = const {};

  String _selectedCategory = 'الكل';
  bool _onlyFavorites = false;
  bool _isLoading = true;
  bool _showBackToTop = false;
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    IslamicTypographySheet.loadSavedScale(IslamicTypographySheet.durarPrefKey).then((s) {
      if (mounted) setState(() => _fontScale = s);
    });
    _selectedCategory = widget.initialCategory ?? 'الكل';
    if (widget.initialCategory == null && widget.pageTitle != null) {
      final title = widget.pageTitle!;
      if (title.contains('معاصر') || title.contains('الدعاة')) {
        _selectedCategory = 'درر الدعاة المعاصرين';
      } else if (title.contains('ابن تيمية')) {
        _selectedCategory = 'فوائد من كتب ابن تيمية';
      } else if (title.contains('ابن القيم')) {
        _selectedCategory = 'فوائد من كتب ابن القيم';
      } else if (title.contains('تدبر') || title.contains('قرآن')) {
        _selectedCategory = 'خواطر قرآنية ووقفات تدبرية';
      }
    }
    if (widget.initialAuthor != null) {
      final match = SalafFilterData.scholars.firstWhere(
        (s) =>
            s.displayName.contains(widget.initialAuthor!) ||
            s.queryKeyword.contains(widget.initialAuthor!),
        orElse: () => SalafFilterData.scholars.first,
      );
      _selectedScholar = match;
    }
    if (widget.initialTopic != null) {
      final match = SalafFilterData.topics.firstWhere(
        (t) =>
            t.title.contains(widget.initialTopic!) ||
            t.matchKeywords.any((kw) => kw.contains(widget.initialTopic!)),
        orElse: () => SalafFilterData.topics.first,
      );
      _selectedTopic = match;
    }
    _loadData();
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 400;
    if (shouldShow != _showBackToTop && mounted) {
      setState(() => _showBackToTop = shouldShow);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _jumpToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _jumpToIndex(int index) {
    if (!_scrollController.hasClients || _filteredGems.isEmpty) return;
    final clamped = index.clamp(0, _filteredGems.length - 1);
    final targetOffset = (clamped * 190.0).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      targetOffset,
      duration: AppMotion.base,
      curve: Curves.easeOutCubic,
    );
  }

  void _jumpToRandom() {
    if (_filteredGems.isEmpty) return;
    final randIndex = Random().nextInt(_filteredGems.length);
    _jumpToIndex(randIndex);
    HapticFeedback.lightImpact();
    AppSnackbar.info(
      context,
      'انتقلت إلى الدُّرّة رقم ${randIndex + 1} (${_filteredGems[randIndex].author})',
      hasNavBar: false,
    );
  }

  void _openQuickJumpSheet() {
    HapticFeedback.lightImpact();
    SalafQuickJumpSheet.show(
      context: context,
      totalCount: _filteredGems.length,
      gems: _filteredGems,
      onJumpToIndex: _jumpToIndex,
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final gems = await _repository.getAllGems();
    final categories = await _repository.getAllCategories();
    final favs = await _repository.getFavoriteIds();
    final scholarCounts = await _repository.getScholarCounts();
    final topicCounts = await _repository.getTopicCounts();

    if (!mounted) return;
    setState(() {
      _allGems = gems;
      _categories = categories;
      _favoriteIds = favs;
      _scholarCounts = scholarCounts;
      _topicCounts = topicCounts;
      _isLoading = false;
    });
    _applyFilters(resetScroll: false);
  }

  Future<void> _applyFilters({bool resetScroll = true}) async {
    final query = _searchController.text.trim();
    final results = await _repository.filterGems(
      query: query.isEmpty ? null : query,
      category: _selectedCategory,
      scholarQuery: _selectedScholar.id == 'all' ? null : _selectedScholar.queryKeyword,
      topic: _selectedTopic,
      onlyFavorites: _onlyFavorites,
    );

    if (!mounted) return;
    setState(() {
      _filteredGems = results;
    });
    if (resetScroll) {
      _jumpToTop();
    }
  }

  bool get _hasActiveFilters =>
      _selectedCategory != 'الكل' ||
      _selectedScholar.id != 'all' ||
      _selectedTopic.id != 'all' ||
      _onlyFavorites ||
      _searchController.text.isNotEmpty;

  void _resetAllFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCategory = 'الكل';
      _selectedScholar = SalafFilterData.scholars.first;
      _selectedTopic = SalafFilterData.topics.first;
      _onlyFavorites = false;
      _searchController.clear();
    });
    _applyFilters(resetScroll: true);
  }

  String _buildDynamicSubtitle() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      return 'عُثِرَ عَلَى ${_filteredGems.length} نَتِيجَةً لِلْبَحْثِ';
    }
    if (_onlyFavorites) {
      return 'المُفَضَّلَةُ • ${_filteredGems.length} دُرَّةٍ مَحْفُوظَة';
    }
    if (_selectedScholar.id != 'all') {
      return '${_selectedScholar.displayName} • ${_filteredGems.length} دُرَّة';
    }
    if (_selectedTopic.id != 'all') {
      return '${_selectedTopic.title} • ${_filteredGems.length} دُرَّة';
    }
    if (_selectedCategory != 'الكل') {
      return '$_selectedCategory • ${_filteredGems.length} دُرَّة';
    }
    return '${_allGems.length} دُرَّةً وَأَثَرًا مُوَثَّقًا';
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
      _applyFilters(resetScroll: false);
    }
  }

  void _copyGem(SalafGem gem) {
    Clipboard.setData(ClipboardData(text: gem.shareableText));
    AppSnackbar.success(
      context,
      'تم نسخ الأثر والمصدر إلى الحافظة بنجاح',
      hasNavBar: false,
    );
  }

  void _openScholarPicker() {
    HapticFeedback.lightImpact();
    SalafAuthorFilterSheet.show(
      context: context,
      scholars: SalafFilterData.scholars,
      counts: _scholarCounts,
      selectedScholar: _selectedScholar,
      onSelectScholar: (scholar) {
        setState(() {
          _selectedScholar = scholar;
        });
        _applyFilters(resetScroll: true);
      },
    );
  }

  void _openTopicPicker() {
    HapticFeedback.lightImpact();
    SalafTopicFilterSheet.show(
      context: context,
      topics: SalafFilterData.topics,
      counts: _topicCounts,
      selectedTopic: _selectedTopic,
      onSelectTopic: (topic) {
        setState(() {
          _selectedTopic = topic;
        });
        _applyFilters(resetScroll: true);
      },
    );
  }

  void _openTypographySheet() {
    IslamicTypographySheet.show(
      context: context,
      currentScale: _fontScale,
      prefKey: IslamicTypographySheet.durarPrefKey,
      titleText: 'حجم خط درر السلف',
      onFontScaleChanged: (scale) => setState(() => _fontScale = scale),
      onReset: () => setState(() => _fontScale = 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: palette.bg,
      floatingActionButton: _showBackToTop
          ? FloatingActionButton.small(
              heroTag: 'durar_scroll_to_top',
              backgroundColor: palette.surfaceRaised,
              foregroundColor: palette.gold,
              tooltip: 'العودة للأعلى',
              onPressed: () {
                HapticFeedback.lightImpact();
                _scrollController.animateTo(
                  0,
                  duration: AppMotion.base,
                  curve: Curves.easeOutCubic,
                );
              },
              child: const Icon(Icons.arrow_upward_rounded),
            )
          : null,
      appBar: AppBar(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                widget.pageTitle ?? 'موسوعة درر السلف والآثار',
                style: textTheme.title.copyWith(
                  color: palette.text,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
              ),
            ),
            Text(
              _buildDynamicSubtitle(),
              style: textTheme.caption.copyWith(
                color: palette.gold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'حجم الخط وتنسيق النص',
            icon: Icon(
              Icons.format_size_rounded,
              color: palette.gold,
              size: AppIcon.md,
            ),
            onPressed: _openTypographySheet,
          ),
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
              _applyFilters(resetScroll: true);
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
                // Modern Capsule Search Header with tap outside unfocus
                Container(
                  color: palette.surface,
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpace.md, AppSpace.xs, AppSpace.md, AppSpace.xs,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.surfaceRaised,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(color: palette.border),
                    ),
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.sm),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: palette.primary),
                        const SizedBox(width: AppSpace.xs),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                            onChanged: (_) => _applyFilters(resetScroll: true),
                            style: textTheme.body.copyWith(color: palette.text),
                            decoration: InputDecoration(
                              hintText: 'ابحث في نصوص الأحاديث وأقوال الصحابة والسلف...',
                              hintStyle: textTheme.body.copyWith(color: palette.textSubtle),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.sm),
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear_rounded, color: palette.textMuted),
                            tooltip: 'مسح البحث',
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters(resetScroll: true);
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                // UNIFIED SINGLE-LINE FILTER BAR (Scholar Pill + Topic Pill + Category Chips)
                SalafFilterCapsuleBar(
                  selectedScholar: _selectedScholar,
                  selectedTopic: _selectedTopic,
                  categories: _categories,
                  selectedCategory: _selectedCategory,
                  onOpenScholarPicker: _openScholarPicker,
                  onOpenTopicPicker: _openTopicPicker,
                  onClearScholar: () {
                    setState(() => _selectedScholar = SalafFilterData.scholars.first);
                    _applyFilters(resetScroll: true);
                  },
                  onClearTopic: () {
                    setState(() => _selectedTopic = SalafFilterData.topics.first);
                    _applyFilters(resetScroll: true);
                  },
                  onSelectCategory: (cat) {
                    final isSelected = _selectedCategory == cat;
                    setState(() => _selectedCategory = isSelected && cat != 'الكل' ? 'الكل' : cat);
                    _applyFilters(resetScroll: true);
                  },
                ),

                // Results Count & Large Collection Navigation Bar
                Container(
                  color: palette.surfaceMuted,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.xs,
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'عُثِرَ عَلَى ${_filteredGems.length} دُرَّةٍ وَأَثَر',
                          style: textTheme.caption.copyWith(
                            color: palette.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),

                      // Fast Jump action for collections > 15
                      if (_filteredGems.length > 15) ...[
                        InkWell(
                          onTap: _openQuickJumpSheet,
                          borderRadius: AppRadius.pillRadius,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.xs,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions_run_rounded,
                                  size: AppIcon.xs,
                                  color: palette.gold,
                                ),
                                const SizedBox(width: AppSpace.xxs),
                                Text(
                                  'انتقال سريع',
                                  style: textTheme.caption.copyWith(
                                    color: palette.gold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        InkWell(
                          onTap: _jumpToRandom,
                          borderRadius: AppRadius.pillRadius,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.xs,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.casino_outlined,
                                  size: AppIcon.xs,
                                  color: palette.primary,
                                ),
                                const SizedBox(width: AppSpace.xxs),
                                Text(
                                  'عشوائي',
                                  style: textTheme.caption.copyWith(
                                    color: palette.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                      ],

                      // Reset Filters Button
                      if (_hasActiveFilters)
                        InkWell(
                          onTap: _resetAllFilters,
                          child: Text(
                            'إعادة ضبط',
                            style: textTheme.caption.copyWith(
                              color: palette.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // List of Gems with ScrollController
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
                                    : 'لم يتم العثور على نتائج مطابقة للبحث',
                                style: textTheme.body.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsetsDirectional.all(AppSpace.md),
                          itemCount: _filteredGems.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpace.md),
                          itemBuilder: (ctx, i) {
                            final gem = _filteredGems[i];
                            final isFav = _favoriteIds.contains(gem.id);
                            return SalafGemCard(
                              gem: gem,
                              fontScale: _fontScale,
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
