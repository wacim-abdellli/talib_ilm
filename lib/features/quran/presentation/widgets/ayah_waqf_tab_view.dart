import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/models/quran_waqf_analysis.dart';
import '../../data/services/quran_waqf_service.dart';

/// Tab view presenting the classical stop judgments of the 5 Imams of Waqf
/// (الداني، السجاوندي، الأنصاري، الهبطي، الأشموني) for a specific Ayah.
class AyahWaqfTabView extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;

  const AyahWaqfTabView({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
  });

  @override
  State<AyahWaqfTabView> createState() => _AyahWaqfTabViewState();
}

class _AyahWaqfTabViewState extends State<AyahWaqfTabView> {
  final QuranWaqfService _waqfService = QuranWaqfService();
  final ScrollController _scrollController = ScrollController();

  AyahWaqfAnalysis? _analysis;
  bool _loading = true;
  String _selectedScholarId = 'all'; // 'all' or scholar ID (dani, sajawandi, etc.)
  int? _selectedWordIndex;

  @override
  void initState() {
    super.initState();
    _loadWaqfData();
  }

  @override
  void didUpdateWidget(covariant AyahWaqfTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahNumber != widget.surahNumber ||
        oldWidget.ayahNumber != widget.ayahNumber) {
      _loadWaqfData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadWaqfData() async {
    setState(() {
      _loading = true;
      _selectedWordIndex = null;
    });

    try {
      final analysis = await _waqfService.getAyahWaqf(
        widget.surahNumber,
        widget.ayahNumber,
      );
      if (!mounted) return;
      setState(() {
        _analysis = analysis;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Color _getGradeColor(AppPalette palette, String grade) {
    switch (grade) {
      case 'tam':
        return palette.success;
      case 'kafi':
        return palette.primary;
      case 'hasan':
      case 'salih':
      case 'jaiz':
        return palette.gold;
      case 'lazim':
        return palette.gold;
      case 'neg':
        return palette.error;
      case 'habti':
        return palette.primary;
      default:
        return palette.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              'جارٍ استخراج أحكام أئمة الوقف...',
              style: textTheme.caption.copyWith(color: palette.textMuted),
            ),
          ],
        ),
      );
    }

    final analysis = _analysis;
    if (analysis == null || analysis.words.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpace.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_border_rounded,
                size: AppIcon.xl,
                color: palette.textMuted,
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'لا توجد مواضع وقف مسجلة لهذه الآية',
                style: textTheme.bodyMedium.copyWith(color: palette.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final scholars = analysis.scholars;

    // Filter words based on selected scholar & word index
    final filteredWords = analysis.words.where((w) {
      if (_selectedWordIndex != null && w.wordIndex != _selectedWordIndex) {
        return false;
      }
      if (_selectedScholarId != 'all') {
        return w.hasScholar(_selectedScholarId);
      }
      return true;
    }).toList();

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpace.sm,
          horizontal: AppSpace.xs,
        ),
        children: [
          // 1. Scholar Filter Chips Wrap
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildScholarFilterChip(
                  context,
                  id: 'all',
                  label: 'جميع الأئمة الخمسة',
                  isSelected: _selectedScholarId == 'all',
                ),
                ...scholars.map((s) {
                  return _buildScholarFilterChip(
                    context,
                    id: s.id,
                    label: '${s.shortName} (${s.deathYear}هـ)',
                    isSelected: _selectedScholarId == s.id,
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.sm),

          // 2. Interactive Word Stop Flow
          AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'انقر على أي كلمة لعرض أحكام الوقف عليها:',
                  style: textTheme.caption.copyWith(color: palette.textMuted),
                ),
                const SizedBox(height: AppSpace.xs),
                Wrap(
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  alignment: WrapAlignment.center,
                  children: analysis.words.map((w) {
                    final isSelected = _selectedWordIndex == w.wordIndex;
                    return Semantics(
                      button: true,
                      label: 'موضع الوقف عند كلمة ${w.word}',
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (_selectedWordIndex == w.wordIndex) {
                              _selectedWordIndex = null;
                            } else {
                              _selectedWordIndex = w.wordIndex;
                            }
                          });
                        },
                        borderRadius: AppRadius.smRadius,
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.sm,
                            vertical: AppSpace.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? palette.primary.withValues(alpha: 0.15)
                                : palette.surfaceMuted,
                            borderRadius: AppRadius.smRadius,
                            border: Border.all(
                              color: isSelected ? palette.primary : palette.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                w.word,
                                style: textTheme.sacred.copyWith(
                                  color: isSelected ? palette.primary : palette.text,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: AppSpace.xxs),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: palette.gold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.md),

          // 3. Judgments List per Word
          if (filteredWords.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                child: Text(
                  'لا توجد أحكام وقف مسجلة للمحدد حالياً',
                  style: textTheme.caption.copyWith(color: palette.textMuted),
                ),
              ),
            )
          else
            ...filteredWords.map((w) => _buildWordCard(context, w, scholars)),

          const SizedBox(height: AppSpace.lg),
        ],
      ),
    );
  }

  Widget _buildScholarFilterChip(
    BuildContext context, {
    required String id,
    required String label,
    required bool isSelected,
  }) {
    final palette = context.palette;
    final textTheme = context.text;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
      child: Semantics(
        button: true,
        selected: isSelected,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedScholarId = id);
          },
          borderRadius: AppRadius.pillRadius,
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected ? palette.primary : palette.surfaceMuted,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(
                color: isSelected ? palette.primary : palette.border,
              ),
            ),
            child: Text(
              label,
              style: textTheme.caption.copyWith(
                color: isSelected ? palette.surface : palette.text,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordCard(
    BuildContext context,
    WaqfWord word,
    List<WaqfScholar> scholars,
  ) {
    final palette = context.palette;
    final textTheme = context.text;

    final judgmentsToShow = _selectedScholarId == 'all'
        ? word.judgments
        : word.judgments.where((j) => j.scholarId == _selectedScholarId).toList();

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
      child: AppCard(
        padding: const EdgeInsetsDirectional.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Word header banner
            Row(
              children: [
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.gold.withValues(alpha: 0.12),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: Text(
                    'الكلمة ${word.wordIndex}',
                    style: textTheme.captionBold.copyWith(color: palette.gold),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    'عند قوله تعالى: ﴿${word.word}﴾',
                    style: textTheme.titleSmall.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpace.sm),
            Divider(height: 1, color: palette.border),
            const SizedBox(height: AppSpace.sm),

            // Judgments from scholars
            ...judgmentsToShow.map((j) {
              final scholar = scholars.firstWhere(
                (s) => s.id == j.scholarId,
                orElse: () => WaqfScholar(
                  id: j.scholarId,
                  shortName: j.scholarId,
                  bookTitle: '',
                  deathYear: 0,
                ),
              );

              final gradeColor = _getGradeColor(palette, j.grade);

              return Container(
                margin: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
                padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadius.smRadius,
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Scholar name + grade badge wrap
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpace.xs,
                      runSpacing: AppSpace.xs,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school_rounded,
                              size: AppIcon.xs,
                              color: palette.primary,
                            ),
                            const SizedBox(width: AppSpace.xxs),
                            Text(
                              '${scholar.shortName} (${scholar.bookTitle})',
                              style: textTheme.captionBold.copyWith(
                                color: palette.text,
                              ),
                            ),
                          ],
                        ),
                        // Grade Badge
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.sm,
                            vertical: AppSpace.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: gradeColor.withValues(alpha: 0.15),
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(color: gradeColor),
                          ),
                          child: Text(
                            j.label.isNotEmpty ? j.label : j.longLabel,
                            style: textTheme.captionBold.copyWith(
                              color: gradeColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Explanation (علة الوقف)
                    if (j.explanation.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        j.explanation,
                        style: textTheme.bodySmall.copyWith(
                          color: palette.text,
                          height: 1.5,
                        ),
                      ),
                    ],

                    // Page citation & note
                    if (j.page.isNotEmpty || j.note.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (j.page.isNotEmpty)
                            Text(
                              'مرجع: ${j.page}',
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          if (j.note.isNotEmpty) ...[
                            const SizedBox(width: AppSpace.sm),
                            Flexible(
                              child: Text(
                                j.note,
                                style: textTheme.caption.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
