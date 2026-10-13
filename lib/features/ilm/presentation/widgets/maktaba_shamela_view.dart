import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/models/shamela_models.dart';
import '../../data/services/shamela_service.dart';
import '../pages/shamela_reader_page.dart';

class MaktabaShamelaView extends StatefulWidget {
  const MaktabaShamelaView({super.key});

  @override
  State<MaktabaShamelaView> createState() => _MaktabaShamelaViewState();
}

class _MaktabaShamelaViewState extends State<MaktabaShamelaView> {
  int _selectedCategoryId = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  final Map<int, bool> _downloadedMap = {};
  final Map<int, double> _downloadProgress = {};

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
        AppSnackbar.success(context, 'تم تحميل كتاب "${book.title}" بنجاح للقراءة بدون إنترنت');
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

  List<ShamelaBook> get _filteredBooks {
    return ShamelaService.searchCatalog(
      query: _searchQuery,
      categoryId: _selectedCategoryId,
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
                            hintText: 'ابحث في أمهات كتب التراث ومصنفات الأئمة...',
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
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
                  itemCount: ShamelaService.categories.length,
                  separatorBuilder: (_, index) => const SizedBox(width: AppSpace.xs),
                  itemBuilder: (context, index) {
                    final cat = ShamelaService.categories[index];
                    final isSelected = _selectedCategoryId == cat.id;

                    return Material(
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
                            color: isSelected ? palette.gold : palette.surfaceRaised,
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(
                              color: isSelected ? palette.gold : palette.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cat.count > 0 && cat.id != 0
                                ? '${cat.name} (${cat.count})'
                                : cat.name,
                            style: textTheme.caption.copyWith(
                              color: isSelected ? palette.brandDark : palette.text,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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
                title: 'لا توجد نتائج في خزانة التراث',
                subtitle: 'جرب البحث باسم كتاب آخر أو اختيار فن من الفنون والعلوم.',
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
                final isDownloaded = _downloadedMap[book.id] ?? false;
                final progress = _downloadProgress[book.id];

                return AppCard(
                  onTap: () => _openBook(book),
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: palette.goldSoft,
                              borderRadius: AppRadius.smRadius,
                              border: Border.all(color: palette.gold.withValues(alpha: 0.3)),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.auto_stories_rounded,
                              color: palette.gold,
                              size: AppIcon.lg,
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  style: textTheme.titleSmall.copyWith(
                                    color: palette.text,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpace.xxs),
                                Text.rich(
                                  TextSpan(
                                    text: book.author,
                                    style: textTheme.caption.copyWith(
                                      color: palette.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    children: [
                                      if (book.authorDeath != null) ...[
                                        const TextSpan(text: ' '),
                                        TextSpan(
                                          text: '(${book.authorDeath})',
                                          style: textTheme.caption.copyWith(color: palette.textMuted),
                                        ),
                                      ],
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Category Pill
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.xs,
                              vertical: AppSpace.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surfaceMuted,
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: Text(
                              book.category,
                              style: textTheme.caption.copyWith(color: palette.textMuted),
                            ),
                          ),
                        ],
                      ),

                      if (book.description.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          book.description,
                          style: textTheme.bodySmall.copyWith(
                            color: palette.textMuted,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: AppSpace.sm),
                      Divider(color: palette.border, height: 1),
                      const SizedBox(height: AppSpace.xs),

                      // Actions Bar: Read vs Offline Download
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpace.sm,
                        runSpacing: AppSpace.xs,
                        children: [
                          Text(
                            '${book.totalPages} صفحة',
                            style: textTheme.caption.copyWith(color: palette.textMuted),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (progress != null) ...[
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    color: palette.gold,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Text(
                                  'جاري التحميل ${(progress * 100).toInt()}%',
                                  style: textTheme.caption.copyWith(color: palette.gold),
                                ),
                              ] else if (isDownloaded) ...[
                                Icon(Icons.cloud_done_rounded, color: palette.gold, size: AppIcon.sm),
                                const SizedBox(width: AppSpace.xxs),
                                Text(
                                  'محمّل بدون إنترنت',
                                  style: textTheme.caption.copyWith(
                                    color: palette.gold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ] else ...[
                                TextButton.icon(
                                  onPressed: () => _downloadBook(book),
                                  icon: Icon(Icons.cloud_download_rounded, size: AppIcon.sm, color: palette.primary),
                                  label: Text(
                                    'تحميل بدون إنترنت',
                                    style: textTheme.caption.copyWith(
                                      color: palette.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: AppSpace.sm),
                              AppButton(
                                size: AppButtonSize.sm,
                                label: 'قراءة الكتاب',
                                onPressed: () => _openBook(book),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
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
