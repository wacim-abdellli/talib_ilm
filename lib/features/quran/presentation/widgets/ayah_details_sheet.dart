import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:share_plus/share_plus.dart';

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

  const AyahDetailsSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    this.initialTafsirScholar,
    this.onBookmarkChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required int surahNumber,
    required int ayahNumber,
    TafsirScholar? initialTafsirScholar,
    VoidCallback? onBookmarkChanged,
  }) {
    return AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.92,
      builder: (_) => AyahDetailsSheet(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        initialTafsirScholar: initialTafsirScholar,
        onBookmarkChanged: onBookmarkChanged,
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

  @override
  void initState() {
    super.initState();
    _selectedScholar =
        widget.initialTafsirScholar ?? TafsirScholar.muyassar;
    _tabController = TabController(length: 4, vsync: this);
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
    final current = bookmarks.where(
      (b) => b.surah == widget.surahNumber && b.ayah == widget.ayahNumber,
    );

    if (!mounted) return;
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
    final note = _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null;
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
    await BookmarkService.updateNote(
      widget.surahNumber,
      widget.ayahNumber,
      note.isNotEmpty ? note : null,
    );
    if (!mounted) return;
    setState(() => _isBookmarked = true);
    widget.onBookmarkChanged?.call();
    AppSnackbar.success(context, 'تم حفظ الملاحظة والتدبر بنجاح');
  }

  Future<void> _saveAsLastRead() async {
    HapticFeedback.selectionClick();
    final page = quran.getPageNumber(widget.surahNumber, widget.ayahNumber);
    await BookmarkService.saveLastRead(
      surah: widget.surahNumber,
      ayah: widget.ayahNumber,
      page: page,
    );
    if (!mounted) return;
    AppSnackbar.success(
      context,
      'تم حفظ موضع القراءة (سورة ${quran.getSurahNameArabic(widget.surahNumber)} الآية ${widget.ayahNumber})',
    );
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
    await Share.share('﴿$verse﴾ [$surahName: ${widget.ayahNumber}]');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    final juzNum = quran.getJuzNumber(widget.surahNumber, widget.ayahNumber);
    final pageNum = quran.getPageNumber(widget.surahNumber, widget.ayahNumber);
    final verseText = quran.getVerse(
      widget.surahNumber,
      widget.ayahNumber,
      verseEndSymbol: true,
    );

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
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xl),
            child: Row(
              children: [
                const IconBadge(icon: Icons.menu_book_rounded),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سورة $surahName • الآية ${widget.ayahNumber}',
                        style: textTheme.titleSmall.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'الجزء $juzNum • الصفحة $pageNum',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
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

          const SizedBox(height: AppSpace.sm),
          Divider(height: 1, color: palette.border),

          Flexible(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsetsDirectional.all(AppSpace.xl),
              children: [
                AppCard(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: SelectableText.rich(
                      TextSpan(
                        children: TajweedService.buildVerseSpans(
                          plainUthmani: verseText,
                          quranComMarkup: _tajweedMarkup,
                          baseStyle: textTheme.sacredLarge.copyWith(
                            color: palette.text,
                            height: 1.8,
                          ),
                          isTajweedEnabled: true,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpace.md),

                Container(
                  padding: const EdgeInsetsDirectional.all(AppSpace.xxs),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(color: palette.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
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

                const SizedBox(height: AppSpace.md),

                SizedBox(
                  height: 280,
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
                      AyahAudioTabView(
                        surahNumber: widget.surahNumber,
                        ayahNumber: widget.ayahNumber,
                        audioService: _audioService,
                      ),
                      AyahNotesTabView(
                        noteController: _noteController,
                        onSaveNote: _saveNote,
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.lg),

                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'حفظ كموضع قراءة',
                        icon: Icons.bookmark_rounded,
                        onPressed: _saveAsLastRead,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
