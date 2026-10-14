import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../core/utils/arabic_digits.dart'
    show getArabicJuzName, getVocalizedSurahName;

import 'quran_section_header.dart';
export 'quran_section_header.dart';

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

class _MushafSinglePageState extends State<MushafSinglePage>
    with AutomaticKeepAliveClientMixin {
  static final PageController _sharedPageController = PageController();
  bool _isFontReady = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _isFontReady = QcfFontLoader.isFontLoaded(widget.pageNumber);
    if (!_isFontReady) {
      _checkAndLoadFont();
    }
  }

  @override
  void didUpdateWidget(covariant MushafSinglePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _isFontReady = QcfFontLoader.isFontLoaded(widget.pageNumber);
      if (!_isFontReady) {
        _checkAndLoadFont();
      }
    }
  }

  void _checkAndLoadFont() {
    final page = widget.pageNumber;
    if (QcfFontLoader.isFontLoaded(page)) {
      _isFontReady = true;
      return;
    }
    _isFontReady = false;
    QcfFontLoader.ensureFontLoaded(page).then((_) {
      if (mounted && widget.pageNumber == page) {
        setState(() {
          _isFontReady = true;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Color _getPageBg(MushafThemeMode themeMode) => MushafColors.bgFor(themeMode);

  Color _getVerseTextColor(MushafThemeMode themeMode) => MushafColors.textFor(themeMode);

  Color _getVerseNumberColor(MushafThemeMode themeMode) => MushafColors.verseNumberFor(themeMode);

  Color _getBorderColor(MushafThemeMode themeMode) => MushafColors.bannerBorderFor(themeMode);



  void _openAyahLongPress(int surah, int ayah) {
    HapticFeedback.mediumImpact();
    widget.onAyahLongPress?.call(surah, ayah);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final palette = context.palette;
    final textTheme = context.text;
    final themeMode = widget.themeMode;
    final pageNumber = widget.pageNumber;
    final pageBg = _getPageBg(themeMode);
    final verseTextColor = _getVerseTextColor(themeMode);
    final verseNumColor = _getVerseNumberColor(themeMode);
    final borderColor = _getBorderColor(themeMode);

    final ranges = getPageData(pageNumber);
    final firstSurah = ranges.isNotEmpty ? int.parse(ranges.first['surah'].toString()) : 1;
    final firstAyah = ranges.isNotEmpty ? int.parse(ranges.first['start'].toString()) : 1;
    final juzNumber = quran.getJuzNumber(firstSurah, firstAyah);
    final surahName = quran.getSurahNameArabic(firstSurah);
    final vocalizedSurahName = getVocalizedSurahName(firstSurah, fallback: surahName);
    final juzName = getArabicJuzName(juzNumber);

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
                      vocalizedSurahName,
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
                      juzName,
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
          if (!QuranRepository.instance.isReady || !_isFontReady) {
            return _buildFontLoadingPlaceholder(palette);
          }
          return _buildPageWidget(context, palette);
        },
      );
    }

    if (!_isFontReady && !QcfFontLoader.isFontLoaded(widget.pageNumber)) {
      return _buildFontLoadingPlaceholder(palette);
    }

    return _buildPageWidget(context, palette);
  }

  Widget _buildFontLoadingPlaceholder(AppPalette palette) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: AppSpace.xxl,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: palette.gold,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            'جاري إعداد الصفحة المباركة...',
            style: context.text.caption.copyWith(
              color: MushafColors.textFor(widget.themeMode).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
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

    return QuranSinglePageWidget(
      key: ValueKey('qcf_plus_page_$pageNumber'),
      page: page,
      pageIndex: pageNumber,
      isTajweed: widget.isTajweedEnabled,
      isDark: themeMode == MushafThemeMode.dark,
      pageController: _sharedPageController,
      lineOffsets: wordOffsets,
      wordHighlightIndex: WordHighlightIndex.empty,
      bookmarkIndex: bookmarkIndex,
      onWordTap: null, // Avoids ~200 TapGestureRecognizers and 15 timers per page; taps bubble to parent InkWell
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
    );
  }
}
