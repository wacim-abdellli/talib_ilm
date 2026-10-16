import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/models/shamela_models.dart';
import '../../data/services/shamela_service.dart';
import '../pages/shamela_reader_page.dart';
import 'shamela_book_card.dart';
import 'shamela_shuruh_sheet.dart';

class MaktabaShamelaView extends StatefulWidget {
  const MaktabaShamelaView({super.key});

  @override
  State<MaktabaShamelaView> createState() => _MaktabaShamelaViewState();
}

class _MaktabaShamelaViewState extends State<MaktabaShamelaView> {
  int _selectedCategoryId = 0;
  int _selectedLevel = 0; // 0 = الكل, 1 = مبتدئ, 2 = متوسط, 3 = متقدم
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  final Map<int, bool> _downloadedMap = {};
  final Map<int, double> _downloadProgress = {};

  static const List<({int id, String label})> _levels = [
    (id: 0, label: 'جميع المستويات'),
    (id: 1, label: 'تمهيدي'),
    (id: 2, label: 'تأصيلي'),
    (id: 3, label: 'مطولات'),
  ];

  @override
  void initState() {
    super.initState();
    _checkDownloadedBooks();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkDownloadedBooks() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final map = <int, bool>{};
    for (final book in ShamelaService.curatedClassics) {
      map[book.id] = prefs.getBool('shamela_downloaded_${book.id}') ?? false;
    }
    setState(() => _downloadedMap.addAll(map));
  }

  Future<void> _downloadBook(ShamelaBook book) async {
    HapticFeedback.selectionClick();
    setState(() => _downloadProgress[book.id] = 0.0);

    try {
      await ShamelaService.downloadBook(
        book,
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _downloadProgress[book.id] = current / total;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _downloadProgress.remove(book.id);
          _downloadedMap[book.id] = true;
        });
        AppSnackbar.success(
          context,
          'تم تحميل كتاب "${book.title}" بنجاح للقراءة بدون إنترنت',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloadProgress.remove(book.id));
        AppSnackbar.error(context, 'تعذر إكمال تحميل الكتاب: $e');
      }
    }
  }

  void _openBook(ShamelaBook book) async {
    HapticFeedback.lightImpact();
    final lastPage = await ShamelaService.getLastReadPage(book.id);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShamelaReaderPage(
          book: book,
          initialPage: lastPage,
        ),
      ),
    );
  }

  void _openShuruhSheet(ShamelaBook parentBook, List<ShamelaBook> shuruh) {
    HapticFeedback.selectionClick();
    ShamelaShuruhSheet.show(
      context: context,
      parentBook: parentBook,
      shuruh: shuruh,
      downloadedMap: _downloadedMap,
      downloadProgress: _downloadProgress,
      onOpenSharh: _openBook,
      onDownloadSharh: _downloadBook,
    );
  }

  List<ShamelaBook> get _filteredBooks {
    return ShamelaService.searchCatalog(
      query: _searchQuery,
      categoryId: _selectedCategoryId,
      level: _selectedLevel,
      rootOnly: _searchQuery.isEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final books = _filteredBooks;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpace.sm),
              // ── Search & Filter Input ────────────────────────────────
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.surfaceRaised,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: palette.border),
                  ),
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: palette.textMuted, size: AppIcon.md),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            _searchDebounce?.cancel();
                            _searchDebounce = Timer(AppMotion.searchDebounce, () {
                              if (mounted) {
                                setState(() => _searchQuery = val);
                              }
                            });
                          },
                          style: textTheme.body.copyWith(color: palette.text),
                          decoration: InputDecoration(
                            hintText: 'ابحث في أمهات كتب المكتبة والشروح...',
                            hintStyle: textTheme.bodySmall.copyWith(color: palette.textMuted),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear_rounded, size: AppIcon.sm, color: palette.textMuted),
                          tooltip: 'مسح البحث',
                          onPressed: () {
                            _searchDebounce?.cancel();
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpace.md),

              // ── Categories Horizontal Filter Chips ─────────────────────
              SizedBox(
                height: AppSize.tap,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
                  itemCount: ShamelaService.categories.length,
                  separatorBuilder: (_, index) => const SizedBox(width: AppSpace.xs),
                  itemBuilder: (context, index) {
                    final cat = ShamelaService.categories[index];
                    final isSelected = _selectedCategoryId == cat.id;

                    return ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: AppSize.tap),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: AppRadius.pillRadius,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCategoryId = cat.id);
                          },
                          child: AnimatedContainer(
                            duration: AppMotion.fast,
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.md,
                              vertical: AppSpace.xs,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? palette.primarySoft : palette.surfaceRaised,
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(
                                color: isSelected ? palette.primary : palette.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              cat.count > 0 && cat.id != 0
                                  ? '${cat.name} (${cat.count})'
                                  : cat.name,
                              style: textTheme.caption.copyWith(
                                color: isSelected ? palette.primary : palette.textMuted,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpace.xs),

              // ── Sullam / Level Segmentation Filter Bar ────────────────
              SizedBox(
                height: AppSize.tap,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
                  itemCount: _levels.length,
                  separatorBuilder: (_, index) => const SizedBox(width: AppSpace.xs),
                  itemBuilder: (context, index) {
                    final lvl = _levels[index];
                    final isSelected = _selectedLevel == lvl.id;

                    return ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: AppSize.tap),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: AppRadius.pillRadius,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedLevel = lvl.id);
                          },
                          child: AnimatedContainer(
                            duration: AppMotion.fast,
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.md,
                              vertical: AppSpace.xs,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? palette.primarySoft : palette.surfaceMuted,
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(
                                color: isSelected ? palette.primary : palette.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              lvl.label,
                              style: textTheme.caption.copyWith(
                                color: isSelected ? palette.primary : palette.textMuted,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpace.md),
            ],
          ),
        ),

        // ── Books Results List (Virtualized SliverList) ──────────────
        if (books.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsDirectional.all(AppSpace.xl),
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'لا توجد نتائج في المكتبة',
                subtitle: 'جرب البحث باسم كتاب آخر أو تغيير الفن والمستوى.',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
            sliver: SliverList.separated(
              itemCount: books.length,
              separatorBuilder: (_, index) => const SizedBox(height: AppSpace.sm),
              itemBuilder: (context, index) {
                final book = books[index];
                return ShamelaBookCard(
                  book: book,
                  isDownloaded: _downloadedMap[book.id] ?? false,
                  downloadProgress: _downloadProgress[book.id],
                  onOpen: () => _openBook(book),
                  onDownload: () => _downloadBook(book),
                  onOpenShuruh: _openShuruhSheet,
                );
              },
            ),
          ),

        SliverToBoxAdapter(
          child: SizedBox(height: AppSize.navClearance(context)),
        ),
      ],
    );
  }
}
