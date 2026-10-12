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

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        width: 380,
        margin: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.xxs),
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
            vertical: AppSpace.xxs,
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
                    style: textTheme.sacred.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
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
                'آيَاتُهَا $verseCount  •  $revelationType',
                style: textTheme.caption.copyWith(
                  color: subtextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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

/// Calligraphic Basmalah banner preceding Surah verses.
class QuranBasmalahBanner extends StatelessWidget {
  final MushafThemeMode themeMode;
  final double fontSize;

  const QuranBasmalahBanner({
    super.key,
    this.themeMode = MushafThemeMode.white,
    this.fontSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    Color textColor;
    switch (themeMode) {
      case MushafThemeMode.white:
        textColor = MushafColors.whiteText;
        break;
      case MushafThemeMode.sepia:
        textColor = MushafColors.sepiaText;
        break;
      case MushafThemeMode.dark:
        textColor = MushafColors.darkText;
        break;
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.xxs),
        alignment: AlignmentDirectional.center,
        child: Text(
          quran.basmala,
          style: textTheme.sacredLarge.copyWith(
            color: textColor,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}
