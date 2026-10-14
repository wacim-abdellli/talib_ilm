import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';

/// Clean, high-performance circular medallion for Surah, Juz, and Hizb numbers.
class SurahNumberMedallion extends StatelessWidget {
  final int number;
  final double size;

  const SurahNumberMedallion({
    super.key,
    required this.number,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.goldSoft,
        border: Border.all(
          color: palette.gold.withValues(alpha: 0.35),
          width: 1.1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpace.xxs),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$number',
            style: context.text.label.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.gold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimalist, high-performance Surah tile conforming to Calm Scholar design system.
class SurahCard extends StatelessWidget {
  final int surahNumber;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmarkTap;
  final Widget? trailing;

  const SurahCard({
    super.key,
    required this.surahNumber,
    required this.isBookmarked,
    required this.onTap,
    required this.onBookmarkTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final surahName = quran.getSurahNameArabic(surahNumber);
    final versesCount = quran.getVerseCount(surahNumber);
    final place = quran.getPlaceOfRevelation(surahNumber);
    final isMakki = place == 'Makkah';
    final startPage = quran.getSurahPages(surahNumber)[0];

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
            vertical: AppSpace.sm + 2,
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
              // Clean circular medallion
              SurahNumberMedallion(number: surahNumber),
              const SizedBox(width: AppSpace.md),

              // Surah Details
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'سورة $surahName',
                            style: context.text.titleSmall.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        // Transliteration name
                        Text(
                          quran.getSurahName(surahNumber),
                          style: context.text.caption.copyWith(
                            color: palette.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xxs + 1),
                    Row(
                      children: [
                        // Revelation badge (مكية / مدنية)
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.xs + 2,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: isMakki
                                ? palette.primarySoft
                                : palette.goldSoft,
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(
                              color: (isMakki ? palette.primary : palette.gold)
                                  .withValues(alpha: 0.25),
                              width: 0.7,
                            ),
                          ),
                          child: Text(
                            isMakki ? 'مكية' : 'مدنية',
                            style: context.text.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isMakki
                                  ? palette.onPrimarySoft
                                  : palette.gold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs + 2),
                        // Verses and page count
                        Flexible(
                          child: Text(
                            '$versesCount آية • ص $startPage',
                            style: context.text.caption.copyWith(
                              color: palette.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpace.xs),

              // Trailing Action (Bookmark or custom)
              trailing ??
                  IconButton(
                    icon: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isBookmarked ? palette.gold : palette.textMuted,
                      size: AppIcon.sm + 2,
                    ),
                    tooltip: isBookmarked
                        ? 'إزالة من المحفوظات'
                        : 'إضافة للمحفوظات',
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onBookmarkTap();
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
