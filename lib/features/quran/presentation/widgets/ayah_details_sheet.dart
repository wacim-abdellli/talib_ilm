import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import '../../../../core/utils/app_share.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../data/services/bookmark_service.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/quran_reader_preferences.dart';
import '../../data/services/quran_tafsir_service.dart';
import '../../data/services/tajweed_service.dart';
import '../../data/services/tajweed_verse_service.dart';
import 'ayah_details_tabs.dart';

class AyahDetailsSheet extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final TafsirScholar? initialTafsirScholar;
  final VoidCallback? onBookmarkChanged;
  final void Function(int surah, int ayah)? onNavigateToVerse;

  final int initialTabIndex;

  const AyahDetailsSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    this.initialTafsirScholar,
    this.onBookmarkChanged,
    this.onNavigateToVerse,
    this.initialTabIndex = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required int surahNumber,
    required int ayahNumber,
    TafsirScholar? initialTafsirScholar,
    VoidCallback? onBookmarkChanged,
    void Function(int surah, int ayah)? onNavigateToVerse,
    int initialTabIndex = 0,
  }) {
    return AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.92,
      enableDrag: false,
      builder: (_) => AyahDetailsSheet(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        initialTafsirScholar: initialTafsirScholar,
        onBookmarkChanged: onBookmarkChanged,
        onNavigateToVerse: onNavigateToVerse,
        initialTabIndex: initialTabIndex,
      ),
    );
  }

  @override
  State<AyahDetailsSheet> createState() => _AyahDetailsSheetState();
}

