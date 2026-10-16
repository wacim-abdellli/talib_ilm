import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import 'surah_card.dart';

/// Minimalist Juz tile modeled after classical Madinah Mushaf index.
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: AppRadius.mdRadius,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: palette.border.withValues(alpha: 0.45),
                width: 0.6,
              ),
            ),
          ),
          child: Row(
            children: [
              // Clean medallion
              SurahNumberMedallion(number: juzNumber),
              const SizedBox(width: AppSpace.md),

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
                            vertical: AppSpace.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: palette.goldSoft,
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(
                              color: palette.gold.withValues(alpha: 0.25),
                              width: 0.7,
                            ),
                          ),
                          child: Text(
                            'ص $pageNumber',
                            style: context.text.caption.copyWith(
                              color: palette.gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xxs + 1),
                    Text(
                      '«$verseSnippet»',
                      style: context.text.sacred.copyWith(
                        color: palette.gold,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
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

              const SizedBox(width: AppSpace.xs),

              // Trailing arrow
              Icon(
                Icons.chevron_left_rounded,
                size: AppIcon.md,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
