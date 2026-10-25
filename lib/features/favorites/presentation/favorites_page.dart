import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/models/favorite_item.dart';
import '../../../core/services/asset_service.dart';
import '../../../core/services/favorites_service.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_states.dart';
import '../../ilm/data/models/mutun_models.dart';
import '../../ilm/data/services/book_progress_service.dart';
import '../../ilm/data/services/bookmark_entry_loader.dart';
import '../../ilm/presentation/pages/book_view_page.dart';
import 'widgets/favorites_book_entries_view.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FavoritesService _service = FavoritesService();
  late Future<List<FavoriteItem>> _future;
  late Future<List<BookmarkEntry>> _bookEntriesFuture;
  int _favoritesCount = 0;
  int _bookEntriesCount = 0;
  int _selectedTab = 0; // 0: general favorites, 1: book bookmarks & notes

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _service.getAll().then((items) {
      if (mounted) {
        setState(() => _favoritesCount = items.length);
      }
      return items;
    });

    _bookEntriesFuture = SharedPreferences.getInstance().then((prefs) {
      final progressService = BookProgressService(prefs);
      return BookmarkEntryLoader.loadAll(progressService);
    }).then((entries) {
      if (mounted) {
        setState(() => _bookEntriesCount = entries.length);
      }
      return entries;
    });
  }

  void _reload() {
    setState(() {
      _load();
    });
  }

  Future<void> _openBookEntry(BookmarkEntry entry) async {
    HapticFeedback.lightImpact();
    final program = await AssetService.loadMutunProgram();
    IlmBook? targetBook;
    for (final lvl in program.levels) {
      for (final b in lvl.books) {
        if (b.id == entry.bookId) {
          targetBook = b;
          break;
        }
      }
    }
    if (targetBook != null && mounted) {
      await Navigator.push(
        context,
        buildFadeRoute(
          page: BookViewPage(
            book: targetBook,
            initialPage: entry.page,
            autoOpenSharhFile: entry.sharhFile,
          ),
        ),
      );
      _reload();
    }
  }

  Future<void> _removeBookEntry(BookmarkEntry entry, {required bool isNote}) async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    final progressService = BookProgressService(prefs);

    if (isNote) {
      if (entry.sharhFile != null) {
        await progressService.deleteSharhNote(entry.bookId, entry.sharhFile!, entry.page);
      } else {
        await progressService.deleteNote(entry.bookId, entry.page);
      }
      if (mounted) {
        AppSnackbar.info(context, 'تم حذف الملاحظة');
      }
    } else {
      if (entry.sharhFile != null) {
        await progressService.removeSharhBookmark(entry.bookId, entry.sharhFile!, entry.page);
      } else {
        await progressService.removeBookmark(entry.bookId, entry.page);
      }
      if (mounted) {
        AppSnackbar.info(context, 'تمت إزالة الإشارة المرجعية');
      }
    }
    _reload();
  }

  void _editBookNote(BookmarkEntry entry) {
    HapticFeedback.selectionClick();
    final controller = TextEditingController(text: entry.note ?? '');

    AppDialog.show<void>(
      context: context,
      builder: (dialogCtx) => AppDialog(
        title: 'تعديل الملاحظة',
        icon: Icons.edit_note_rounded,
        content: TextField(
          controller: controller,
          style: dialogCtx.text.body,
          decoration: InputDecoration(
            hintText: 'اكتب ملاحظتك هنا...',
            hintStyle: dialogCtx.text.bodySmall.copyWith(
              color: dialogCtx.palette.textMuted,
            ),
          ),
          minLines: 3,
          maxLines: 6,
        ),
        actions: [
          AppButton.text(
            label: 'إلغاء',
            onPressed: () => Navigator.pop(dialogCtx),
            size: AppButtonSize.sm,
          ),
          AppButton(
            label: 'حفظ',
            onPressed: () async {
              final newText = controller.text.trim();
              Navigator.pop(dialogCtx);
              final prefs = await SharedPreferences.getInstance();
              final progressService = BookProgressService(prefs);
              if (entry.sharhFile != null) {
                await progressService.saveSharhNote(entry.bookId, entry.sharhFile!, entry.page, newText);
              } else {
                await progressService.saveNote(entry.bookId, entry.page, newText);
              }
              if (mounted) {
                AppSnackbar.success(context, 'تم تحديث الملاحظة');
              }
              _reload();
            },
            size: AppButtonSize.sm,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final currentCount = _selectedTab == 0 ? _favoritesCount : _bookEntriesCount;

    return Scaffold(
      backgroundColor: palette.bg,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpace.xl,
              AppSpace.lg,
              AppSpace.xl,
              AppSpace.md,
            ),
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border(
                bottom: BorderSide(color: palette.border, width: 1),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(
                    children: [
                      const AppBackButton(),
                      const SizedBox(width: AppSpace.xs),
                      Container(
                        width: AppSize.tap,
                        height: AppSize.tap,
                        decoration: BoxDecoration(
                          color: palette.goldSoft,
                          borderRadius: AppRadius.mdRadius,
                          border: Border.all(
                            color: palette.gold.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.collections_bookmark_rounded,
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
                              'المفضلة والمحفوظات',
                              style: textTheme.title.copyWith(
                                color: palette.text,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _selectedTab == 0
                                  ? '$currentCount عنصر محفوظ'
                                  : '$currentCount إشارة وملاحظة محفوظة',
                              style: textTheme.bodySmall.copyWith(
                                color: palette.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  Container(
                    decoration: BoxDecoration(
                      color: palette.surfaceRaised,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(color: palette.border),
                    ),
                    padding: const EdgeInsetsDirectional.all(AppSpace.xxs),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: AppRadius.smRadius,
                            onTap: () => setState(() => _selectedTab = 0),
                            child: AnimatedContainer(
                              duration: AppMotion.fast,
                              padding: const EdgeInsetsDirectional.symmetric(
                                vertical: AppSpace.xs,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? palette.primarySoft
                                    : Colors.transparent,
                                borderRadius: AppRadius.smRadius,
                              ),
                              child: Center(
                                child: Text(
                                  'المفضلة العامة ($_favoritesCount)',
                                  style: textTheme.caption.copyWith(
                                    color: _selectedTab == 0
                                        ? palette.primary
                                        : palette.textMuted,
                                    fontWeight: _selectedTab == 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: AppRadius.smRadius,
                            onTap: () => setState(() => _selectedTab = 1),
                            child: AnimatedContainer(
                              duration: AppMotion.fast,
                              padding: const EdgeInsetsDirectional.symmetric(
                                vertical: AppSpace.xs,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? palette.primarySoft
                                    : Colors.transparent,
                                borderRadius: AppRadius.smRadius,
                              ),
                              child: Center(
                                child: Text(
                                  'إشارات وملاحظات الكتب ($_bookEntriesCount)',
                                  style: textTheme.caption.copyWith(
                                    color: _selectedTab == 1
                                        ? palette.primary
                                        : palette.textMuted,
                                    fontWeight: _selectedTab == 1
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildGeneralFavoritesView(palette, textTheme)
                : FutureBuilder<List<BookmarkEntry>>(
                    future: _bookEntriesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const AppLoadingIndicator();
                      }
                      final entries = snapshot.data ?? const [];
                      return FavoritesBookEntriesView(
                        entries: entries,
                        onSelect: _openBookEntry,
                        onRemoveBookmark: (BookmarkEntry e) => _removeBookEntry(e, isNote: false),
                        onRemoveNote: (BookmarkEntry e) => _removeBookEntry(e, isNote: true),
                        onEditNote: _editBookNote,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralFavoritesView(AppPalette palette, AppTextTheme textTheme) {
    return FutureBuilder<List<FavoriteItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingIndicator();
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsetsDirectional.all(AppSpace.xl),
            child: AppEmptyState.favorites(),
          );
        }

        final grouped = <FavoriteType, List<FavoriteItem>>{};
        for (final item in items) {
          grouped.putIfAbsent(item.type, () => []).add(item);
        }

        final sections = FavoriteType.values.where(grouped.containsKey).map((type) {
          final list = grouped[type]!;
          return _Section(
            title: _labelFor(type),
            items: list,
            onRemove: (item) async {
              await _service.remove(item.type, item.id);
              _reload();
            },
          );
        }).toList();

        return ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.xl,
            vertical: AppSpace.lg,
          ),
          children: [
            ...sections,
            SizedBox(height: AppSize.navClearance(context)),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<FavoriteItem> items;
  final void Function(FavoriteItem item) onRemove;

  const _Section({
    required this.title,
    required this.items,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleSmall.copyWith(color: palette.text),
        ),
        const SizedBox(height: AppSpace.sm),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
            child: AppCard(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: textTheme.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.text,
                          ),
                        ),
                        if (item.subtitle.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            item.subtitle,
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AppIconButton(
                    tooltip: AppStrings.favoritesRemoveTooltip,
                    onPressed: () => onRemove(item),
                    icon: Icons.bookmark_remove_rounded,
                    color: palette.gold,
                    iconSize: AppIcon.md,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
      ],
    );
  }
}

String _labelFor(FavoriteType type) {
  switch (type) {
    case FavoriteType.hadith:
      return AppStrings.favoriteTypeHadith;
    case FavoriteType.dhikr:
      return AppStrings.favoriteTypeDhikr;
    case FavoriteType.dua:
      return AppStrings.favoriteTypeDua;
    case FavoriteType.lesson:
      return AppStrings.favoriteTypeLesson;
    case FavoriteType.book:
      return AppStrings.favoriteTypeBook;
    case FavoriteType.quran:
      return AppStrings.favoriteTypeQuran;
    case FavoriteType.quote:
      return AppStrings.favoriteTypeQuote;
  }
}
