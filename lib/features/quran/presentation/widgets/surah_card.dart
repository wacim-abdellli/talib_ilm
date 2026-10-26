import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';

/// Ornate Islamic medallion for Surah numbers with double concentric border rings.
class SurahNumberMedallion extends StatelessWidget {
  final int number;
  final double size;

  const SurahNumberMedallion({
    super.key,
    required this.number,
    this.size = 42,
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
          width: 1.2,
        ),
      ),
      child: Container(
        width: size - AppSpace.sm,
        height: size - AppSpace.sm,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: palette.gold.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpace.xxs),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$number',
              style: context.text.labelHeavy.copyWith(
                color: palette.gold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Distinct, scholarly badge for Makkah vs Madinah revelations with authentic iconography and colors.
class _RevelationBadge extends StatelessWidget {
  final bool isMakki;

  const _RevelationBadge({required this.isMakki});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = isMakki ? palette.gold : palette.success;
    final bg = isMakki ? palette.goldSoft : palette.success.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMakki ? Icons.crop_square_rounded : Icons.brightness_3_rounded,
            size: AppIcon.xs,
            color: color,
          ),
          const SizedBox(width: AppSpace.xxs),
          Text(
            isMakki ? 'مكية' : 'مدنية',
            style: context.text.captionHeavy.copyWith(
              color: color,
            ),
          ),
        ],
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
    final juzNumber = quran.getJuzNumber(surahNumber, 1);

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
              // Ornate Islamic medallion
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Row(
                      children: [
                        // Distinct Revelation badge (مكية / مدنية)
                        _RevelationBadge(isMakki: isMakki),
                        const SizedBox(width: AppSpace.sm),
                        // Juz number, Verses and page count
                        Flexible(
                          child: Text(
                            'الجزء $juzNumber • $versesCount آية • ص $startPage',
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
                      size: AppIcon.md,
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
