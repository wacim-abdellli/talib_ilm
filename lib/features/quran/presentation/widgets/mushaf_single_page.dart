import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qcf_quran/qcf_quran.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../data/services/tajweed_service.dart';
import 'mushaf_settings_sheet.dart';

/// Helper to convert western digits to Arabic-Indic digits
String toArabicDigits(int number) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  final str = number.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    final code = str.codeUnitAt(i) - 48;
    if (code >= 0 && code <= 9) {
      buffer.write(digits[code]);
    } else {
      buffer.write(str[i]);
    }
  }
  return buffer.toString();
}

/// Helper to get formal Arabic Juz title
String getArabicJuzName(int juzNumber) {
  const juzNames = [
    'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس',
    'السادس', 'السابع', 'الثامن', 'التاسع', 'العاشر',
    'الحادي عشر', 'الثاني عشر', 'الثالث عشر', 'الرابع عشر', 'الخامس عشر',
    'السادس عشر', 'السابع عشر', 'الثامن عشر', 'التاسع عشر', 'العشرون',
    'الحادي والعشرون', 'الثاني والعشرون', 'الثالث والعشرون', 'الرابع والعشرون', 'الخامس والعشرون',
    'السادس والعشرون', 'السابع والعشرون', 'الثامن والعشرون', 'التاسع والعشرون', 'الثلاثون',
  ];
  if (juzNumber >= 1 && juzNumber <= 30) {
    return 'الجُزْءُ ${juzNames[juzNumber - 1]}';
  }
  return 'الجزء ${toArabicDigits(juzNumber)}';
}

/// Authentic Medina Mushaf Surah Header Banner
class MushafSurahBanner extends StatelessWidget {
  final int surahNumber;
  final MushafThemeMode themeMode;

