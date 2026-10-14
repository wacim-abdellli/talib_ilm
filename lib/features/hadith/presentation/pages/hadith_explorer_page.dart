import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_ui.dart';
import 'package:talib_ilm/shared/widgets/app_back_button.dart';
import '../widgets/hadith_card.dart';
import '../../data/models/hadith_models.dart';
import '../../data/services/hadith_service.dart';

class HadithExplorerPage extends StatefulWidget {
  final String? initialCategory;

  const HadithExplorerPage({
    super.key,
    this.initialCategory,
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
      _collections = ['الكل', ...collections];
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
      list = list.where((h) => h.collection == _selectedCollection).toList();
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Input
                Padding(
                  padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(color: palette.border),
                    ),
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) {
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(AppMotion.searchDebounce, _applyFilter);
                      },
                      decoration: InputDecoration(
                        icon: Icon(
                          Icons.search_rounded,
                          color: palette.textMuted,
                        ),
                        hintText: 'ابحث في الأحاديث، الرواة، أو الفوائد...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: palette.textSubtle,
                          fontFamily: AppTextStyles.cairo,
                        ),
                        border: InputBorder.none,
                      ),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: palette.text,
                        fontFamily: AppTextStyles.cairo,
                      ),
                    ),
                  ),
                ),

                // Canonical Collections Chips
                if (_collections.length > 2) ...[
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.lg,
                      ),
                      itemCount: _collections.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: AppSpace.xs),
                      itemBuilder: (context, index) {
                        final col = _collections[index];
                        final isSelected = col == _selectedCollection;
                        return ChoiceChip(
                          label: Text(
                            col,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isSelected
                                  ? palette.onPrimary
                                  : palette.text,
                              fontFamily: AppTextStyles.cairo,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: palette.primary,
                          backgroundColor: palette.surfaceRaised,
                          side: BorderSide(
                            color: isSelected
                                ? palette.primary
                                : palette.border,
                          ),
                          onSelected: (val) {
                            if (val) _onCollectionSelected(col);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                ],

                // Chapter / Category Chips
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.lg,
                    ),
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: AppSpace.xs),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = cat == _selectedCategory;
                      return ChoiceChip(
                        label: Text(
                          cat,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected
                                ? palette.onPrimary
                                : palette.textMuted,
                            fontFamily: AppTextStyles.cairo,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: palette.gold,
                        backgroundColor: palette.surface,
                        side: BorderSide(
                          color: isSelected
                              ? palette.gold
                              : palette.border,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedCategory = cat);
                            _applyFilter();
                          }
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppSpace.sm),

                // Hadith List
                Expanded(
                  child: _filteredHadiths.isEmpty
                      ? Center(
                          child: Text(
                            'لم يتم العثور على أحاديث مطابقة',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: palette.textMuted,
                              fontFamily: AppTextStyles.cairo,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsetsDirectional.only(
                            start: AppSpace.lg,
                            end: AppSpace.lg,
                            top: AppSpace.sm,
                            bottom: AppSize.navClearance(context),
                          ),
                          itemCount: _filteredHadiths.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpace.lg),
                          itemBuilder: (context, index) {
                            return HadithCard(
                              hadith: _filteredHadiths[index],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
