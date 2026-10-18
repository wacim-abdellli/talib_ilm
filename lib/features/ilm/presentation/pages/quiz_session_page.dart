import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../data/models/islamic_quiz_models.dart';
import '../../data/services/quiz_progress_service.dart';
import '../widgets/quiz_lesson_explanation_card.dart';
import 'quiz_result_page.dart';

/// The active test and lesson runner for an Islamic quiz session.
class QuizSessionPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? levelId;
  final List<QuizQuestion> questions;
  final bool isDailyChallenge;

  const QuizSessionPage({
    super.key,
    required this.title,
    required this.subtitle,
    this.levelId,
    required this.questions,
    this.isDailyChallenge = false,
  });

  @override
  State<QuizSessionPage> createState() => _QuizSessionPageState();
}

class _QuizSessionPageState extends State<QuizSessionPage> {
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswered = false;

  int _correctAnswers = 0;
  int _currentStreak = 0;
  int _maxStreak = 0;

  final List<int?> _userAnswers = [];
  final ScrollController _scrollController = ScrollController();

  QuizQuestion get _currentQuestion => widget.questions[_currentIndex];

  String get _sessionKey =>
      widget.levelId ?? (widget.isDailyChallenge ? 'daily' : widget.title);

  @override
  void initState() {
    super.initState();
    _restoreActiveSession();
  }

