import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/quran_tafsir_service.dart';
import '../../data/services/tajweed_service.dart';

class AyahDetailsSheet extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final VoidCallback? onBookmarkChanged;

  const AyahDetailsSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    this.onBookmarkChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required int surahNumber,
    required int ayahNumber,
    VoidCallback? onBookmarkChanged,
  }) {
    return AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.88,
      builder: (_) => AyahDetailsSheet(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
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

  TafsirScholar _selectedScholar = TafsirScholar.muyassar;
  String _tafsirText = '';
  bool _loadingTafsir = true;
  bool _isBookmarked = false;
  bool _isPlayingAudio = false;

  static const String _kBookmarksKey = 'dashboard_fav_surahs';
  static const String _kLastSurahKey = 'dashboard_last_surah';
  static const String _kLastAyahKey = 'dashboard_last_ayah';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookmarkState();
    _fetchTafsir();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarkState() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_kBookmarksKey) ?? [];
    if (!mounted) return;
    setState(() {
      _isBookmarked = bookmarks.contains(widget.surahNumber.toString());
    });
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
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_kBookmarksKey) ?? [];
    final surahStr = widget.surahNumber.toString();

    if (!mounted) return;
    if (bookmarks.contains(surahStr)) {
      bookmarks.remove(surahStr);
      _isBookmarked = false;
      AppSnackbar.info(context, 'تمت إزالة السورة من المحفوظات');
    } else {
      bookmarks.add(surahStr);
      _isBookmarked = true;
      AppSnackbar.success(context, 'تمت إضافة السورة إلى المحفوظات');
    }

    await prefs.setStringList(_kBookmarksKey, bookmarks);
    if (!mounted) return;
    widget.onBookmarkChanged?.call();
    setState(() {});
  }

  Future<void> _saveAsLastRead() async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastSurahKey, widget.surahNumber);
    await prefs.setInt(_kLastAyahKey, widget.ayahNumber);
    if (!mounted) return;
    AppSnackbar.success(
      context,
      'تم حفظ سورة ${quran.getSurahNameArabic(widget.surahNumber)} الآية ${widget.ayahNumber} كآخر موضع قراءة',
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

  Future<void> _toggleAudio() async {
    HapticFeedback.mediumImpact();
    if (_isPlayingAudio) {
      await _audioService.stop();
      if (mounted) setState(() => _isPlayingAudio = false);
    } else {
      setState(() => _isPlayingAudio = true);
      await _audioService.playVerse(widget.surahNumber, widget.ayahNumber);
      if (mounted) {
        _audioService.playerStateStream.listen((state) {
          if (!mounted) return;
          if (state.processingState.name == 'completed') {
            setState(() => _isPlayingAudio = false);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    final juzNum = quran.getJuzNumber(widget.surahNumber, widget.ayahNumber);
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
          // Drag handle
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

          // Header
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
                        'الجزء $juzNum • صفحة ${quran.getPageNumber(widget.surahNumber, widget.ayahNumber)}',
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
                  tooltip: 'حفظ العلامة',
                  color: _isBookmarked ? palette.primary : palette.textMuted,
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

          // Scrollable Body
          Flexible(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpace.xl),
              children: [
                // 1. Tajweed-colored Ayah Card
                AppCard(
                  child: Column(
                    children: [
                      SelectableText.rich(
                        TextSpan(
                          children: TajweedService.buildTajweedSpans(
                            verseText,
                            baseStyle: textTheme.sacredLarge.copyWith(
                              color: palette.text,
                            ),
                            isTajweedEnabled: true,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.md),

                // 2. Tab Bar (Tafsir, Words, Recitation)
                TabBar(
                  controller: _tabController,
                  labelColor: palette.primary,
                  unselectedLabelColor: palette.textMuted,
                  indicatorColor: palette.primary,
                  indicatorWeight: 3,
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
                  ],
                ),

                const SizedBox(height: AppSpace.md),

                // 3. Tab Contents
                SizedBox(
                  height: 220,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTafsirTab(palette, textTheme),
                      _buildWordsTab(palette, textTheme),
                      _buildAudioTab(palette, textTheme),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.lg),

                // 4. Action Row (Save Last Read, Copy, Share)
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

  Widget _buildTafsirTab(AppPalette palette, AppTextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scholar selector chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: TafsirScholar.values.map((scholar) {
              final isSelected = _selectedScholar == scholar;
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
                child: ChoiceChip(
                  label: Text(
                    QuranTafsirService.getScholarName(scholar),
                    style: textTheme.caption.copyWith(
                      color: isSelected ? palette.onPrimary : palette.text,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: palette.primary,
                  backgroundColor: palette.surfaceMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.pillRadius,
                    side: BorderSide(
                      color: isSelected ? palette.primary : palette.border,
                    ),
                  ),
                  onSelected: (val) {
                    if (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedScholar = scholar);
                      _fetchTafsir();
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Expanded(
          child: _loadingTafsir
              ? const Column(
                  children: [
                    AppSkeleton(width: double.infinity, height: 20),
                    SizedBox(height: AppSpace.sm),
                    AppSkeleton(width: double.infinity, height: 20),
                    SizedBox(height: AppSpace.sm),
                    AppSkeleton(width: 200, height: 20),
                  ],
                )
              : Container(
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: palette.border),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      _tafsirText,
                      style: textTheme.body.copyWith(
                        color: palette.text,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildWordsTab(AppPalette palette, AppTextTheme textTheme) {
    final words = QuranTafsirService.getWordMeanings(
      widget.surahNumber,
      widget.ayahNumber,
    );

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: palette.border),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpace.sm),
        itemCount: words.length,
        separatorBuilder: (_, index) => Divider(
          height: 1,
          color: palette.border.withValues(alpha: 0.5),
        ),
        itemBuilder: (context, index) {
          final item = words[index];
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpace.xs,
              horizontal: AppSpace.sm,
            ),
            child: Row(
              children: [
                Text(
                  item.word,
                  style: textTheme.sacred.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    item.morphology ?? '',
                    style: textTheme.caption.copyWith(
                      color: palette.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAudioTab(AppPalette palette, AppTextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.record_voice_over_rounded,
                size: AppIcon.sm,
                color: palette.primary,
              ),
              const SizedBox(width: AppSpace.sm),
              DropdownButton<QuranReciter>(
                value: _audioService.selectedReciter,
                dropdownColor: palette.surfaceRaised,
                underline: const SizedBox.shrink(),
                items: QuranAudioService.reciters.map((r) {
                  return DropdownMenuItem<QuranReciter>(
                    value: r,
                    child: Text(
                      r.name,
                      style: textTheme.body.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _audioService.setSelectedReciter(val));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Center(
            child: FloatingActionButton(
              heroTag: 'ayah_audio_fab',
              backgroundColor: palette.primary,
              foregroundColor: palette.onPrimary,
              elevation: 0,
              onPressed: _toggleAudio,
              child: Icon(
                _isPlayingAudio
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: AppIcon.lg,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            _isPlayingAudio ? 'جاري الاستماع...' : 'انقر للاستماع للآية بصوت القارئ',
            style: textTheme.caption.copyWith(
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
