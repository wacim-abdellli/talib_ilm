import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import '../../../../app/theme/theme_colors.dart';

/// Authentic Islamic 8-pointed star (Rub el Hizb) medallion for Surah numbers
class SurahNumberMedallion extends StatelessWidget {
  final int number;
  final double size;

  const SurahNumberMedallion({
    super.key,
    required this.number,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final gold = context.goldColor;
    final isDark = context.isDark;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotated outer square (45 deg)
          Transform.rotate(
            angle: 0.785398, // 45 degrees
            child: Container(
              width: size * 0.72,
              height: size * 0.72,
              decoration: BoxDecoration(
                color: gold.withValues(alpha: isDark ? 0.08 : 0.06),
                borderRadius: BorderRadius.circular(size * 0.14),
                border: Border.all(
                  color: gold.withValues(alpha: isDark ? 0.35 : 0.28),
                  width: 1.1,
                ),
              ),
            ),
          ),
          // Inner upright square
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              color: gold.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(size * 0.14),
              border: Border.all(
                color: gold.withValues(alpha: isDark ? 0.45 : 0.35),
                width: 1.1,
              ),
            ),
          ),
          // Center Surah number
          Text(
            '$number',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: size * 0.32,
              fontWeight: FontWeight.w800,
              color: gold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ornate Surah card conforming to Spiritual Serenity design system
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
    final isDark = context.isDark;
    final cardColor = context.surfaceContainer;
    final textColor = context.textPrimaryColor;
    final mutedColor = context.textSecondaryColor;
    final accentColor = context.goldColor;
    final surahName = quran.getSurahNameArabic(surahNumber);
    final versesCount = quran.getVerseCount(surahNumber);
    final place = quran.getPlaceOfRevelation(surahNumber);
    final isMakki = place == 'Makkah';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.outlineColor.withValues(
            alpha: isDark ? 0.12 : 0.08,
          ),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.16 : 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Ornate 8-pointed star medallion
                SurahNumberMedallion(number: surahNumber),
                const SizedBox(width: 16),

                // Surah Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'سورة $surahName',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              height: 1.25,
                            ),
                          ),
                          const Spacer(),
                          // Transliteration name
                          Text(
                            quran.getSurahName(surahNumber),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Makkah / Madinah badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (isMakki
                                      ? context.islamicGreenColor
                                      : accentColor)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isMakki ? 'مكية' : 'مدنية',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isMakki
                                    ? context.islamicGreenColor
                                    : accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Verse count
                          Text(
                            '$versesCount آية',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Trailing Action (Bookmark or custom)
                trailing ??
                    IconButton(
                      icon: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: isBookmarked ? accentColor : mutedColor,
                        size: 22,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onBookmarkTap();
                      },
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
