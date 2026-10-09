import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';

/// Authentic Islamic 8-pointed star (Rub el Hizb) medallion for Surah numbers
class SurahNumberMedallion extends StatelessWidget {
  final int number;
  final double size;

  const SurahNumberMedallion({
    super.key,
    required this.number,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

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
                color: palette.goldSoft,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: palette.gold.withValues(alpha: 0.3),
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
              color: palette.goldSoft,
              borderRadius: AppRadius.smRadius,
              border: Border.all(
                color: palette.gold.withValues(alpha: 0.4),
                width: 1.1,
              ),
            ),
          ),
          // Center Surah number
          Padding(
            padding: const EdgeInsets.all(AppSpace.xs),
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
        ],
      ),
    );
  }
}

/// Ornate Surah card conforming to Calm Scholar design system
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
            // Ornate 8-pointed star medallion
            SurahNumberMedallion(number: surahNumber),
            const SizedBox(width: AppSpace.lg),

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
                          style: context.text.sacred.copyWith(
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
                  const SizedBox(height: AppSpace.xs),
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Makkah / Madinah badge
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isMakki
                              ? palette.primarySoft
                              : palette.goldSoft,
                          borderRadius: AppRadius.smRadius,
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
                      // Verse count
                      Text(
                        '$versesCount آية',
                        style: context.text.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpace.sm),

            // Trailing Action (Bookmark or custom)
            trailing ??
                AppIconButton(
                  icon: isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  tooltip: isBookmarked
                      ? 'إزالة من المحفوظات'
                      : 'إضافة للمحفوظات',
                  color: isBookmarked ? palette.gold : palette.textMuted,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onBookmarkTap();
                  },
                ),
          ],
        ),
      ),
    );
  }
}
