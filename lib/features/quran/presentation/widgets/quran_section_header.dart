import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/utils/arabic_digits.dart' show getArabicJuzName;

/// Authentic Medina Mushaf Surah Header Banner
class MushafSurahBanner extends StatelessWidget {
  final int surahNumber;
  final MushafThemeMode themeMode;

  const MushafSurahBanner({
    super.key,
    required this.surahNumber,
    required this.themeMode,
  });

  static const String _bannerAsset = 'assets/surah_banner.png';
  static const AssetImage _assetImage = AssetImage(
    _bannerAsset,
    package: 'qcf_quran_plus',
  );

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final verseCount = quran.getVerseCount(surahNumber);
    final isMakki = quran.getPlaceOfRevelation(surahNumber) == 'Makkah';
    final revelationType = isMakki ? 'مَكِّيَّةٌ' : 'مَدَنِيَّةٌ';
    final surahName = quran.getSurahNameArabic(surahNumber);

    final Color textColor = switch (themeMode) {
      MushafThemeMode.white => MushafColors.whiteText,
      MushafThemeMode.sepia => MushafColors.sepiaText,
      MushafThemeMode.dark => MushafColors.darkBannerText,
    };

    final Color? frameColor = MushafColors.bannerFrameTint(themeMode);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        width: 380,
        height: 48,
        margin: const EdgeInsetsDirectional.only(
          top: AppSpace.xs,
          bottom: AppSpace.xs,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Authentic King Fahd Complex Medina Mushaf Ornamental Frame
            Image(
              image: const ResizeImage(
                _assetImage,
                width: 1024,
                allowUpscaling: false,
              ),
              width: 380,
              height: 48,
              fit: BoxFit.fill,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              color: frameColor,
              colorBlendMode: frameColor != null ? BlendMode.srcIn : BlendMode.srcOver,
            ),

            // 2. Classical Medina Cartouche Metadata and Authentic Calligraphic Title
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Right in RTL: Ayah count with high contrast plaque
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (themeMode == MushafThemeMode.dark
                              ? palette.surfaceRaised
                              : Colors.white)
                          .withValues(alpha: 0.90),
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: palette.gold.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      'آيَاتُهَا $verseCount',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: textTheme.caption.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),

                  // Center: Authentic Sacred Surah Name
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xs),
                          child: Text(
                            'سُورَةُ $surahName',
                            textAlign: TextAlign.center,
                            style: textTheme.sacred.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Left in RTL: Revelation location with high contrast plaque
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (themeMode == MushafThemeMode.dark
                              ? palette.surfaceRaised
                              : Colors.white)
                          .withValues(alpha: 0.90),
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: palette.gold.withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      revelationType,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: textTheme.caption.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ornamental banner demarcating the entry into one of the 30 Quranic Juz.
class QuranJuzSectionHeader extends StatelessWidget {
  final int juzNumber;
  final MushafThemeMode themeMode;

  const QuranJuzSectionHeader({
    super.key,
    required this.juzNumber,
    this.themeMode = MushafThemeMode.white,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final palette = context.palette;
    final juzTitle = getArabicJuzName(juzNumber);

    Color bannerBg;
    Color borderColor;
    Color textColor;

    switch (themeMode) {
      case MushafThemeMode.white:
        bannerBg = MushafColors.whiteBannerBg;
        borderColor = MushafColors.whiteBannerBorder;
        textColor = MushafColors.whiteBannerText;
        break;
      case MushafThemeMode.sepia:
        bannerBg = MushafColors.sepiaBannerBg;
        borderColor = MushafColors.sepiaBannerBorder;
        textColor = MushafColors.sepiaBannerText;
        break;
      case MushafThemeMode.dark:
        bannerBg = MushafColors.darkBannerBg;
        borderColor = MushafColors.darkBannerBorder;
        textColor = MushafColors.darkBannerText;
        break;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.md),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: borderColor.withValues(alpha: 0.6), width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 1,
            color: borderColor.withValues(alpha: 0.6),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            '۞',
            style: textTheme.caption.copyWith(
              color: palette.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            juzTitle,
            style: textTheme.sacred.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            '۞',
            style: textTheme.caption.copyWith(
              color: palette.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Container(
            width: 24,
            height: 1,
            color: borderColor.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}

/// Authentic Medina Mushaf Calligraphic Basmalah
class QuranBasmalahBanner extends StatelessWidget {
  final int? surahNumber;
  final MushafThemeMode themeMode;
  final double fontSize;

  const QuranBasmalahBanner({
    super.key,
    this.surahNumber,
    this.themeMode = MushafThemeMode.white,
    this.fontSize = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    if (surahNumber == 9) {
      return const SizedBox.shrink();
    }

    final textTheme = context.text;
    final Color textColor = switch (themeMode) {
      MushafThemeMode.white => MushafColors.whiteText,
      MushafThemeMode.sepia => MushafColors.sepiaText,
      MushafThemeMode.dark => MushafColors.darkText,
    };

    // Authentic King Fahd Complex Uthman Taha Medina Basmalah calligraphy glyphs
    final String basmalahGlyphs =
        (surahNumber == 97 || surahNumber == 95) ? '齃𧻓𥳐龎' : '齃𧻓𥳐𥉉';

    return Container(
      margin: const EdgeInsetsDirectional.only(
        top: AppSpace.sm,
        bottom: AppSpace.xs,
      ),
      alignment: AlignmentDirectional.center,
      child: SizedBox(
        height: 36,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            basmalahGlyphs,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: textTheme.basmallahCalligraphy.copyWith(
              color: textColor,
              fontSize: 26,
            ),
          ),
        ),
      ),
    );
  }
}
