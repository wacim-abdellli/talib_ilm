import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../core/utils/arabic_digits.dart'
    show getArabicJuzName, getVocalizedSurahName;

import 'quran_section_header.dart';
export 'quran_section_header.dart';

class _PageMeta {
  final String vocalizedSurahName;
  final String juzName;
  const _PageMeta({required this.vocalizedSurahName, required this.juzName});
}

final Map<int, _PageMeta> _pageMetaCache = <int, _PageMeta>{};

_PageMeta _getPageMeta(int pageNumber) {
  final cached = _pageMetaCache[pageNumber];
  if (cached != null) return cached;

  final ranges = getPageData(pageNumber);
  final firstSurah =
      ranges.isNotEmpty ? int.parse(ranges.first['surah'].toString()) : 1;
  final firstAyah =
      ranges.isNotEmpty ? int.parse(ranges.first['start'].toString()) : 1;
  final juzNumber = quran.getJuzNumber(firstSurah, firstAyah);
  final surahName = quran.getSurahNameArabic(firstSurah);
  final vocalized = getVocalizedSurahName(firstSurah, fallback: surahName);
  final juz = getArabicJuzName(juzNumber);

  final meta = _PageMeta(vocalizedSurahName: vocalized, juzName: juz);
  _pageMetaCache[pageNumber] = meta;
  return meta;
}

/// A complete, authentic King Fahd Complex Medina Mushaf single page
/// rendered using [qcf_quran_plus] with Uthmani Tajweed font support.
class MushafSinglePage extends StatefulWidget {
  final int pageNumber;
  final MushafThemeMode themeMode;
  final bool isTajweedEnabled;
  final double fontSize;
  final int? activeSurah;
  final int? activeAyah;
  final void Function(int surah, int ayah)? onAyahTap;
  final void Function(int surah, int ayah)? onAyahLongPress;
  final VoidCallback? onToggleOverlays;

  const MushafSinglePage({
    super.key,
    required this.pageNumber,
    required this.themeMode,
    required this.isTajweedEnabled,
    this.fontSize = 24.0,
    this.activeSurah,
    this.activeAyah,
    this.onAyahTap,
    this.onAyahLongPress,
    this.onToggleOverlays,
  });

  @override
  State<MushafSinglePage> createState() => _MushafSinglePageState();
}

class _MushafSinglePageState extends State<MushafSinglePage> {
  static final PageController _sharedController = PageController();


  Color _getPageBg(MushafThemeMode themeMode) => MushafColors.bgFor(themeMode);

  Color _getVerseTextColor(MushafThemeMode themeMode) => MushafColors.textFor(themeMode);

  Color _getVerseNumberColor(MushafThemeMode themeMode) => MushafColors.verseNumberFor(themeMode);

  Color _getBorderColor(MushafThemeMode themeMode) => MushafColors.bannerBorderFor(themeMode);



  void _openAyah(int surah, int ayah) {
    if (widget.onAyahTap != null) {
      widget.onAyahTap!(surah, ayah);
    } else {
      widget.onToggleOverlays?.call();
    }
  }

  void _openAyahLongPress(int surah, int ayah) {
    HapticFeedback.mediumImpact();
    widget.onAyahLongPress?.call(surah, ayah);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final themeMode = widget.themeMode;
    final pageNumber = widget.pageNumber;
    final pageBg = _getPageBg(themeMode);
    final verseTextColor = _getVerseTextColor(themeMode);
    final verseNumColor = _getVerseNumberColor(themeMode);
    final borderColor = _getBorderColor(themeMode);
    final meta = _getPageMeta(pageNumber);

    return Container(
      color: pageBg,
      child: Column(
        children: [
          // 1. Classical Top Header Bar (ترويسة الصفحة)
          InkWell(
            onTap: widget.onToggleOverlays,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Container(
              height: 38,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.sm),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: borderColor.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PositionedDirectional(
                    start: 0,
                    child: Text(
                      meta.vocalizedSurahName,
                      style: textTheme.mushafChrome.copyWith(
                        color: verseTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Center(
                    child: Text(
                      '۞',
                      style: textTheme.caption.copyWith(
                        color: palette.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: 0,
                    child: Text(
                      meta.juzName,
                      style: textTheme.mushafChrome.copyWith(
                        color: verseTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Middle Mushaf Page Content with Tajweed font rendering
          Expanded(
            child: InkWell(
              onTap: widget.onToggleOverlays,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: _buildQcfPlusPage(context, palette),
            ),
          ),

          // 3. Classical Bottom Footer Bar (تذييل الصفحة)
          InkWell(
            onTap: widget.onToggleOverlays,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Container(
              height: 34,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: borderColor.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  'ـ $pageNumber ـ',
                  style: textTheme.mushafChrome.copyWith(
                    color: verseNumColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQcfPlusPage(BuildContext context, AppPalette palette) {
    if (!QuranRepository.instance.isReady) {
      return FutureBuilder<void>(
        future: QuranRepository.instance.ensureLoaded(604),
        builder: (context, snapshot) {
          if (!QuranRepository.instance.isReady) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildPageWidget(context, palette);
        },
      );
    }

    return _buildPageWidget(context, palette);
  }

  Widget _buildPageWidget(BuildContext context, AppPalette palette) {
    final pageNumber = widget.pageNumber;
    final themeMode = widget.themeMode;
    final pageIndex = pageNumber - 1;
    final pages = QuranRepository.instance.pages;
    if (pageIndex < 0 || pageIndex >= pages.length) {
      return const SizedBox.shrink();
    }

    final page = pages[pageIndex];
    final wordOffsets = QuranRepository.instance.wordOffsets[pageIndex] ?? const {};

    BookmarkIndex bookmarkIndex = BookmarkIndex.empty;
    if (widget.activeSurah != null && widget.activeAyah != null) {
      bookmarkIndex = BookmarkIndex.build([
        HighlightVerse(
          surah: widget.activeSurah!,
          verseNumber: widget.activeAyah!,
          page: pageNumber,
          color: palette.gold.withValues(alpha: 0.28),
        ),
      ]);
    }

    return RepaintBoundary(
      child: QuranSinglePageWidget(
        key: ValueKey('qcf_plus_page_$pageNumber'),
        page: page,
        pageIndex: pageNumber,
        isTajweed: widget.isTajweedEnabled,
        isDark: themeMode == MushafThemeMode.dark,
        pageController: _sharedController,
        lineOffsets: wordOffsets,
        wordHighlightIndex: WordHighlightIndex.empty,
        bookmarkIndex: bookmarkIndex,
        onWordTap: (surah, ayah, wordIdx, word) => _openAyah(surah, ayah),
        onLongPress: (surah, ayah, details) => _openAyahLongPress(surah, ayah),
        surahHeaderBuilder: (context, surah) => MushafSurahBanner(
          surahNumber: surah,
          themeMode: themeMode,
        ),
        basmallahBuilder: (context, surah) => QuranBasmalahBanner(
          surahNumber: surah,
          themeMode: themeMode,
        ),
        forceFitConstraints: false,
      ),
    );
  }
}
