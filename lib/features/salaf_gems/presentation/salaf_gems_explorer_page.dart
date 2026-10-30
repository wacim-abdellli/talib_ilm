import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/islamic_typography_sheet.dart';
import '../data/models/encyclopedia_section.dart';
import '../data/models/salaf_gem.dart';
import '../data/repositories/salaf_gems_repository.dart';
import 'widgets/salaf_author_filter_sheet.dart';
import 'widgets/salaf_gem_card.dart';
import 'widgets/salaf_gem_share_sheet.dart';

class SalafGemsExplorerPage extends StatefulWidget {
  final String? pageTitle;
  final String? initialCategory;
  final String? initialAuthor;
  final String? initialSectionId;
  final String? initialTopic;

  const SalafGemsExplorerPage({
    super.key,
    this.pageTitle,
    this.initialCategory,
    this.initialAuthor,
    this.initialSectionId,
    this.initialTopic,
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
  EncyclopediaSection? _currentSection;

  String _selectedCategory = 'الكل';
  String _selectedAuthor = 'الكل';
  bool _onlyFavorites = false;
  bool _isLoading = true;
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    IslamicTypographySheet.loadSavedScale(IslamicTypographySheet.durarPrefKey).then((s) {
      if (mounted) setState(() => _fontScale = s);
    });
    if (widget.initialSectionId != null) {
      _currentSection = _repository.getSectionById(widget.initialSectionId!);
    }
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
    final sec = _currentSection;
    final results = _allGems.where((gem) {
      if (_onlyFavorites && !_favoriteIds.contains(gem.id)) {
        return false;
      }
      if (sec != null) {
        bool sectionMatch = false;
        if (sec.targetAuthor != null && gem.author.contains(sec.targetAuthor!)) {
          sectionMatch = true;
        } else if (sec.targetCategory != null && gem.category == sec.targetCategory) {
          sectionMatch = true;
        } else {
          for (final kw in sec.keywords) {
            if (gem.topic.contains(kw) ||
                gem.author.contains(kw) ||
                gem.sourceRef.contains(kw) ||
                gem.text.contains(kw)) {
              sectionMatch = true;
              break;
            }
          }
        }
        if (!sectionMatch) return false;
      }
      if (widget.initialTopic != null &&
          !gem.topic.contains(widget.initialTopic!) &&
          !gem.category.contains(widget.initialTopic!)) {
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
      authors: _topAuthors,
      selectedAuthor: _selectedAuthor,
      onSelectAuthor: (author) {
        setState(() {
          _selectedAuthor = author;
        });
        _applyFilters();
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
    final hasAuthorFilter = _selectedAuthor != 'الكل';

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
              widget.pageTitle ??
                  _currentSection?.title ??
                  'موسوعة درر السلف والآثار',
              style: textTheme.title.copyWith(
                color: palette.text,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${_allGems.length} أَثَرًا مُوَثَّقًا وَحِكْمَةً مُحَقَّقَة',
              style: textTheme.caption.copyWith(
                color: palette.gold,
              ),
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

                // UNIFIED SINGLE-LINE FILTER BAR (Scholar Dropdown + Category Pills)
                Container(
                  color: palette.surface,
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    0,
                    AppSpace.xxs,
                    0,
                    AppSpace.sm,
                  ),
                  height: AppSize.tap,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md),
                    children: [
                      // Scholar Picker Capsule Pill
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: AppRadius.pillRadius,
                          onTap: _openScholarPicker,
                          child: Container(
                            alignment: AlignmentDirectional.center,
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.sm,
                              vertical: AppSpace.xs,
                            ),
                            decoration: BoxDecoration(
                              color: hasAuthorFilter ? palette.goldSoft : palette.surfaceRaised,
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(
                                color: hasAuthorFilter ? palette.gold : palette.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  color: hasAuthorFilter ? palette.gold : palette.textMuted,
                                ),
                                const SizedBox(width: AppSpace.xxs),
                                Text(
                                  hasAuthorFilter ? _selectedAuthor : 'القائل ▾',
                                  style: textTheme.label.copyWith(
                                    color: hasAuthorFilter ? palette.gold : palette.textMuted,
                                  ),
                                ),
                                if (hasAuthorFilter) ...[
                                  const SizedBox(width: AppSpace.xxs),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedAuthor = 'الكل';
                                      });
                                      _applyFilters();
                                    },
                                    child: Icon(
                                      Icons.cancel_rounded,
                                      color: palette.gold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),

                      // Category Pills in the same single row
                      ..._categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(start: AppSpace.xs),
                          child: Material(
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
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Results Count Bar
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
                        'عُثِرَ عَلَى ${_filteredGems.length} دُرَّةٍ وَأَثَر',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      if (_selectedCategory != 'الكل' || _selectedAuthor != 'الكل' || _onlyFavorites || _searchController.text.isNotEmpty)
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
                                    : 'لم يتم العثور على نتائج مطابقة للبحث',
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