class _AyahDetailsSheetState extends State<AyahDetailsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final QuranAudioService _audioService = QuranAudioService();
  final TextEditingController _noteController = TextEditingController();

  late TafsirScholar _selectedScholar;
  String? _tajweedMarkup;
  String _tafsirText = '';
  bool _loadingTafsir = true;
  bool _isBookmarked = false;
  bool _isLastRead = false;

  @override
  void initState() {
    super.initState();
    _selectedScholar = widget.initialTafsirScholar ?? TafsirScholar.muyassar;
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 5),
    );
    _loadBookmarkState();
    _loadTajweedMarkup();
    if (widget.initialTafsirScholar != null) {
      _fetchTafsir();
    } else {
      _initScholarFromPrefs();
    }
  }

  Future<void> _initScholarFromPrefs() async {
    final snapshot = await QuranReaderPreferences.load();
    if (!mounted) return;
    setState(() => _selectedScholar = snapshot.defaultTafsir);
    await _fetchTafsir();
  }

  Future<void> _loadTajweedMarkup() async {
    final markup = await TajweedVerseService.getAyahMarkup(
      widget.surahNumber,
      widget.ayahNumber,
    );
    if (!mounted) return;
    setState(() => _tajweedMarkup = markup);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarkState() async {
    final bookmarks = await BookmarkService.getBookmarks();
    final hasSavedLastRead = await BookmarkService.hasSavedLastRead();
    final lastRead = await BookmarkService.getLastRead();
    final current = bookmarks.where(
      (b) => b.surah == widget.surahNumber && b.ayah == widget.ayahNumber,
    );
    final isLastRead =
        hasSavedLastRead &&
        lastRead.surah == widget.surahNumber &&
        lastRead.ayah == widget.ayahNumber;

    if (!mounted) return;
    setState(() => _isLastRead = isLastRead);
    if (current.isNotEmpty) {
      final b = current.first;
      setState(() {
        _isBookmarked = true;
        _noteController.text = b.note ?? '';
      });
    } else {
      setState(() {
        _isBookmarked = false;
        _noteController.text = '';
      });
    }
  }

  Future<void> _fetchTafsir() async {
    setState(() => _loadingTafsir = true);
    final text = await QuranTafsirService.getTafsir(
      surahNumber: widget.surahNumber,
      ayahNumber: widget.ayahNumber,
      scholar: _selectedScholar,
    );
    if (!mounted) return;
    setState(() {
      _tafsirText = text;
      _loadingTafsir = false;
    });
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.selectionClick();
    final note = _noteController.text.trim().isNotEmpty
        ? _noteController.text.trim()
        : null;
    final isNowBookmarked = await BookmarkService.toggleBookmark(
      widget.surahNumber,
      widget.ayahNumber,
      note: note,
    );

    if (!mounted) return;
    setState(() => _isBookmarked = isNowBookmarked);
    widget.onBookmarkChanged?.call();

    if (isNowBookmarked) {
      AppSnackbar.success(context, 'تمت إضافة الآية إلى المحفوظات');
    } else {
      AppSnackbar.info(context, 'تمت إزالة الآية من المحفوظات');
    }
  }

  Future<void> _saveNote() async {
    HapticFeedback.selectionClick();
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      await _deleteNote();
      return;
    }
    await BookmarkService.updateNote(
      widget.surahNumber,
      widget.ayahNumber,
      note,
    );
    if (!mounted) return;
    setState(() => _isBookmarked = true);
    widget.onBookmarkChanged?.call();
    AppSnackbar.success(context, 'تم حفظ التدبر بنجاح');
  }

  Future<void> _deleteNote() async {
    HapticFeedback.lightImpact();
    _noteController.clear();
    await BookmarkService.removeNote(
      widget.surahNumber,
      widget.ayahNumber,
    );
    if (!mounted) return;
    setState(() => _isBookmarked = false);
    widget.onBookmarkChanged?.call();
    AppSnackbar.info(context, 'تم حذف التدبر بنجاح');
  }

  Future<void> _toggleLastRead() async {
    HapticFeedback.selectionClick();
    if (_isLastRead) {
      final removed = await BookmarkService.clearLastReadIfMatches(
        surah: widget.surahNumber,
        ayah: widget.ayahNumber,
      );
      if (!mounted) return;
      if (!removed) {
        await _loadBookmarkState();
        return;
      }
      setState(() => _isLastRead = false);
      widget.onBookmarkChanged?.call();
      AppSnackbar.info(context, 'تمت إزالة موضع القراءة');
      return;
    }

    final page = quran.getPageNumber(widget.surahNumber, widget.ayahNumber);
    await BookmarkService.saveLastRead(
      surah: widget.surahNumber,
      ayah: widget.ayahNumber,
      page: page,
    );
    if (!mounted) return;
    setState(() => _isLastRead = true);
    widget.onBookmarkChanged?.call();
    AppSnackbar.success(context, 'تم حفظ موضع القراءة');
  }

  Future<void> _copyVerse() async {
    HapticFeedback.selectionClick();
    final verse = quran.getVerse(
      widget.surahNumber,
      widget.ayahNumber,
      verseEndSymbol: true,
    );
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    await Clipboard.setData(
      ClipboardData(text: '﴿$verse﴾ [$surahName: ${widget.ayahNumber}]'),
    );
    if (!mounted) return;
    AppSnackbar.success(context, 'تم نسخ الآية الكريمة');
  }

  Future<void> _shareVerse() async {
    HapticFeedback.selectionClick();
    final verse = quran.getVerse(
      widget.surahNumber,
      widget.ayahNumber,
      verseEndSymbol: true,
    );
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    await AppShare.share(
      context,
      '﴿$verse﴾ [$surahName: ${widget.ayahNumber}]',
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    return Container(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpace.md,
        bottom: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),

          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.xl,
            ),
            child: Row(
              children: [
                const IconBadge(icon: Icons.menu_book_rounded),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _audioService.activeSurahNotifier,
                          _audioService.activeAyahNotifier,
                        ]),
                        builder: (context, _) {
                          final playingSurah =
                              _audioService.activeSurahNotifier.value;
                          final playingAyah =
                              _audioService.activeAyahNotifier.value;
                          final syncSurah = playingSurah ?? widget.surahNumber;
                          final syncAyah = playingAyah ?? widget.ayahNumber;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'سورة ${quran.getSurahNameArabic(syncSurah)} • الآية $syncAyah',
                                style: textTheme.titleSmall.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'الجزء ${quran.getJuzNumber(syncSurah, syncAyah)} • الصفحة ${quran.getPageNumber(syncSurah, syncAyah)}',
                                style: textTheme.caption.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: _isBookmarked
                      ? Icons.bookmark_added_rounded
                      : Icons.bookmark_add_outlined,
                  tooltip: 'حفظ الآية',
                  color: _isBookmarked ? palette.gold : palette.textMuted,
                  onPressed: _toggleBookmark,
                ),
                AppIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'إغلاق',
                  color: palette.textMuted,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.xs),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: AppSpace.xs),

          // Pinned Verse Text Card with Compact Constraint
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.lg,
            ),
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _audioService.activeSurahNotifier,
                _audioService.activeAyahNotifier,
              ]),
              builder: (context, _) {
                final syncSurah =
                    _audioService.activeSurahNotifier.value ??
                    widget.surahNumber;
                final syncAyah =
                    _audioService.activeAyahNotifier.value ?? widget.ayahNumber;
                final syncVerse = quran.getVerse(
                  syncSurah,
                  syncAyah,
                  verseEndSymbol: true,
                );
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 110),
                  child: AppCard(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.sm,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text.rich(
                          TextSpan(
                            children: TajweedService.buildVerseSpans(
                              plainUthmani: syncVerse,
                              quranComMarkup:
                                  syncSurah == widget.surahNumber &&
                                      syncAyah == widget.ayahNumber
                                  ? _tajweedMarkup
                                  : null,
                              baseStyle: textTheme.sacred.copyWith(
                                color: palette.text,
                                height: 1.6,
                              ),
                              isTajweedEnabled: true,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpace.xs),

          // Pinned Tab Bar
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.lg,
            ),
            child: Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.xxs),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.pillRadius,
                border: Border.all(color: palette.border),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: palette.primary,
                unselectedLabelColor: palette.textMuted,
                indicator: BoxDecoration(
                  color: palette.surfaceRaised,
                  borderRadius: AppRadius.pillRadius,
                  boxShadow: palette.shadow,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: textTheme.label.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: textTheme.label,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.auto_stories_rounded, size: AppIcon.sm),
                    text: 'التفسير',
                  ),
                  Tab(
                    icon: Icon(Icons.spellcheck_rounded, size: AppIcon.sm),
                    text: 'المعاني',
                  ),
                  Tab(
                    icon: Icon(Icons.compare_arrows_rounded, size: AppIcon.sm),
                    text: 'المتشابهات',
                  ),
                  Tab(
                    icon: Icon(
                      Icons.pause_circle_outline_rounded,
                      size: AppIcon.sm,
                    ),
                    text: 'أحكام الوقف',
                  ),
                  Tab(
                    icon: Icon(Icons.headphones_rounded, size: AppIcon.sm),
                    text: 'التلاوة',
                  ),
                  Tab(
                    icon: Icon(Icons.edit_note_rounded, size: AppIcon.sm),
                    text: 'التدبر',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpace.xs),

          // Expanded TabBarView: Takes full height, allowing inner tabs to scroll freely
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.lg,
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  AyahTafsirTabView(
                    selectedScholar: _selectedScholar,
                    tafsirText: _tafsirText,
                    loadingTafsir: _loadingTafsir,
                    onScholarChanged: (scholar) {
                      setState(() => _selectedScholar = scholar);
                      QuranReaderPreferences.saveTafsirScholar(scholar);
                      _fetchTafsir();
                    },
                  ),
                  AyahWordsTabView(
                    surahNumber: widget.surahNumber,
                    ayahNumber: widget.ayahNumber,
                  ),
                  AyahSimilarTabView(
                    surahNumber: widget.surahNumber,
                    ayahNumber: widget.ayahNumber,
                    onNavigateToVerse: (surah, ayah) {
                      Navigator.of(context).pop();
                      widget.onNavigateToVerse?.call(surah, ayah);
                    },
                  ),
                  AyahWaqfTabView(
                    surahNumber: widget.surahNumber,
                    ayahNumber: widget.ayahNumber,
                  ),
                  AyahAudioTabView(
                    surahNumber: widget.surahNumber,
                    ayahNumber: widget.ayahNumber,
                    audioService: _audioService,
                  ),
                  AyahNotesTabView(
                    noteController: _noteController,
                    onSaveNote: _saveNote,
                    onDeleteNote: _deleteNote,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpace.xs),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: AppSpace.xs),

          // Pinned Bottom Action Bar
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.lg,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(1) > 1.2;
                final isNarrow = constraints.maxWidth < 360 || largeText;
                final positionButton = AppButton(
                  label: _isLastRead ? 'إزالة الموضع' : 'حفظ الموضع',
                  icon: _isLastRead
                      ? Icons.bookmark_remove_rounded
                      : Icons.bookmark_add_rounded,
                  onPressed: _toggleLastRead,
                );
                final utilityButtons = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIconButton(
                      icon: Icons.copy_rounded,
                      tooltip: 'نسخ الآية',
                      onPressed: _copyVerse,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    AppIconButton(
                      icon: Icons.share_rounded,
                      tooltip: 'مشاركة',
                      onPressed: _shareVerse,
                    ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      positionButton,
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: utilityButtons,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: positionButton),
                    const SizedBox(width: AppSpace.sm),
                    utilityButtons,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
