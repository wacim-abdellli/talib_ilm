import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../data/models/islamic_quiz_models.dart';
import '../../data/services/quiz_progress_service.dart';
import 'quiz_session_page.dart';

/// Screen displaying the sequential levels for a specific Islamic discipline.
class FanQuizLevelsPage extends StatefulWidget {
  final FanQuiz fan;

  const FanQuizLevelsPage({
    super.key,
    required this.fan,
  });

  @override
  State<FanQuizLevelsPage> createState() => _FanQuizLevelsPageState();
}

class _FanQuizLevelsPageState extends State<FanQuizLevelsPage> {
  QuizProgressService? _progressService;
  bool _isLoading = true;
  Map<String, QuizLevelProgress> _progressMap = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _progressService = QuizProgressService(prefs);

    final map = <String, QuizLevelProgress>{};
    String? prevId;
    for (final level in widget.fan.levels) {
      final p = _progressService!.getLevelProgress(
        level.id,
        level.levelNumber,
        prevId,
        level.totalQuestions,
      );
      map[level.id] = p;
      prevId = level.id;
    }

    setState(() {
      _progressMap = map;
      _isLoading = false;
    });
  }

  void _startLevel(QuizLevel level) async {
    final progress = _progressMap[level.id];
    if (progress == null || !progress.isUnlocked) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أتمم المستوى السابق بنسبة 70% على الأقل لفتح هذا المستوى'),
        ),
      );
      return;
    }

    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      buildFadeRoute(
        page: QuizSessionPage(
          title: widget.fan.title,
          subtitle: level.title,
          levelId: level.id,
          questions: level.questions,
        ),
      ),
    );

    // Reload progress upon return
    await _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    int totalEarnedStars = 0;
    for (final p in _progressMap.values) {
      totalEarnedStars += p.stars;
    }
    final maxStars = widget.fan.levels.length * 3;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: palette.bg,
        appBar: AppBar(
          backgroundColor: palette.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'رجوع',
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: Text(widget.fan.title, style: textTheme.titleSmall),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: palette.primary))
            : ListView(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xl,
                  vertical: AppSpace.lg,
                ),
                children: [
                  // Hero Discipline Card
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
                        Container(
                          width: AppSpace.xxl * 2,
                          height: AppSpace.xxl * 2,
                          decoration: BoxDecoration(
                            color: palette.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.fan.icon,
                            color: palette.primary,
                            size: AppIcon.hero,
                          ),
                        ),
                        const SizedBox(height: AppSpace.md),
                        Text(
                          widget.fan.title,
                          style: textTheme.title,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          widget.fan.subtitle,
                          style: textTheme.bodySmall.copyWith(
                            color: palette.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpace.lg),
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.lg,
                            vertical: AppSpace.sm,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceMuted,
                            borderRadius: AppRadius.pillRadius,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: palette.gold,
                                size: AppIcon.md,
                              ),
                              const SizedBox(width: AppSpace.xs),
                              Text(
                                '$totalEarnedStars من $maxStars نجوم الإتقان',
                                style: textTheme.label.copyWith(
                                  color: palette.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpace.xl),

                  // Section Title
                  Text(
                    'مستويات الاختبار والدروس (${widget.fan.levels.length})',
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpace.md),

                  // Levels List
                  ...widget.fan.levels.map((level) {
                    final progress = _progressMap[level.id];
                    final isUnlocked = progress?.isUnlocked ?? false;
                    final isCompleted = progress?.isCompleted ?? false;
                    final stars = progress?.stars ?? 0;

                    return Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
                      child: _buildLevelCard(
                        level: level,
                        isUnlocked: isUnlocked,
                        isCompleted: isCompleted,
                        stars: stars,
                        highScore: progress?.highScore ?? 0,
                        palette: palette,
                        textTheme: textTheme,
                      ),
                    );
                  }),

                  SizedBox(height: AppSize.navClearance(context)),
                ],
              ),
      ),
    );
  }

  Widget _buildLevelCard({
    required QuizLevel level,
    required bool isUnlocked,
    required bool isCompleted,
    required int stars,
    required int highScore,
    required AppPalette palette,
    required dynamic textTheme,
  }) {
    return Material(
      color: palette.surface,
      borderRadius: AppRadius.lgRadius,
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: () => _startLevel(level),
        child: Container(
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            border: Border.all(
              color: isCompleted
                  ? palette.primary.withAlpha(90)
                  : palette.border,
            ),
            boxShadow: palette.shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: AppSpace.xxl,
                    height: AppSpace.xxl,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isUnlocked ? palette.primarySoft : palette.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${level.levelNumber}',
                      style: textTheme.label.copyWith(
                        color: isUnlocked ? palette.primary : palette.textSubtle,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.title,
                          style: textTheme.titleSmall.copyWith(
                            color: isUnlocked ? palette.text : palette.textMuted,
                          ),
                        ),
                        Text(
                          '${level.totalQuestions} أسئلة مع الشروحات والأدلة',
                          style: textTheme.caption.copyWith(
                            color: palette.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isUnlocked)
                    Icon(
                      Icons.lock_rounded,
                      color: palette.textSubtle,
                      size: AppIcon.md,
                    )
                  else if (isCompleted)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        return Icon(
                          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: i < stars ? palette.gold : palette.border,
                          size: AppIcon.sm,
                        );
                      }),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                level.description,
                style: textTheme.bodySmall.copyWith(
                  color: palette.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (highScore > 0)
                    Text(
                      'أفضل نتيجة: $highScore / ${level.totalQuestions}',
                      style: textTheme.caption.copyWith(
                        color: palette.primary,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isUnlocked ? palette.primary : palette.surfaceMuted,
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isCompleted
                              ? 'إعادة الاختبار'
                              : (isUnlocked ? 'بدء الاختبار' : 'مقفل'),
                          style: textTheme.caption.copyWith(
                            color: isUnlocked ? palette.onPrimary : palette.textSubtle,
                          ),
                        ),
                        if (isUnlocked) ...[
                          const SizedBox(width: AppSpace.xs),
                          Icon(
                            Icons.arrow_back_rounded,
                            color: palette.onPrimary,
                            size: AppIcon.xs,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
