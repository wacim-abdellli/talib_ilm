import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../data/catalogs/islamic_quiz_catalog.dart';
import '../../data/models/islamic_quiz_models.dart';
import '../../data/services/quiz_progress_service.dart';
import 'quiz_session_page.dart';

/// The celebratory and educational results screen displayed at the conclusion of a quiz.
class QuizResultPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? levelId;
  final List<QuizQuestion> questions;
  final List<int?> userAnswers;
  final int correctCount;
  final int maxStreak;
  final QuizRecordResult? recordResult;
  final bool isDailyChallenge;

  const QuizResultPage({
    super.key,
    required this.title,
    required this.subtitle,
    this.levelId,
    required this.questions,
    required this.userAnswers,
    required this.correctCount,
    required this.maxStreak,
    this.recordResult,
    this.isDailyChallenge = false,
  });

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  bool _isReviewing = false;

  int get _total => widget.questions.length;
  double get _percentage => _total > 0 ? (widget.correctCount / _total) * 100 : 0.0;
  bool get _hasPassed => _percentage >= 70.0;

  int get _stars {
    if (widget.recordResult != null) return widget.recordResult!.earnedStars;
    if (_percentage >= 99.9) return 3;
    if (_percentage >= 80.0) return 2;
    if (_percentage >= 70.0) return 1;
    return 0;
  }

  void _retakeQuiz() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pushReplacement(
      buildFadeRoute(
        page: QuizSessionPage(
          title: widget.title,
          subtitle: widget.subtitle,
          levelId: widget.levelId,
          questions: widget.questions,
          isDailyChallenge: widget.isDailyChallenge,
        ),
      ),
    );
  }

  void _proceedToNextLevel() {
    if (widget.levelId == null) return;
    final fan = IslamicQuizCatalog.getFanForLevel(widget.levelId!);
    if (fan == null) return;

    final currentIndex = fan.levels.indexWhere((lvl) => lvl.id == widget.levelId);
    if (currentIndex != -1 && currentIndex + 1 < fan.levels.length) {
      final nextLevel = fan.levels[currentIndex + 1];
      HapticFeedback.selectionClick();
      Navigator.of(context).pushReplacement(
        buildFadeRoute(
          page: QuizSessionPage(
            title: fan.title,
            subtitle: nextLevel.title,
            levelId: nextLevel.id,
            questions: nextLevel.questions,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: palette.bg,
        appBar: AppBar(
          backgroundColor: palette.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'إغلاق النتيجة',
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: Text(
            _isReviewing ? 'مراجعة الإجابات والدروس' : 'نتيجة الاختبار',
            style: textTheme.titleSmall,
          ),
        ),
        body: _isReviewing
            ? _buildReviewList(palette: palette, textTheme: textTheme)
            : _buildSummaryView(palette: palette, textTheme: textTheme),
      ),
    );
  }

  Widget _buildSummaryView({
    required AppPalette palette,
    required dynamic textTheme,
  }) {
    final nextLevelAvailable = widget.recordResult?.newlyUnlockedNextLevel ?? false;

    return ListView(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.lg,
      ),
      children: [
        // Trophy / Result Card
        Container(
          padding: const EdgeInsetsDirectional.all(AppSpace.xl),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AppRadius.xlRadius,
            border: Border.all(color: palette.border),
            boxShadow: palette.shadow,
          ),
          child: Column(
            children: [
              Transform.scale(
                scale: 1.8,
                child: Text(
                  _hasPassed ? '🎉' : '📖',
                  style: textTheme.display,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                _hasPassed ? 'مبارك! اجتزت الاختبار بنجاح' : 'محاولة طيبة! داوم على الطلب',
                style: textTheme.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                widget.title,
                style: textTheme.bodySmall.copyWith(color: palette.textMuted),
              ),
              const SizedBox(height: AppSpace.lg),

              // Stars Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final active = index < _stars;
                  return Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xs),
                    child: Icon(
                      active ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: active ? palette.gold : palette.border,
                      size: AppIcon.hero,
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpace.lg),

              // Score Ring & Breakdown
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xl,
                  vertical: AppSpace.md,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      label: 'الدرجة',
                      value: '${_percentage.toInt()}%',
                      color: _hasPassed ? palette.primary : palette.error,
                      palette: palette,
                      textTheme: textTheme,
                    ),
                    _buildStatColumn(
                      label: 'الصواب',
                      value: '${widget.correctCount} / $_total',
                      color: palette.text,
                      palette: palette,
                      textTheme: textTheme,
                    ),
                    if (widget.recordResult != null)
                      _buildStatColumn(
                        label: 'نقاط العلم',
                        value: '+${widget.recordResult!.earnedXp} XP',
                        color: palette.gold,
                        palette: palette,
                        textTheme: textTheme,
                      ),
                  ],
                ),
              ),

              if (widget.maxStreak >= 2) ...[
                const SizedBox(height: AppSpace.md),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.goldSoft,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Text(
                    'أطول سلسلة إجابات صحيحة: ${widget.maxStreak} أسئلة متتالية 🔥',
                    style: textTheme.caption.copyWith(color: palette.gold),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Unlocked next level banner
        if (nextLevelAvailable) ...[
          const SizedBox(height: AppSpace.md),
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            decoration: BoxDecoration(
              color: palette.primarySoft,
              borderRadius: AppRadius.lgRadius,
              border: Border.all(color: palette.primary.withAlpha(90)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_open_rounded,
                  color: palette.primary,
                  size: AppIcon.lg,
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تم فتح المستوى التالي!',
                        style: textTheme.label.copyWith(color: palette.primary),
                      ),
                      if (widget.recordResult?.nextLevelTitle != null)
                        Text(
                          widget.recordResult!.nextLevelTitle!,
                          style: textTheme.caption.copyWith(color: palette.text),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpace.xl),

        // Primary Action: Review Questions & Lessons
        SizedBox(
          height: AppSize.buttonH,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: palette.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
            ),
            icon: const Icon(Icons.school_rounded, size: AppIcon.sm),
            label: Text(
              'مراجعة الأسئلة والدروس المستفادة',
              style: textTheme.label.copyWith(color: palette.onPrimary),
            ),
            onPressed: () => setState(() => _isReviewing = true),
          ),
        ),
        const SizedBox(height: AppSpace.sm),

        // Secondary Action: Next Level or Retake
        if (nextLevelAvailable) ...[
          SizedBox(
            height: AppSize.buttonH,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.primary,
                side: BorderSide(color: palette.primary),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: AppIcon.sm),
              label: Text(
                'بدء المستوى التالي',
                style: textTheme.label.copyWith(color: palette.primary),
              ),
              onPressed: _proceedToNextLevel,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
        ],

        SizedBox(
          height: AppSize.buttonH,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: palette.textMuted,
            ),
            icon: const Icon(Icons.refresh_rounded, size: AppIcon.sm),
            label: Text(
              'إعادة الاختبار لتثبيت المعرفة',
              style: textTheme.label.copyWith(color: palette.textMuted),
            ),
            onPressed: _retakeQuiz,
          ),
        ),

        const SizedBox(height: AppSpace.sm),
        SizedBox(
          height: AppSize.buttonH,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'العودة لقائمة المسابقات',
              style: textTheme.label.copyWith(color: palette.textSubtle),
            ),
          ),
        ),

        SizedBox(height: AppSize.navClearance(context)),
      ],
    );
  }

  Widget _buildReviewList({
    required AppPalette palette,
    required dynamic textTheme,
  }) {
    return ListView(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.lg,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'مراجعة جميع الأسئلة ($_total)',
              style: textTheme.titleSmall,
            ),
            TextButton.icon(
              icon: const Icon(Icons.arrow_forward_rounded, size: AppIcon.sm),
              label: Text(
                'العودة للنتيجة',
                style: textTheme.label.copyWith(color: palette.primary),
              ),
              onPressed: () => setState(() => _isReviewing = false),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        ...List.generate(widget.questions.length, (index) {
          final question = widget.questions[index];
          final userAnswer = index < widget.userAnswers.length ? widget.userAnswers[index] : null;
          final isCorrect = userAnswer == question.correctIndex;

          return Container(
            margin: const EdgeInsetsDirectional.only(bottom: AppSpace.lg),
            padding: const EdgeInsetsDirectional.all(AppSpace.lg),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: AppRadius.lgRadius,
              border: Border.all(
                color: isCorrect ? palette.primary.withAlpha(90) : palette.error.withAlpha(90),
              ),
              boxShadow: palette.shadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isCorrect ? palette.primarySoft : palette.errorSoft,
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Text(
                        isCorrect ? 'إجابة صحيحة ✓' : 'إجابة خاطئة ✗',
                        style: textTheme.caption.copyWith(
                          color: isCorrect ? palette.primary : palette.error,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'سؤال ${index + 1}',
                      style: textTheme.caption.copyWith(color: palette.textSubtle),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  question.question,
                  style: textTheme.body.copyWith(color: palette.text),
                ),
                const SizedBox(height: AppSpace.md),

                // Selected & Correct options comparison
                Container(
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isCorrect && userAnswer != null) ...[
                        Text(
                          'إجابتك: ${question.options[userAnswer]}',
                          style: textTheme.bodySmall.copyWith(color: palette.error),
                        ),
                        const SizedBox(height: AppSpace.xs),
                      ],
                      Text(
                        'الإجابة الصحيحة: ${question.options[question.correctIndex]}',
                        style: textTheme.bodySmall.copyWith(color: palette.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.md),

                // Scholarly lesson & proof
                Text(
                  'الدرس المستفاد:',
                  style: textTheme.label.copyWith(color: palette.text),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  question.lesson,
                  style: textTheme.bodySmall.copyWith(color: palette.textMuted, height: 1.5),
                ),

                if (question.evidence.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    'الدليل: ${question.evidence}',
                    style: textTheme.sacred.copyWith(color: palette.text, height: 1.6),
                  ),
                ],

                if (question.reference.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xs),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      'المصدر: ${question.reference}',
                      style: textTheme.caption.copyWith(color: palette.textSubtle),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        SizedBox(height: AppSize.navClearance(context)),
      ],
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required Color color,
    required AppPalette palette,
    required dynamic textTheme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: textTheme.titleSmall.copyWith(color: color),
        ),
        const SizedBox(height: AppSpace.xxs),
        Text(
          label,
          style: textTheme.caption.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}
