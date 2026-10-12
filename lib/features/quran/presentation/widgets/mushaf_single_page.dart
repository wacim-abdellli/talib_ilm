import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qcf_quran/qcf_quran.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/utils/arabic_digits.dart' show getArabicJuzName;
import '../utils/mushaf_verse_gestures.dart';

import 'quran_section_header.dart';
export 'quran_section_header.dart';

/// A complete, authentic King Fahd Complex Medina Mushaf single page
class MushafSinglePage extends StatefulWidget {
  final int pageNumber;
  final MushafThemeMode themeMode;
  final bool isTajweedEnabled;
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
  final MushafVerseRecognizerPool _recognizers = MushafVerseRecognizerPool();

  @override
  void dispose() {
    _recognizers.dispose();
    super.dispose();
  }

  Color _getPageBg(MushafThemeMode themeMode) => MushafColors.bgFor(themeMode);

  Color _getVerseTextColor(MushafThemeMode themeMode) => MushafColors.textFor(themeMode);

  Color _getVerseNumberColor(MushafThemeMode themeMode) => MushafColors.verseNumberFor(themeMode);

  Color _getBorderColor(MushafThemeMode themeMode) => MushafColors.bannerBorderFor(themeMode);

  void _openAyah(int surah, int ayah) {
    HapticFeedback.selectionClick();
    widget.onAyahTap?.call(surah, ayah);
  }

  void _openAyahLongPress(int surah, int ayah) {
    HapticFeedback.mediumImpact();
    if (widget.onAyahLongPress != null) {
      widget.onAyahLongPress!(surah, ayah);
    } else {
      _openAyah(surah, ayah);
    }
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

    final ranges = getPageData(pageNumber);
    final firstSurah = ranges.isNotEmpty ? int.parse(ranges.first['surah'].toString()) : 1;
    final firstAyah = ranges.isNotEmpty ? int.parse(ranges.first['start'].toString()) : 1;
    final juzNumber = quran.getJuzNumber(firstSurah, firstAyah);
    final surahName = quran.getSurahNameArabic(firstSurah);
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
              padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.md),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: borderColor.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                children: [
                    Text(
                    'سُورَةُ $surahName',
                    style: textTheme.mushafChrome.copyWith(
                      color: verseTextColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '۞',
                    style: textTheme.caption.copyWith(
                      color: palette.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    juzName,
                    style: textTheme.mushafChrome.copyWith(
                      color: verseTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Middle Mushaf Page Content (QCF only — no greedy tap wrapper; PageView owns horizontal drag)
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.sm),
              child: Center(
                child: _buildQcfPage(
                  context,
                  ranges,
                  verseTextColor,
                  verseNumColor,
                  palette,
                ),
              ),
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

  Widget _buildQcfPage(
    BuildContext context,
    List ranges,
    Color verseTextColor,
    Color verseNumColor,
    AppPalette palette,
  ) {
    final pageNumber = widget.pageNumber;
    final themeMode = widget.themeMode;
    final pageFont = "QCF_P${pageNumber.toString().padLeft(3, '0')}";
    final baseFontSize = getFontSize(pageNumber, context);
    final verseSpans = <InlineSpan>[];

    for (final r in ranges) {
      final surah = int.parse(r['surah'].toString());
      final start = int.parse(r['start'].toString());
      final end = int.parse(r['end'].toString());

      for (int v = start; v <= end; v++) {
        if (v == start && v == 1) {
          verseSpans.add(
            WidgetSpan(
              child: MushafSurahBanner(
                surahNumber: surah,
                themeMode: themeMode,
              ),
            ),
          );

          if (pageNumber != 1 && pageNumber != 187) {
            verseSpans.add(
              WidgetSpan(
                child: QuranBasmalahBanner(
                  themeMode: themeMode,
                  fontSize: baseFontSize,
                ),
              ),
            );
          }
        }

        final isHighlighted =
            widget.activeSurah == surah && widget.activeAyah == v;
        final verseBg = isHighlighted ? palette.gold.withValues(alpha: 0.28) : null;

        final tapRecognizer = _recognizers.tap(
          surah: surah,
          ayah: v,
          onTap: () => _openAyah(surah, v),
        );
        final longPressRecognizer = _recognizers.longPress(
          surah: surah,
          ayah: v,
          onLongPress: () => _openAyahLongPress(surah, v),
        );

        final verseNumberSpan = TextSpan(
          text: getVerseNumberQCF(surah, v),
          recognizer: longPressRecognizer,
          style: TextStyle( // ui-lint: allow — per-page QCF package font
            fontFamily: pageFont,
            package: 'qcf_quran',
            color: verseNumColor,
            height: 1.35,
            backgroundColor: verseBg,
          ),
        );

        final verseText = v == ranges[0]['start']
            ? "${getVerseQCF(surah, v, verseEndSymbol: false).substring(0, 1)}\u200A${getVerseQCF(surah, v, verseEndSymbol: false).substring(1)}"
            : getVerseQCF(surah, v, verseEndSymbol: false);

        verseSpans.add(
          TextSpan(
            text: verseText,
            recognizer: tapRecognizer,
            style: TextStyle( // ui-lint: allow — dynamic highlight bg per verse
              backgroundColor: verseBg,
            ),
            children: [verseNumberSpan],
          ),
        );
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth - (AppSpace.md * 2);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: contentWidth,
        child: Text.rich(
          TextSpan(children: verseSpans),
          locale: const Locale('ar'),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle( // ui-lint: allow — per-page QCF package font
            fontFamily: pageFont,
            package: 'qcf_quran',
            fontSize: baseFontSize,
            color: verseTextColor,
            height: (pageNumber == 1 || pageNumber == 2) ? 2.2 : 2.05,
            letterSpacing: 0.0,
            wordSpacing: 0.0,
          ),
        ),
      ),
    );
  }
}
