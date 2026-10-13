import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_text_styles.dart';
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

  List<GradedHadith> _allHadiths = [];
  List<GradedHadith> _filteredHadiths = [];
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHadiths() async {
    final hadiths = await _hadithService.getAllHadiths();
    final categories = await _hadithService.getCategories();

    if (!mounted) return;

    setState(() {
      _allHadiths = hadiths;
      _categories = ['الكل', ...categories];
      if (widget.initialCategory != null &&
          _categories.contains(widget.initialCategory)) {
        _selectedCategory = widget.initialCategory!;
      }
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    final query = _searchController.text.trim();
    List<GradedHadith> list = _allHadiths;

    if (_selectedCategory != 'الكل') {
      list = list.where((h) => h.category == _selectedCategory).toList();
    }

    if (query.isNotEmpty) {
      final clean = _normalize(query);
      list = list.where((h) {
        return _normalize(h.title).contains(clean) ||
            _normalize(h.matn).contains(clean) ||
            _normalize(h.narrator).contains(clean) ||
            _normalize(h.benefits).contains(clean);
      }).toList();
    }

    setState(() {
      _filteredHadiths = list;
    });
  }

  String _normalize(String s) {
    return s
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll(RegExp(r'[إأآا]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        title: Text(
          'الأحاديث النبوية الصحيحة',
          style: AppTextStyles.titleMedium.copyWith(
            color: palette.text,
            fontFamily: AppTextStyles.cairo,
          ),
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
                      onChanged: (_) => _applyFilter(),
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

                // Category Chips
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.lg,
                    ),
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: AppSpace.sm),
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
                        selectedColor: palette.primary,
                        backgroundColor: palette.surface,
                        side: BorderSide(
                          color: isSelected
                              ? palette.primary
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

                const SizedBox(height: AppSpace.md),

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