  Future<void> _restoreActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final service = QuizProgressService(prefs);
    final session = service.getActiveSession(_sessionKey);
    if (session != null &&
        session.currentIndex > 0 &&
        session.currentIndex < widget.questions.length &&
        mounted) {
      setState(() {
        _currentIndex = session.currentIndex;
        _correctAnswers = session.correctAnswers;
        _currentStreak = session.currentStreak;
        _maxStreak = session.maxStreak;
        _userAnswers
          ..clear()
          ..addAll(session.userAnswers);
        _selectedOptionIndex = null;
        _isAnswered = false;
      });
    }
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    final service = QuizProgressService(prefs);
    await service.saveActiveSession(
      _sessionKey,
      QuizActiveSession(
        currentIndex: _currentIndex,
        correctAnswers: _correctAnswers,
        currentStreak: _currentStreak,
        maxStreak: _maxStreak,
        userAnswers: _userAnswers,
      ),
    );
  }

  void _onOptionSelected(int index) {
    if (_isAnswered) return;

    final isCorrect = _currentQuestion.isCorrect(index);
    HapticFeedback.selectionClick();

    setState(() {
      _selectedOptionIndex = index;
      _isAnswered = true;

      if (isCorrect) {
        _correctAnswers++;
        _currentStreak++;
        if (_currentStreak > _maxStreak) {
          _maxStreak = _currentStreak;
        }
      } else {
        _currentStreak = 0;
      }

      _userAnswers.add(index);
    });

    _persistSession();

    // Gently scroll down so the lesson and explanation are in full view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppMotion.slow,
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _onNextQuestion() async {
    HapticFeedback.selectionClick();

    if (_currentIndex + 1 < widget.questions.length) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _isAnswered = false;
      });

      _persistSession();

      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    } else {
      // Completed all questions in the session
      await _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    final progressService = QuizProgressService(prefs);

    await progressService.clearActiveSession(_sessionKey);

    QuizRecordResult? recordResult;
    if (widget.levelId != null) {
      recordResult = await progressService.recordLevelResult(
        levelId: widget.levelId!,
        correctCount: _correctAnswers,
        totalQuestions: widget.questions.length,
        maxStreak: _maxStreak,
      );
    } else if (widget.isDailyChallenge) {
      await progressService.markDailyChallengeCompleted(
        _correctAnswers,
        widget.questions.length,
      );
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      buildFadeRoute(
        page: QuizResultPage(
          title: widget.title,
          subtitle: widget.subtitle,
          levelId: widget.levelId,
          questions: widget.questions,
          userAnswers: _userAnswers,
          correctCount: _correctAnswers,
          maxStreak: _maxStreak,
          recordResult: recordResult,
          isDailyChallenge: widget.isDailyChallenge,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final total = widget.questions.length;
    final progressFraction = (_currentIndex + 1) / total;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _persistSession();
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
        backgroundColor: palette.bg,
        appBar: AppBar(
          backgroundColor: palette.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'خروج من الاختبار',
            onPressed: () => _confirmExit(context),
          ),
          centerTitle: true,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.subtitle,
                style: textTheme.caption.copyWith(color: palette.textSubtle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            if (_currentStreak >= 2)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpace.md),
                child: Center(
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: palette.goldSoft,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(color: palette.gold.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🔥 $_currentStreak',
                          style: textTheme.label.copyWith(
                            color: palette.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(AppSpace.xs),
            child: LinearProgressIndicator(
              value: progressFraction,
              backgroundColor: palette.border,
              valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
              minHeight: AppSpace.xs,
            ),
          ),
        ),
        body: ListView(
          controller: _scrollController,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.xl,
            vertical: AppSpace.lg,
          ),
          children: [
            // Question Counter & Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primarySoft,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Text(
                    'السؤال ${_currentIndex + 1} من $total',
                    style: textTheme.label.copyWith(
                      color: palette.onPrimarySoft,
                    ),
                  ),
                ),
                Text(
                  'الصواب: $_correctAnswers',
                  style: textTheme.caption.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),

            // Question Card
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.xl),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadius.lgRadius,
                border: Border.all(color: palette.border),
                boxShadow: palette.shadow,
              ),
              child: Text(
                _currentQuestion.question,
                style: textTheme.titleSmall.copyWith(
                  height: 1.6,
                ),
                textAlign: TextAlign.start,
              ),
            ),
            const SizedBox(height: AppSpace.lg),

            // Options list
            ...List.generate(_currentQuestion.options.length, (index) {
              final optionText = _currentQuestion.options[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
                child: _buildOptionTile(
                  index: index,
                  text: optionText,
                  palette: palette,
                  textTheme: textTheme,
                ),
              );
            }),

            // Interactive lesson & explanation card (revealed upon answer)
            if (_isAnswered) ...[
              const SizedBox(height: AppSpace.md),
              QuizLessonExplanationCard(
                question: _currentQuestion,
                isUserCorrect:
                    _selectedOptionIndex == _currentQuestion.correctIndex,
              ),
              const SizedBox(height: AppSpace.xl),
            ],

            // Navigation Bottom Spacer
            SizedBox(height: AppSize.navClearance(context)),
          ],
        ),
        bottomNavigationBar: _isAnswered
            ? Container(
                padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                decoration: BoxDecoration(
                  color: palette.surfaceRaised,
                  border: Border(top: BorderSide(color: palette.border)),
                ),
                child: SafeArea(
                  child: SizedBox(
                    height: AppSize.buttonH,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: palette.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mdRadius,
                        ),
                      ),
                      onPressed: _onNextQuestion,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentIndex + 1 < total
                                ? 'السؤال التالي'
                                : 'عرض النتيجة النهائية',
                            style: textTheme.label.copyWith(
                              color: palette.onPrimary,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          const Icon(
                            Icons.arrow_back_rounded,
                            size: AppIcon.sm,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    ),
  );
}

  Widget _buildOptionTile({
    required int index,
    required String text,
    required AppPalette palette,
    required dynamic textTheme,
  }) {
    Color bgColor = palette.surface;
    Color borderColor = palette.border;
    Color textColor = palette.text;
    Widget? trailingIcon;

    if (_isAnswered) {
      final isCorrect = _currentQuestion.correctIndex == index;
      final isSelected = _selectedOptionIndex == index;

      if (isCorrect) {
        bgColor = palette.primarySoft;
        borderColor = palette.primary;
        textColor = palette.onPrimarySoft;
        trailingIcon = Icon(
          Icons.check_circle_rounded,
          color: palette.primary,
          size: AppIcon.md,
        );
      } else if (isSelected) {
        bgColor = palette.errorSoft;
        borderColor = palette.error;
        textColor = palette.error;
        trailingIcon = Icon(
          Icons.cancel_rounded,
          color: palette.error,
          size: AppIcon.md,
        );
      }
    }

    return Material(
      color: bgColor,
      borderRadius: AppRadius.mdRadius,
      child: InkWell(
        borderRadius: AppRadius.mdRadius,
        onTap: _isAnswered ? null : () => _onOptionSelected(index),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSize.tap),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: AppSpace.xxl,
                height: AppSpace.xxl,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surfaceMuted,
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  _getOptionLetter(index),
                  style: textTheme.caption.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  text,
                  style: textTheme.body.copyWith(
                    color: textColor,
                    height: 1.5,
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppSpace.sm),
                trailingIcon,
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getOptionLetter(int index) {
    switch (index) {
      case 0:
        return 'أ';
      case 1:
        return 'ب';
      case 2:
        return 'ج';
      case 3:
        return 'د';
      default:
        return '${index + 1}';
    }
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final palette = ctx.palette;
        final textTheme = ctx.text;
        return AlertDialog(
          backgroundColor: palette.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.xlRadius,
          ),
          title: Text(
            'حفظ ومتابعة لاحقاً؟',
            style: textTheme.titleSmall,
          ),
          content: Text(
            'سيتم حفظ تقدمك تلقائياً لتستأنف الاختبار من نفس السؤال عند عودتك.',
            style: textTheme.bodySmall,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'متابعة الاختبار',
                style: textTheme.label.copyWith(color: palette.primary),
              ),
            ),
            TextButton(
              onPressed: () async {
                await _persistSession();
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                'خروج وحفظ',
                style: textTheme.label.copyWith(color: palette.error),
              ),
            ),
          ],
        );
      },
    );
  }
}
