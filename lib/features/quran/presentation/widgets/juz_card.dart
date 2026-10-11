import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import 'surah_card.dart';

/// Authentic Juz card modeled after classical Madinah Mushaf index (Wahi style).
class JuzCard extends StatelessWidget {
  final int juzNumber;
  final VoidCallback onTap;

  const JuzCard({
    super.key,
    required this.juzNumber,
    required this.onTap,
  });

  static const List<String> juzNames = [
    'الجزء الأول',
    'الجزء الثاني',
    'الجزء الثالث',
    'الجزء الرابع',
    'الجزء الخامس',
    'الجزء السادس',
    'الجزء السابع',
    'الجزء الثامن',
    'الجزء التاسع',
    'الجزء العاشر',
    'الجزء الحادي عشر',
    'الجزء الثاني عشر',
    'الجزء الثالث عشر',
    'الجزء الرابع عشر',
    'الجزء الخامس عشر',
    'الجزء السادس عشر',
    'الجزء السابع عشر',
    'الجزء الثامن عشر',
    'الجزء التاسع عشر',
    'الجزء العشرون',
    'الجزء الحادي والعشرون',
    'الجزء الثاني والعشرون',
    'الجزء الثالث والعشرون',
    'الجزء الرابع والعشرون',
    'الجزء الخامس والعشرون',
    'الجزء السادس والعشرون',
    'الجزء السابع والعشرون',
    'الجزء الثامن والعشرون',
    'الجزء التاسع والعشرون',
    'الجزء الثلاثون',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final map = quran.getSurahAndVersesFromJuz(juzNumber);
    final firstSurah = map.keys.first;
    final firstVerse = map[firstSurah]!.first;
    final pageNumber = quran.getPageNumber(firstSurah, firstVerse);
    final surahName = quran.getSurahNameArabic(firstSurah);
    final verseSnippet = quran.getVerse(firstSurah, firstVerse, verseEndSymbol: false);
    final juzLabel = (juzNumber >= 1 && juzNumber <= 30)
        ? juzNames[juzNumber - 1]
        : 'الجزء $juzNumber';

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
      child: AppCard(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: Row(
          children: [
            // Ornate Juz Medallion
            SurahNumberMedallion(number: juzNumber),
            const SizedBox(width: AppSpace.lg),

            // Juz information
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        juzLabel,
                        style: context.text.titleSmall.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: AppSpace.xs,
                        ),
                        decoration: BoxDecoration(
                          color: palette.goldSoft,
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Text(
                          'صفحة $pageNumber',
                          style: context.text.caption.copyWith(
                            color: palette.onGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  // Opening Ayah snippet
                  Text(
                    '«$verseSnippet»',
                    style: context.text.sacred.copyWith(
                      color: palette.gold,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  // Starting Surah and Verse
                  Text(
                    'بداية سورة $surahName • آية $firstVerse',
                    style: context.text.caption.copyWith(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Trailing arrow icon
            Icon(
              Icons.arrow_back_ios_new_rounded,
              size: AppIcon.sm,
              color: palette.gold,
            ),
          ],
        ),
      ),
    );
  }
}
