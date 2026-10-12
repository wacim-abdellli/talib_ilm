import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../data/services/bookmark_service.dart';
import 'widgets/ayah_details_sheet.dart';
import 'widgets/mushaf_page_viewer.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  List<Bookmark> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final list = await BookmarkService.getBookmarks();
    if (mounted) {
      setState(() {
        _bookmarks = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeBookmark(Bookmark bookmark) async {
    HapticFeedback.selectionClick();
    await BookmarkService.removeBookmark(bookmark.surah, bookmark.ayah);
    setState(() {
      _bookmarks.removeWhere((b) => b.surah == bookmark.surah && b.ayah == bookmark.ayah);
    });
    if (!mounted) return;
    AppSnackbar.info(context, 'تمت إزالة الآية من المحفوظات');
  }

  void _openBookmark(Bookmark bookmark) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MushafPageViewer(
          initialPage: bookmark.page,
          initialSurah: bookmark.surah,
          initialAyah: bookmark.ayah,
        ),
      ),
    ).then((_) => _loadBookmarks());
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: PrimaryAppBar(
        title: 'المحفوظات والتدبر',
        showBack: true,
        bottom: (!_isLoading && _bookmarks.isNotEmpty)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: AppSpace.xs),
                  child: Text(
                    '${_bookmarks.length} علامة وملاحظة محفوظة',
                    style: textTheme.caption.copyWith(
                      color: palette.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: palette.gold))
          : _bookmarks.isEmpty
              ? EmptyState(
                  icon: Icons.bookmark_border_rounded,
                  title: 'لا توجد آيات أو ملاحظات محفوظة بعد',
                  subtitle:
                      'اضغط على أيقونة الحفظ عند قراءة أي آية لإضافتها إلى قائمة المحفوظات وتدوين خواطرك حولها.',
                  actionLabel: 'تصفح القرآن الكريم',
                  onAction: () => Navigator.pop(context),
                )
              : ListView.builder(
                  padding: AppSpace.screenPadding.copyWith(
                    top: AppSpace.sm,
                    bottom: AppSpace.xxl,
                  ),
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, index) {
                    final b = _bookmarks[index];
                    final surahName = quran.getSurahNameArabic(b.surah);
                    final verseText = quran.getVerse(b.surah, b.ayah, verseEndSymbol: false);

                    return Dismissible(
                      key: ValueKey('${b.surah}_${b.ayah}_${b.timestamp.millisecondsSinceEpoch}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: AlignmentDirectional.centerEnd,
                        padding: const EdgeInsetsDirectional.only(end: AppSpace.lg),
                        decoration: BoxDecoration(
                          color: palette.error.withValues(alpha: 0.15),
                          borderRadius: AppRadius.mdRadius,
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: palette.error,
                          size: AppIcon.md,
                        ),
                      ),
                      onDismissed: (_) => _removeBookmark(b),
                      child: Container(
                        margin: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
                        decoration: BoxDecoration(
                          color: palette.surfaceRaised,
                          borderRadius: AppRadius.mdRadius,
                          border: Border.all(color: palette.border),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: AppRadius.mdRadius,
                            onTap: () => _openBookmark(b),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.all(AppSpace.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: palette.goldSoft,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: AlignmentDirectional.center,
                                        child: Text(
                                          '${b.ayah}',
                                          style: textTheme.caption.copyWith(
                                            color: palette.gold,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpace.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'سورة $surahName',
                                              style: textTheme.titleSmall.copyWith(
                                                color: palette.text,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'الصفحة ${b.page}',
                                              style: textTheme.caption.copyWith(
                                                color: palette.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AppIconButton(
                                        icon: Icons.menu_book_rounded,
                                        tooltip: 'التفسير والتدبر',
                                        color: palette.textMuted,
                                        onPressed: () {
                                          AyahDetailsSheet.show(
                                            context,
                                            surahNumber: b.surah,
                                            ayahNumber: b.ayah,
                                            onBookmarkChanged: _loadBookmarks,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpace.xs),
                                  Text(
                                    verseText,
                                    style: textTheme.sacred.copyWith(
                                      color: palette.text,
                                      height: 1.6,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (b.note != null && b.note!.trim().isNotEmpty) ...[
                                    const SizedBox(height: AppSpace.xs),
                                    Container(
                                      padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                                      decoration: BoxDecoration(
                                        color: palette.surfaceMuted,
                                        borderRadius: AppRadius.smRadius,
                                        border: Border.all(color: palette.border),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_note_rounded,
                                            size: AppIcon.sm,
                                            color: palette.primary,
                                          ),
                                          const SizedBox(width: AppSpace.xs),
                                          Expanded(
                                            child: Text(
                                              b.note!,
                                              style: textTheme.caption.copyWith(
                                                color: palette.text,
                                                fontStyle: FontStyle.italic,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
