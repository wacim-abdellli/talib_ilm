import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../data/models/mutashabih_card.dart';
import '../../data/services/quran_mutashabihat_service.dart';

/// Tab view displaying authentic Quranic similar verses (المتشابهات اللفظية),
/// memory mnemonics (الضوابط الحفظية), and rhetorical reasoning (التوجيه البلاغي).
class AyahSimilarTabView extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final void Function(int surah, int ayah)? onNavigateToVerse;

  const AyahSimilarTabView({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    this.onNavigateToVerse,
  });

  @override
  State<AyahSimilarTabView> createState() => _AyahSimilarTabViewState();
}

class _AyahSimilarTabViewState extends State<AyahSimilarTabView> {
  late Future<List<MutashabihCard>> _cardsFuture;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void didUpdateWidget(covariant AyahSimilarTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahNumber != widget.surahNumber ||
        oldWidget.ayahNumber != widget.ayahNumber) {
      _loadCards();
    }
  }

  void _loadCards() {
    _cardsFuture = QuranMutashabihatService.getSimilarVerses(
      surah: widget.surahNumber,
      ayah: widget.ayahNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return FutureBuilder<List<MutashabihCard>>(
      future: _cardsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: palette.gold,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  'جاري استخراج المتشابهات والضوابط الحفظية...',
                  style: textTheme.caption.copyWith(color: palette.textMuted),
                ),
              ],
            ),
          );
        }

        final cards = snapshot.data ?? const [];

        if (cards.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.all(AppSpace.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const IconBadge(icon: Icons.auto_awesome_rounded),
                  const SizedBox(height: AppSpace.md),
                  Text(
                    'آية فريدة في سياقها القرآني',
                    style: textTheme.titleSmall.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'لم تُسجل متشابهات لفظية متداخلة لهذه الآية الكريمة، وسياقها متفرد مبارك.',
                    style: textTheme.caption.copyWith(
                      color: palette.textMuted,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.sm),
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
          itemBuilder: (context, index) {
            final card = cards[index];
            return _MutashabihCardWidget(
              card: card,
              currentSurah: widget.surahNumber,
              currentAyah: widget.ayahNumber,
              onNavigateToVerse: widget.onNavigateToVerse,
            );
          },
        );
      },
    );
  }
}

class _MutashabihCardWidget extends StatelessWidget {
  final MutashabihCard card;
  final int currentSurah;
  final int currentAyah;
  final void Function(int surah, int ayah)? onNavigateToVerse;

  const _MutashabihCardWidget({
    required this.card,
    required this.currentSurah,
    required this.currentAyah,
    this.onNavigateToVerse,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge
          Row(
            children: [
              Icon(
                Icons.compare_arrows_rounded,
                size: AppIcon.sm,
                color: palette.gold,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                'مواضع المتشابهات (${card.places.length} مواضع)',
                style: textTheme.label.copyWith(
                  color: palette.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),

          // List of Places
          ...card.places.map((place) {
            final isCurrent =
                place.surah == currentSurah && place.ayah == currentAyah;
            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
              child: _PlaceTile(
                place: place,
                isCurrent: isCurrent,
                onTap: isCurrent
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        onNavigateToVerse?.call(place.surah, place.ayah);
                      },
              ),
            );
          }),

          // Rule / Mnemonic (الضابط الحفظي)
          if (card.rule != null && card.rule!.trim().isNotEmpty) ...[
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: palette.surfaceRaised,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: palette.gold.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_rounded,
                        size: AppIcon.xs,
                        color: palette.gold,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        'الضابط الحفظي للتمييز:',
                        style: textTheme.caption.copyWith(
                          color: palette.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    card.rule!,
                    style: textTheme.bodySmall.copyWith(
                      color: palette.text,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
          ],

          // Rhetoric / Reasoning (التوجيه البلاغي)
          if (card.rhetoric != null && card.rhetoric!.trim().isNotEmpty) ...[
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: palette.surfaceRaised,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: palette.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology_rounded,
                        size: AppIcon.xs,
                        color: palette.primary,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        'سر اختلاف اللفظ والتوجيه البلاغي:',
                        style: textTheme.caption.copyWith(
                          color: palette.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    card.rhetoric!,
                    style: textTheme.bodySmall.copyWith(
                      color: palette.text,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
          ],

          // Reference (المصدر)
          if (card.source != null && card.source!.trim().isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: AppIcon.xs,
                  color: palette.textMuted,
                ),
                const SizedBox(width: AppSpace.xxs),
                Expanded(
                  child: Text(
                    card.source!,
                    style: textTheme.caption.copyWith(
                      color: palette.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  final MutashabihPlace place;
  final bool isCurrent;
  final VoidCallback? onTap;

  const _PlaceTile({
    required this.place,
    required this.isCurrent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final surahName = quran.getSurahNameArabic(place.surah);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smRadius,
        child: Container(
          padding: const EdgeInsetsDirectional.all(AppSpace.sm),
          decoration: BoxDecoration(
            color: isCurrent
                ? palette.primary.withValues(alpha: 0.08)
                : palette.surfaceRaised,
            borderRadius: AppRadius.smRadius,
            border: Border.all(
              color: isCurrent
                  ? palette.primary.withValues(alpha: 0.4)
                  : palette.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                children: [
                  Icon(
                    isCurrent
                        ? Icons.my_location_rounded
                        : Icons.menu_book_rounded,
                    size: AppIcon.xs,
                    color: isCurrent ? palette.primary : palette.textMuted,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    'سورة $surahName • الآية ${place.ayah}',
                    style: textTheme.label.copyWith(
                      color: isCurrent ? palette.primary : palette.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.xs,
                        vertical: AppSpace.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: palette.primary.withValues(alpha: 0.15),
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Text(
                        'هذه الآية',
                        style: textTheme.caption.copyWith(
                          color: palette.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'انتقال',
                          style: textTheme.caption.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                        const SizedBox(width: AppSpace.xxs),
                        Icon(
                          Icons.chevron_left_rounded,
                          size: AppIcon.sm,
                          color: palette.textMuted,
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.xs),

              // Ayah text with highlighted matching phrase
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text.rich(
                  TextSpan(
                    children: _buildHighlightedSpans(
                      verseText: place.text.isNotEmpty
                          ? place.text
                          : quran.getVerse(
                              place.surah,
                              place.ayah,
                              verseEndSymbol: true,
                            ),
                      fromWord: place.fromWord,
                      toWord: place.toWord,
                      palette: palette,
                      textTheme: textTheme,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildHighlightedSpans({
    required String verseText,
    required int fromWord,
    required int toWord,
    required AppPalette palette,
    required dynamic textTheme,
  }) {
    final words = verseText.split(RegExp(r'\s+'));
    if (words.isEmpty) {
      return [TextSpan(text: verseText)];
    }

    final spans = <InlineSpan>[];
    var wordIndex = 0;

    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final isArabicWord = RegExp(r'[\u0600-\u06FF]').hasMatch(word);
      if (isArabicWord) {
        wordIndex++;
      }

      final isMatch = fromWord > 0 &&
          toWord >= fromWord &&
          wordIndex >= fromWord &&
          wordIndex <= toWord;

      spans.add(
        TextSpan(
          text: i == 0 ? word : ' $word',
          style: isMatch
              ? textTheme.sacred.copyWith(
                  color: palette.gold,
                  fontWeight: FontWeight.bold,
                  backgroundColor: palette.gold.withValues(alpha: 0.14),
                  height: 1.6,
                )
              : textTheme.sacred.copyWith(
                  color: palette.text,
                  height: 1.6,
                ),
        ),
      );
    }

    return spans;
  }
}