  const MushafSurahBanner({
    super.key,
    required this.surahNumber,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final surahName = quran.getSurahNameArabic(surahNumber);
    final verseCount = quran.getVerseCount(surahNumber);
    final isMakki = quran.getPlaceOfRevelation(surahNumber) == 'Makkah';
    final revelationType = isMakki ? 'مَكِّيَّةٌ' : 'مَدَنِيَّةٌ';

    Color bannerBg;
    Color borderColor;
    Color textColor;
    Color subtextColor;

    switch (themeMode) {
      case MushafThemeMode.white:
        bannerBg = MushafColors.whiteBannerBg;
        borderColor = MushafColors.whiteBannerBorder;
        textColor = MushafColors.whiteBannerText;
        subtextColor = MushafColors.whiteBannerSubtext;
        break;
      case MushafThemeMode.sepia:
        bannerBg = MushafColors.sepiaBannerBg;
        borderColor = MushafColors.sepiaBannerBorder;
        textColor = MushafColors.sepiaBannerText;
        subtextColor = MushafColors.sepiaBannerSubtext;
        break;
      case MushafThemeMode.dark:
        bannerBg = MushafColors.darkBannerBg;
        borderColor = MushafColors.darkBannerBorder;
        textColor = MushafColors.darkBannerText;
        subtextColor = MushafColors.darkBannerSubtext;
        break;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.sm),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.smRadius,
          border: Border.all(
            color: borderColor.withValues(alpha: 0.45),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '۞',
                  style: textTheme.caption.copyWith(
                    color: borderColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Text(
                  'سُورَةُ $surahName',
                  style: textTheme.titleSmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Text(
                  '۞',
                  style: textTheme.caption.copyWith(
                    color: borderColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              'آيَاتُهَا ${toArabicDigits(verseCount)}  •  $revelationType',
              style: textTheme.caption.copyWith(
                color: subtextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A complete, authentic King Fahd Complex Medina Mushaf single page
class MushafSinglePage extends StatelessWidget {
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

  Color _getPageBg() {
    switch (themeMode) {
      case MushafThemeMode.white:
        return MushafColors.whiteBg;
      case MushafThemeMode.sepia:
        return MushafColors.sepiaBg;
      case MushafThemeMode.dark:
        return MushafColors.darkBg;
    }
  }

  Color _getVerseTextColor() {
    switch (themeMode) {
      case MushafThemeMode.white:
        return MushafColors.whiteText;
      case MushafThemeMode.sepia:
        return MushafColors.sepiaText;
      case MushafThemeMode.dark:
        return MushafColors.darkText;
    }
  }

  Color _getVerseNumberColor() {
    switch (themeMode) {
      case MushafThemeMode.white:
        return MushafColors.whiteVerseNumber;
      case MushafThemeMode.sepia:
        return MushafColors.sepiaVerseNumber;
      case MushafThemeMode.dark:
        return MushafColors.darkVerseNumber;
    }
  }

  Color _getBorderColor() {
    switch (themeMode) {
      case MushafThemeMode.white:
        return MushafColors.whiteBannerBorder;
      case MushafThemeMode.sepia:
        return MushafColors.sepiaBannerBorder;
      case MushafThemeMode.dark:
        return MushafColors.darkBannerBorder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final pageBg = _getPageBg();
    final verseTextColor = _getVerseTextColor();
    final verseNumColor = _getVerseNumberColor();
    final borderColor = _getBorderColor();

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
            onTap: onToggleOverlays,
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
                    style: textTheme.caption.copyWith(
                      color: verseTextColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Amiri',
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
                    style: textTheme.caption.copyWith(
                      color: verseTextColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Middle Mushaf Page Content
          Expanded(
            child: InkWell(
              onTap: onToggleOverlays,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.sm),
                child: Center(
                  child: isTajweedEnabled
                      ? _buildTajweedPage(context, ranges, verseTextColor, verseNumColor, palette)
                      : _buildQcfPage(context, ranges, verseTextColor, verseNumColor, palette),
                ),
              ),
            ),
          ),

          // 3. Classical Bottom Footer Bar (تذييل الصفحة)
          InkWell(
            onTap: onToggleOverlays,
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
                  'ـ ${toArabicDigits(pageNumber)} ـ',
                  style: textTheme.caption.copyWith(
                    color: verseNumColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
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
              TextSpan(
                text: " \uFBD3   \uFBD4\uFBD5\uFBD6\n",
                style: TextStyle(
                  fontFamily: "QCF_P001",
                  package: 'qcf_quran',
                  fontSize: 22.0,
                  color: verseTextColor,
                ),
              ),
            );
          }
        }

        final isHighlighted = activeSurah == surah && activeAyah == v;
        final verseBg = isHighlighted ? palette.gold.withValues(alpha: 0.28) : null;

        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            HapticFeedback.selectionClick();
            onAyahTap?.call(surah, v);
          };

        final verseNumberSpan = TextSpan(
          text: getVerseNumberQCF(surah, v),
          style: TextStyle(
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
            recognizer: recognizer,
            style: TextStyle(
              backgroundColor: verseBg,
            ),
            children: [verseNumberSpan],
          ),
        );
      }
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(children: verseSpans),
        locale: const Locale('ar'),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: pageFont,
          package: 'qcf_quran',
          fontSize: baseFontSize,
          color: verseTextColor,
          height: (pageNumber == 1 || pageNumber == 2) ? 2.2 : 2.05,
          letterSpacing: 0.0,
          wordSpacing: 0.0,
        ),
      ),
    );
  }

  Widget _buildTajweedPage(
    BuildContext context,
    List ranges,
    Color verseTextColor,
    Color verseNumColor,
    AppPalette palette,
  ) {
    final textTheme = context.text;
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
              TextSpan(
                text: 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ\n',
                style: textTheme.sacred.copyWith(
                  color: verseTextColor,
                  fontSize: 20.0,
                  height: 2.0,
                ),
              ),
            );
          }
        }

        final isHighlighted = activeSurah == surah && activeAyah == v;
        final verseBg = isHighlighted ? palette.gold.withValues(alpha: 0.28) : null;
        final verseRawText = quran.getVerse(surah, v, verseEndSymbol: false);

        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            HapticFeedback.selectionClick();
            onAyahTap?.call(surah, v);
          };

        final baseStyle = textTheme.sacred.copyWith(
          color: verseTextColor,
          fontSize: 18.5,
          height: 2.1,
          backgroundColor: verseBg,
        );

        final tajweedSpans = TajweedService.buildTajweedSpans(
          verseRawText,
          baseStyle: baseStyle,
          isTajweedEnabled: true,
        );

        // Add verse end symbol
        final endSymbolSpan = TextSpan(
          text: ' ﴿${toArabicDigits(v)}﴾ ',
          recognizer: recognizer,
          style: textTheme.caption.copyWith(
            color: verseNumColor,
            fontWeight: FontWeight.bold,
            fontSize: 14.0,
            backgroundColor: verseBg,
          ),
        );

        verseSpans.addAll(tajweedSpans.map((s) => TextSpan(
          text: s.text,
          recognizer: recognizer,
          style: s.style?.copyWith(backgroundColor: verseBg),
        )));
        verseSpans.add(endSymbolSpan);
      }
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(children: verseSpans),
        locale: const Locale('ar'),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
