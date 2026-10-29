import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_ui.dart';
import 'package:talib_ilm/shared/widgets/app_back_button.dart';
import '../widgets/hadith_card.dart';
import '../../data/models/hadith_models.dart';
import '../../data/services/hadith_service.dart';

class HadithExplorerPage extends StatefulWidget {
  final String? initialCategory;
  final String? initialSearchQuery;

  const HadithExplorerPage({
    super.key,
    this.initialCategory,
    this.initialSearchQuery,
  });

  @override
  State<HadithExplorerPage> createState() => _HadithExplorerPageState();
}

class _HadithExplorerPageState extends State<HadithExplorerPage> {
  final HadithService _hadithService = HadithService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<GradedHadith> _allHadiths = [];
  List<GradedHadith> _filteredHadiths = [];
  List<String> _collections = ['الكل'];
  String _selectedCollection = 'الكل';
  List<String> _categories = ['الكل'];
  String _selectedCategory = 'الكل';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
    }
    _loadHadiths();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHadiths() async {
    final hadiths = await _hadithService.getAllHadiths();
    final collections = await _hadithService.getCollections();
    final categories = await _hadithService.getCategories();

    if (!mounted) return;

    setState(() {
      _allHadiths = hadiths;
      _collections = collections;
      _categories = ['الكل', ...categories];
      if (widget.initialCategory != null &&
          _categories.contains(widget.initialCategory)) {
        _selectedCategory = widget.initialCategory!;
      }
      _applyFilter();
      _isLoading = false;
    });
  }

  Future<void> _onCollectionSelected(String col) async {
    _selectedCollection = col;
    final cats = await _hadithService.getCategories(col);
    if (!mounted) return;
    setState(() {
      _categories = ['الكل', ...cats];
      _selectedCategory = 'الكل';
      _applyFilter();
    });
  }

  void _applyFilter() {
    final query = _searchController.text.trim();
    List<GradedHadith> list = _allHadiths;

    if (_selectedCollection != 'الكل') {
      list = _hadithService.filterByCollection(list, _selectedCollection);
    }

    if (_selectedCategory != 'الكل') {
      list = list.where((h) => h.category == _selectedCategory).toList();
    }

    if (query.isNotEmpty) {
      final clean = HadithService.normalizeArabic(query);
      list = list.where((h) {
        if (h.searchIndex != null) {
          return h.searchIndex!.contains(clean);
        }
        return HadithService.normalizeArabic(h.title).contains(clean) ||
            HadithService.normalizeArabic(h.matn).contains(clean) ||
            HadithService.normalizeArabic(h.narrator).contains(clean) ||
            HadithService.normalizeArabic(h.benefits).contains(clean);
      }).toList();
    }

    setState(() {
      _filteredHadiths = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الأحاديث النبوية الصحيحة',
              style: AppTextStyles.titleMedium.copyWith(
                color: palette.text,
                fontFamily: AppTextStyles.cairo,
              ),
            ),
            if (!_isLoading)
              Text(
                '${_filteredHadiths.length} حديثاً صحيحاً ومسنداً',
                style: AppTextStyles.caption.copyWith(
                  color: palette.textMuted,
                  fontFamily: AppTextStyles.cairo,
                ),
              ),
          ],
        ),
        leading: const AppBackButton(),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: palette.primary,
              ),
            )
          : Column(
              children: [
                // Modern Capsule Search Bar
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
                      border: Border.all(color: palette.border),
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
                            onChanged: (_) {
                              _searchDebounce?.cancel();
                              _searchDebounce = Timer(AppMotion.searchDebounce, _applyFilter);
                            },
                            decoration: InputDecoration(
                              hintText: 'ابحث في الأحاديث، الرواة، أو الفوائد...',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: palette.textSubtle,
                                fontFamily: AppTextStyles.cairo,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsetsDirectional.symmetric(
                                vertical: AppSpace.sm,
                              ),
                            ),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: palette.text,
                              fontFamily: AppTextStyles.cairo,
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
                              _applyFilter();
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                // Canonical Collections Sleek Pills
                if (_collections.length > 2) ...[
                  Container(
                    color: palette.surface,
                    padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.xs),
                    height: AppSize.tap,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.md,
                      ),
                      itemCount: _collections.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: AppSpace.xs),
                      itemBuilder: (context, index) {
                        final col = _collections[index];
                        final isSelected = col == _selectedCollection;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: AppRadius.pillRadius,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _onCollectionSelected(col);
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
                                col,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isSelected
                                      ? palette.primary
                                      : palette.textMuted,
                                  fontFamily: AppTextStyles.cairo,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Chapter / Category Sleek Pills
                Container(
                  color: palette.surface,
                  padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
                  height: AppSize.tap,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                    ),
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: AppSpace.xs),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = cat == _selectedCategory;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: AppRadius.pillRadius,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _selectedCategory = isSelected && cat != 'الكل' ? 'الكل' : cat);
                            _applyFilter();
                          },
                          child: Container(
                            alignment: AlignmentDirectional.center,
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.md,
                              vertical: AppSpace.xs,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? palette.goldSoft : palette.surfaceRaised,
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(
                                color: isSelected ? palette.gold : palette.border,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isSelected
                                    ? palette.gold
                                    : palette.textMuted,
                                fontFamily: AppTextStyles.cairo,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
                        'نتائج البحث: ${_filteredHadiths.length} حديثاً',
                        style: AppTextStyles.caption.copyWith(
                          color: palette.textMuted,
                          fontFamily: AppTextStyles.cairo,
                        ),
                      ),
                      if (_selectedCollection != 'الكل' || _selectedCategory != 'الكل' || _searchController.text.isNotEmpty)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCollection = 'الكل';
                              _selectedCategory = 'الكل';
                              _searchController.clear();
                            });
                            _applyFilter();
                          },
                          child: Text(
                            'إعادة ضبط المرشحات',
                            style: AppTextStyles.caption.copyWith(
                              color: palette.primary,
                              fontFamily: AppTextStyles.cairo,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Hadith List
                Expanded(
                  child: _filteredHadiths.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.xl,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  color: palette.textSubtle,
                                ),
                                const SizedBox(height: AppSpace.sm),
                                Text(
                                  'لم يتم العثور على أحاديث مطابقة في المجموعة المحلية',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: palette.textMuted,
                                    fontFamily: AppTextStyles.cairo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsetsDirectional.all(AppSpace.md),
                          itemCount: _filteredHadiths.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpace.md),
                          itemBuilder: (context, index) {
                            return HadithCard(
                              hadith: _filteredHadiths[index],
                              initiallyExpanded: false,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
