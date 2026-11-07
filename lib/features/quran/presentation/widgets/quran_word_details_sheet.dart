import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/utils/arabic_search_utils.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../data/services/quran_tafsir_service.dart';

/// Quick word lookup opened directly from the Hafs Mushaf page.
///
/// The current word-by-word endpoint supplies English glosses. The language is
/// stated in the UI so the gloss cannot be mistaken for Arabic lexicography.
class QuranWordDetailsSheet extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final int wordIndex;
  final String tappedWord;
  final VoidCallback? onOpenVerseStudy;

  const QuranWordDetailsSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.wordIndex,
    required this.tappedWord,
    this.onOpenVerseStudy,
  });

  static Future<void> show(
    BuildContext context, {
    required int surahNumber,
    required int ayahNumber,
    required int wordIndex,
    required String tappedWord,
    VoidCallback? onOpenVerseStudy,
  }) async {
    await AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.66,
      builder: (_) => QuranWordDetailsSheet(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        wordIndex: wordIndex,
        tappedWord: tappedWord,
        onOpenVerseStudy: onOpenVerseStudy,
      ),
    );
  }

  @override
  State<QuranWordDetailsSheet> createState() => _QuranWordDetailsSheetState();
}

class _QuranWordDetailsSheetState extends State<QuranWordDetailsSheet> {
  late Future<List<WordMeaning>> _wordsFuture;
  late int _selectedWordIndex;

  @override
  void initState() {
    super.initState();
    _selectedWordIndex = widget.wordIndex;
    _loadWords();
  }

  void _loadWords() {
    _wordsFuture = QuranTafsirService.fetchWordMeanings(
      widget.surahNumber,
      widget.ayahNumber,
    );
  }

  int? _resolveWordIndex(List<WordMeaning> words) {
    if (_selectedWordIndex >= 0 && _selectedWordIndex < words.length) {
      return _selectedWordIndex;
    }

    final normalizedTappedWord = ArabicSearchUtils.normalize(widget.tappedWord);
    for (var index = 0; index < words.length; index++) {
      if (ArabicSearchUtils.normalize(words[index].word) ==
          normalizedTappedWord) {
        return index;
      }
    }
    return null;
  }

  void _openVerseStudy() {
    final onOpenVerseStudy = widget.onOpenVerseStudy;
    Navigator.of(context).pop();
    if (onOpenVerseStudy == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onOpenVerseStudy();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final verse = quran.getVerse(
      widget.surahNumber,
      widget.ayahNumber,
      verseEndSymbol: false,
    );
    final surahName = quran.getSurahNameArabic(widget.surahNumber);

    return AppSheet(
      titleText: 'معنى الكلمة',
      icon: Icons.translate_rounded,
      showCloseButton: true,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.lg,
      ),
      child: FutureBuilder<List<WordMeaning>>(
        future: _wordsFuture,
        initialData: QuranTafsirService.getCachedWordMeanings(
          widget.surahNumber,
          widget.ayahNumber,
        ),
        builder: (context, snapshot) {
          final words = snapshot.data ?? const <WordMeaning>[];
          final selectedIndex = _resolveWordIndex(words);
          final currentIndex = selectedIndex;
          final selectedMeaning = currentIndex == null
              ? null
              : words[currentIndex];
          final selectedWord = selectedMeaning?.word ?? widget.tappedWord;
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
              words.isEmpty;

          return ListView(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadius.lgRadius,
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        selectedWord,
                        textAlign: TextAlign.center,
                        style: textTheme.sacred.copyWith(
                          color: palette.text,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'سورة $surahName • الآية ${widget.ayahNumber}',
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),
              if (isLoading)
                Container(
                  padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                  decoration: BoxDecoration(
                    color: palette.surfaceRaised,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: palette.border),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppSkeleton.line(height: 14),
                      SizedBox(height: AppSpace.md),
                      AppSkeleton.line(height: 22),
                    ],
                  ),
                )
              else if (selectedMeaning != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.language_rounded,
                      size: AppIcon.sm,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      'المعنى بالإنجليزية',
                      style: textTheme.captionBold.copyWith(
                        color: palette.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceRaised,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (selectedMeaning.transliteration != null &&
                          selectedMeaning.transliteration!.isNotEmpty) ...[
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            selectedMeaning.transliteration!,
                            textAlign: TextAlign.start,
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.xs),
                      ],
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          selectedMeaning.meaning,
                          textAlign: TextAlign.start,
                          style: textTheme.body.copyWith(
                            color: palette.text,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: currentIndex != null && currentIndex > 0
                            ? () => setState(
                                () => _selectedWordIndex = currentIndex - 1,
                              )
                            : null,
                        icon: const Icon(Icons.skip_previous_rounded),
                        label: const Text('الكلمة السابقة'),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed:
                            currentIndex != null &&
                                currentIndex < words.length - 1
                            ? () => setState(
                                () => _selectedWordIndex = currentIndex + 1,
                              )
                            : null,
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('الكلمة التالية'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: palette.border),
                  ),
                  child: Text(
                    'تعذّر تحميل معنى هذه الكلمة. قد تحتاج إلى اتصال بالإنترنت؛ نص المصحف ما زال متاحًا.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall.copyWith(
                      color: palette.textMuted,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                AppButton.outline(
                  label: 'إعادة المحاولة',
                  icon: Icons.refresh_rounded,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(_loadWords);
                  },
                ),
              ],
              const SizedBox(height: AppSpace.sm),
              Container(
                padding: const EdgeInsetsDirectional.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    verse,
                    textAlign: TextAlign.center,
                    style: textTheme.body.copyWith(
                      color: palette.text,
                      height: 1.7,
                    ),
                  ),
                ),
              ),
              if (widget.onOpenVerseStudy != null) ...[
                const SizedBox(height: AppSpace.md),
                AppButton.outline(
                  label: 'فتح معاني الآية كاملة',
                  icon: Icons.menu_book_rounded,
                  onPressed: _openVerseStudy,
                ),
              ],
              if (currentIndex != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: AppSpace.xs),
                  child: Text(
                    'الكلمة ${currentIndex + 1} من ${words.length}',
                    textAlign: TextAlign.center,
                    style: textTheme.caption.copyWith(color: palette.textMuted),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
