import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/utils/arabic_search_utils.dart';
import '../../../../shared/widgets/app_card.dart';

/// Data class representing a matching Ayah in Quran word search.
class QuranAyahMatch {
  final int surahNumber;
  final int ayahNumber;
  final int pageNumber;
  final int juzNumber;
  final String surahName;
  final String verseText;
  final String query;

  const QuranAyahMatch({
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageNumber,
    required this.juzNumber,
    required this.surahName,
    required this.verseText,
    required this.query,
  });
}

/// Accessible, token-compliant card displaying an Ayah search match with query highlighting.
class QuranAyahSearchCard extends StatelessWidget {
  final QuranAyahMatch match;
  final VoidCallback onTap;

  const QuranAyahSearchCard({
    super.key,
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.xs,
      ),
      child: Semantics(
        button: true,
        label:
            'سورة ${match.surahName} آية ${match.ayahNumber} صفحة ${match.pageNumber}',
        child: AppCard(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          padding: const EdgeInsetsDirectional.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top metadata row
            Row(
              children: [
                // Ayah number badge
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: palette.goldSoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: palette.gold.withValues(alpha: 0.5),
                    ),
                  ),
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    '${match.ayahNumber}',
                    style: textTheme.caption.copyWith(
                      color: palette.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                // Surah name and location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سورة ${match.surahName}',
                        style: textTheme.titleSmall.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'صفحة ${match.pageNumber} • الجزء ${match.juzNumber}',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Open indicator pill
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.smRadius,
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'انتقال',
                        style: textTheme.captionBold.copyWith(
                          color: palette.gold,
                        ),
                      ),
                      const SizedBox(width: AppSpace.xxs),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: AppIcon.xs,
                        color: palette.gold,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            // Highlighted verse snippet
            _buildVerseSnippet(context),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildVerseSnippet(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final words = match.verseText.trim().split(RegExp(r'\s+'));
    final normalizedQuery = ArabicSearchUtils.normalize(match.query);

    final spans = <TextSpan>[];
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final isMatch = normalizedQuery.isNotEmpty &&
          ArabicSearchUtils.matches(word, normalizedQuery);

      spans.add(
        TextSpan(
          text: '$word ',
          style: textTheme.body.copyWith(
            color: isMatch ? palette.gold : palette.text,
            fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
            height: 1.8,
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      textDirection: TextDirection.rtl,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }
}
