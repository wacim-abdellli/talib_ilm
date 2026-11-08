import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/utils/arabic_search_utils.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../data/models/quran_word_analysis.dart';
import '../../data/services/quran_tafsir_service.dart';
import '../../data/services/quran_word_analysis_service.dart';

enum WordAnalysisTier {
  meaning('المعنى والبيان', Icons.menu_book_rounded),
  irab('الإعراب المفصل', Icons.account_tree_rounded),
  sarf('الصرف والاشتقاق', Icons.architecture_rounded),
  qiraat('القراءات الواردة', Icons.record_voice_over_rounded);

  final String label;
  final IconData icon;
  const WordAnalysisTier(this.label, this.icon);
}

/// Comprehensive 4-tier linguistic breakdown sheet for Quranic words.
///
/// Inspired by the Wahy Islamic platform:
/// 1. المعنى والبيان (Contextual explanation and vocabulary).
/// 2. الإعراب المفصل (Full syntactic dependency and inflectional markers).
/// 3. الصرف والاشتقاق والوزن (Measure, root, and morphological decomposition).
/// 4. القراءات الواردة (Canonical ten Qira'at differences وصلاً ووقفاً).
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
      maxHeightFactor: 0.85,
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
  late Future<List<QuranWordAnalysis>> _analysesFuture;
  late Future<List<WordMeaning>> _meaningsFuture;
  late int _selectedWordIndex;
  WordAnalysisTier _selectedTier = WordAnalysisTier.meaning;

  @override
  void initState() {
    super.initState();
    _selectedWordIndex = widget.wordIndex;
    _loadData();
  }

  void _loadData() {
    _analysesFuture = QuranWordAnalysisService().getAyahWordAnalyses(
      widget.surahNumber,
      widget.ayahNumber,
    );
    _meaningsFuture = QuranTafsirService.fetchWordMeanings(
      widget.surahNumber,
      widget.ayahNumber,
    );
  }

  int? _resolveAnalysisIndex(List<QuranWordAnalysis> analyses) {
    if (_selectedWordIndex >= 0 && _selectedWordIndex < analyses.length) {
      return _selectedWordIndex;
    }

    final normalizedTapped = ArabicSearchUtils.normalize(widget.tappedWord);
    for (var i = 0; i < analyses.length; i++) {
      if (ArabicSearchUtils.normalize(analyses[i].word) == normalizedTapped) {
        return i;
      }
    }
    return analyses.isNotEmpty ? 0 : null;
  }

  WordMeaning? _findGloss(List<WordMeaning> meanings, String word) {
    final norm = ArabicSearchUtils.normalize(word);
    for (final m in meanings) {
      if (ArabicSearchUtils.normalize(m.word) == norm) {
        return m;
      }
    }
    return null;
  }

  void _openVerseStudy() {
    final callback = widget.onOpenVerseStudy;
    Navigator.of(context).pop();
    if (callback != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => callback());
    }
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
      titleText: 'التحليل اللغوي للمفردة',
      icon: Icons.auto_stories_rounded,
      showCloseButton: true,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.lg,
      ),
      child: FutureBuilder<List<QuranWordAnalysis>>(
        future: _analysesFuture,
        builder: (context, analysisSnapshot) {
          return FutureBuilder<List<WordMeaning>>(
            future: _meaningsFuture,
            initialData: QuranTafsirService.getCachedWordMeanings(
              widget.surahNumber,
              widget.ayahNumber,
            ),
            builder: (context, meaningSnapshot) {
              final analyses = analysisSnapshot.data ?? const <QuranWordAnalysis>[];
              final meanings = meaningSnapshot.data ?? const <WordMeaning>[];
              final currentIndex = _resolveAnalysisIndex(analyses);

              final currentAnalysis = currentIndex != null && currentIndex < analyses.length
                  ? analyses[currentIndex]
                  : null;

              final selectedWord = currentAnalysis?.word ?? widget.tappedWord;
              final gloss = _findGloss(meanings, selectedWord);
              final isLoading = analysisSnapshot.connectionState == ConnectionState.waiting &&
                  analyses.isEmpty;

              return ListView(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                children: [
                  // 1. Word Header Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsetsDirectional.all(AppSpace.md),
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
                            '﴿$selectedWord﴾',
                            textAlign: TextAlign.center,
                            style: textTheme.sacred.copyWith(
                              color: palette.text,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpace.xs,
                          runSpacing: AppSpace.xxs,
                          children: [
                            Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.sm,
                                vertical: AppSpace.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: palette.goldSoft,
                                borderRadius: AppRadius.pillRadius,
                              ),
                              child: Text(
                                'سورة $surahName • الآية ${widget.ayahNumber}',
                                style: textTheme.captionBold.copyWith(
                                  color: palette.gold,
                                ),
                              ),
                            ),
                            if (currentIndex != null)
                              Container(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpace.sm,
                                  vertical: AppSpace.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.surfaceRaised,
                                  borderRadius: AppRadius.pillRadius,
                                  border: Border.all(color: palette.border),
                                ),
                                child: Text(
                                  'الكلمة ${currentIndex + 1} من ${analyses.length}',
                                  style: textTheme.caption.copyWith(
                                    color: palette.textMuted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpace.md),

                  // 2. Tier Selection Tabs
                  Wrap(
                    spacing: AppSpace.xs,
                    runSpacing: AppSpace.xs,
                    children: WordAnalysisTier.values.map((tier) {
                      final isSelected = _selectedTier == tier;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedTier = tier);
                          },
                          borderRadius: AppRadius.pillRadius,
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 44),
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.sm,
                              vertical: AppSpace.xs,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? palette.primary
                                  : palette.surfaceRaised,
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(
                                color: isSelected
                                    ? palette.primary
                                    : palette.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  tier.icon,
                                  size: AppIcon.sm,
                                  color: isSelected
                                      ? palette.surfaceRaised
                                      : palette.textMuted,
                                ),
                                const SizedBox(width: AppSpace.xxs),
                                Text(
                                  tier.label,
                                  style: textTheme.captionBold.copyWith(
                                    color: isSelected
                                        ? palette.surfaceRaised
                                        : palette.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpace.md),

                  // 3. Analysis Body
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
                          AppSkeleton.line(height: 16),
                          SizedBox(height: AppSpace.md),
                          AppSkeleton.line(height: 24),
                          SizedBox(height: AppSpace.sm),
                          AppSkeleton.line(height: 18),
                        ],
                      ),
                    )
                  else if (currentAnalysis != null) ...[
                    _buildTierContent(
                      tier: _selectedTier,
                      analysis: currentAnalysis,
                      gloss: gloss,
                      palette: palette,
                      textTheme: textTheme,
                    ),

                    const SizedBox(height: AppSpace.sm),

                    // 4. Previous / Next Word Navigation Steppers
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: currentIndex != null && currentIndex > 0
                                ? () {
                                    HapticFeedback.selectionClick();
                                    setState(
                                      () => _selectedWordIndex = currentIndex - 1,
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.skip_previous_rounded),
                            label: const Text('الكلمة السابقة'),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: currentIndex != null &&
                                    currentIndex < analyses.length - 1
                                ? () {
                                    HapticFeedback.selectionClick();
                                    setState(
                                      () => _selectedWordIndex = currentIndex + 1,
                                    );
                                  }
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
                        'تعذّر تحميل التحليل اللغوي لهذه المفردة حالياً.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    AppButton.outline(
                      label: 'إعادة المحاولة',
                      icon: Icons.refresh_rounded,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(_loadData);
                      },
                    ),
                  ],

                  const SizedBox(height: AppSpace.sm),

                  // 5. Verse Context Card
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
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTierContent({
    required WordAnalysisTier tier,
    required QuranWordAnalysis analysis,
    required WordMeaning? gloss,
    required AppPalette palette,
    required AppTextTheme textTheme,
  }) {
    switch (tier) {
      case WordAnalysisTier.meaning:
        final hasArabicMeaning = analysis.hasMeaning;
        final hasGloss = gloss != null && gloss.meaning.isNotEmpty;

        return Container(
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
              if (hasArabicMeaning) ...[
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: AppIcon.sm,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      'المعنى في السياق القرآني',
                      style: textTheme.captionBold.copyWith(
                        color: palette.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    analysis.meaning,
                    style: textTheme.body.copyWith(
                      color: palette.text,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
              if (hasGloss) ...[
                if (hasArabicMeaning) const SizedBox(height: AppSpace.md),
                Row(
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      size: AppIcon.sm,
                      color: palette.textMuted,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      'English Meaning & Transliteration',
                      style: textTheme.captionBold.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                if (gloss.transliteration != null &&
                    gloss.transliteration!.isNotEmpty) ...[
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      gloss.transliteration!,
                      style: textTheme.caption.copyWith(color: palette.gold),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xxs),
                ],
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    gloss.meaning,
                    style: textTheme.bodySmall.copyWith(
                      color: palette.text,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
              if (!hasArabicMeaning && !hasGloss)
                Text(
                  'انظر تفسير الآية الكريمة لبيان معانيها.',
                  style: textTheme.bodySmall.copyWith(color: palette.textMuted),
                ),
            ],
          ),
        );

      case WordAnalysisTier.irab:
        return Container(
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
              Row(
                children: [
                  Icon(
                    Icons.account_tree_rounded,
                    size: AppIcon.sm,
                    color: palette.primary,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    'الإعراب والتركيب النحوي',
                    style: textTheme.captionBold.copyWith(
                      color: palette.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  analysis.irab.isNotEmpty
                      ? analysis.irab
                      : 'لا يتوفر إعراب تفصيلي لهذه المفردة حالياً.',
                  style: textTheme.body.copyWith(
                    color: palette.text,
                    height: 1.65,
                  ),
                ),
              ),
            ],
          ),
        );

      case WordAnalysisTier.sarf:
        return Container(
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
              Row(
                children: [
                  Icon(
                    Icons.architecture_rounded,
                    size: AppIcon.sm,
                    color: palette.gold,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    'الوزن الصرفي والاشتقاق والجذر',
                    style: textTheme.captionBold.copyWith(
                      color: palette.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  analysis.sarf.isNotEmpty
                      ? analysis.sarf
                      : 'لا يتوفر تصريف واشتقاق لهذه المفردة حالياً.',
                  style: textTheme.body.copyWith(
                    color: palette.text,
                    height: 1.65,
                  ),
                ),
              ),
            ],
          ),
        );

      case WordAnalysisTier.qiraat:
        return Container(
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
              Row(
                children: [
                  Icon(
                    Icons.record_voice_over_rounded,
                    size: AppIcon.sm,
                    color: palette.primary,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    'روايات القراء العشر في الموضع',
                    style: textTheme.captionBold.copyWith(
                      color: palette.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  analysis.qiraat.isNotEmpty
                      ? analysis.qiraat
                      : 'لا خلاف بين القراء العشرة في هذا الموضع.',
                  style: textTheme.body.copyWith(
                    color: palette.text,
                    height: 1.65,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}
