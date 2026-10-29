import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/islamic_typography_sheet.dart';
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
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    IslamicTypographySheet.loadSavedScale(IslamicTypographySheet.hadithPrefKey).then((s) {
      if (mounted) setState(() => _fontScale = s);
    });
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

  void _openCollectionPicker() {
    HapticFeedback.lightImpact();
    final palette = context.palette;
    final textTheme = context.text;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom Sheet Header
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpace.lg,
                  AppSpace.md,
                  AppSpace.sm,
                  AppSpace.xs,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        'اختر كتاب الحديث أو المجموعة',
                        style: textTheme.titleSmall.copyWith(
                          color: palette.text,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: palette.textMuted,
                      tooltip: 'إغلاق',
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Collection List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  itemCount: _collections.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpace.xs),
                  itemBuilder: (context, index) {
                    final col = _collections[index];
                    final isSelected = col == _selectedCollection;
                    final isAll = col == 'الكل';

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: AppRadius.mdRadius,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _onCollectionSelected(col);
                          Navigator.of(ctx).pop();
                        },
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.md,
                            vertical: AppSpace.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? palette.primarySoft
                                : palette.surfaceRaised,
                            borderRadius: AppRadius.mdRadius,
                            border: Border.all(
                              color: isSelected
                                  ? palette.primary
                                  : palette.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isAll
                                    ? Icons.all_inclusive_rounded
                                    : Icons.menu_book_rounded,
                                color: isSelected
                                    ? palette.primary
                                    : palette.textMuted,
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Expanded(
                                child: Text(
                                  isAll
                                      ? 'الكل (جميع الصحاح والسنن والمصادر)'
                                      : col,
                                  style: textTheme.body.copyWith(
                                    color: isSelected
                                        ? palette.primary
                                        : palette.text,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: palette.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openTypographySheet() {
    IslamicTypographySheet.show(
      context: context,
      currentScale: _fontScale,
      prefKey: IslamicTypographySheet.hadithPrefKey,
      titleText: 'حجم خط الأحاديث النبوية',
      onFontScaleChanged: (scale) => setState(() => _fontScale = scale),
      onReset: () => setState(() => _fontScale = 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasCollectionFilter = _selectedCollection != 'الكل';

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

                // UNIFIED SINGLE-LINE FILTER BAR (Book Collection Dropdown + Category Pills)
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
                      // Book / Collection Picker Capsule Pill
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: AppRadius.pillRadius,
                          onTap: _openCollectionPicker,
                          child: Container(
                            alignment: AlignmentDirectional.center,
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.md,
                              vertical: AppSpace.xs,
                            ),
                            decoration: BoxDecoration(
                              color: hasCollectionFilter
                                  ? palette.primarySoft
                                  : palette.surfaceRaised,
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(
                                color: hasCollectionFilter
                                    ? palette.primary
                                    : palette.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: AppIcon.sm,
                                  color: hasCollectionFilter
                                      ? palette.primary
                                      : palette.textMuted,
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Text(
                                  _selectedCollection == 'الكل'
                                      ? 'المصدر: الكل ▾'
                                      : '$_selectedCollection ▾',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: hasCollectionFilter
                                        ? palette.primary
                                        : palette.text,
                                    fontFamily: AppTextStyles.cairo,
                                    fontWeight: hasCollectionFilter
                                        ? AppFontWeight.bold
                                        : AppFontWeight.medium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),

                      // Category Pills
                      ..._categories.map((cat) {
                        final isSelected = cat == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: AppSpace.xs,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: AppRadius.pillRadius,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _selectedCategory =
                                    isSelected && cat != 'الكل'
                                        ? 'الكل'
                                        : cat);
                                _applyFilter();
                              },
                              child: Container(
                                alignment: AlignmentDirectional.center,
                                padding:
                                    const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpace.md,
                                  vertical: AppSpace.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? palette.goldSoft
                                      : palette.surfaceRaised,
                                  borderRadius: AppRadius.pillRadius,
                                  border: Border.all(
                                    color: isSelected
                                        ? palette.gold
                                        : palette.border,
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isSelected
                                        ? palette.gold
                                        : palette.textMuted,
                                    fontFamily: AppTextStyles.cairo,
                                    fontWeight: isSelected
                                        ? AppFontWeight.bold
                                        : AppFontWeight.medium,
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
                              fontScale: _fontScale,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
