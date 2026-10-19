import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../data/catalogs/islamic_quiz_catalog.dart';
import '../../data/catalogs/quiz_manhaj_syllabus.dart';
import '../../data/models/islamic_quiz_models.dart';
import '../../data/services/quiz_dump_service.dart';
import '../../data/services/quiz_progress_service.dart';
import '../widgets/fan_quiz_level_card.dart';
import 'quiz_session_page.dart';

/// Screen displaying the sequential levels and curriculum tree for a specific Islamic discipline.
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

  FanQuiz get _currentFan =>
      IslamicQuizCatalog.getFan(widget.fan.id) ?? widget.fan;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    await QuizDumpService.instance.loadDump();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _progressService = QuizProgressService(prefs);

    final map = <String, QuizLevelProgress>{};
    String? prevId;
    for (final level in _currentFan.levels) {
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

    final freshLevel = IslamicQuizCatalog.getLevel(level.id) ?? level;

    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      buildFadeRoute(
        page: QuizSessionPage(
          title: _currentFan.title,
          subtitle: freshLevel.title,
          levelId: freshLevel.id,
          questions: freshLevel.questions,
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
    int completedLevelsCount = 0;
    for (final p in _progressMap.values) {
      totalEarnedStars += p.stars;
      if (p.isCompleted) completedLevelsCount++;
    }
    final maxStars = _currentFan.levels.length * 3;
    final disciplineProgress = maxStars > 0
        ? (totalEarnedStars / maxStars).clamp(0.0, 1.0)
        : 0.0;

    final descriptors = QuizManhajSyllabus.descriptors[_currentFan.id] ?? const [];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: palette.bg,
        appBar: AppBar(
          backgroundColor: palette.surface,
          elevation: 0,
          leading: const AppBackButton(),
          centerTitle: true,
          title: Text(_currentFan.title, style: textTheme.titleSmall),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: palette.primary))
            : ListView(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.md,
                ),
                children: [
                  // Hero Discipline Scholarly Card
                  _buildHeroCard(
                    palette: palette,
                    textTheme: textTheme,
                    disciplineProgress: disciplineProgress,
                    totalEarnedStars: totalEarnedStars,
                    maxStars: maxStars,
                    completedLevelsCount: completedLevelsCount,
                  ),

                  const SizedBox(height: AppSpace.lg),

                  // Curriculum Roadmap Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'شجرة المنهج والمستويات الدراسية',
                        style: textTheme.titleSmall,
                      ),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: AppSpace.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Text(
                          '${_currentFan.levels.length} مستويات منهجية',
                          style: textTheme.caption.copyWith(color: palette.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),

                  // Levels Tree with Stage Dividers
                  ..._buildLevelsTree(
                    palette: palette,
                    textTheme: textTheme,
                    descriptors: descriptors,
                  ),

                  SizedBox(height: AppSize.navClearance(context)),
                ],
              ),
      ),
    );
  }

  Widget _buildHeroCard({
    required AppPalette palette,
    required dynamic textTheme,
    required double disciplineProgress,
    required int totalEarnedStars,
    required int maxStars,
    required int completedLevelsCount,
  }) {
    final fanTheme = palette.fanColor(_currentFan.id);

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(
          color: fanTheme.border.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: palette.shadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: AppSpace.xxl * 1.5,
                height: AppSpace.xxl * 1.5,
                decoration: BoxDecoration(
                  color: fanTheme.softBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: fanTheme.border,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _currentFan.icon,
                  color: fanTheme.primary,
                  size: AppIcon.lg,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentFan.title,
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      _currentFan.subtitle,
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),

          // Stage Roadmap Steps
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Row(
              children: [
                _buildStageChip('التأسيس', palette, textTheme, true),
                Icon(Icons.chevron_left_rounded, color: palette.textSubtle, size: AppIcon.sm),
                _buildStageChip('التأصيل', palette, textTheme, completedLevelsCount >= 2),
                Icon(Icons.chevron_left_rounded, color: palette.textSubtle, size: AppIcon.sm),
                _buildStageChip('التمكين والإتقان', palette, textTheme, completedLevelsCount >= 4),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.md),

          // Progress Bar
          ClipRRect(
            borderRadius: AppRadius.pillRadius,
            child: LinearProgressIndicator(
              value: disciplineProgress,
              backgroundColor: palette.surfaceMuted,
              color: fanTheme.primary,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: AppSpace.sm),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: palette.gold,
                    size: AppIcon.sm,
                  ),
                  const SizedBox(width: AppSpace.xxs),
                  Text(
                    '$totalEarnedStars من $maxStars نجوم الإتقان',
                    style: textTheme.caption.copyWith(
                      color: palette.gold,
                    ),
                  ),
                ],
              ),
              Text(
                '$completedLevelsCount من ${_currentFan.levels.length} مستويات منجزة',
                style: textTheme.caption.copyWith(
                  color: palette.textSubtle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageChip(String label, AppPalette palette, dynamic textTheme, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.xxs),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? palette.surface : Colors.transparent,
          borderRadius: AppRadius.pillRadius,
          border: isActive ? Border.all(color: palette.border) : null,
        ),
        child: Text(
          label,
          style: textTheme.caption.copyWith(
            color: isActive ? palette.text : palette.textSubtle,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLevelsTree({
    required AppPalette palette,
    required dynamic textTheme,
    required List<ManhajLevelDescriptor> descriptors,
  }) {
    final widgets = <Widget>[];
    String? currentStage;

    for (int i = 0; i < _currentFan.levels.length; i++) {
      final level = _currentFan.levels[i];
      final descriptor = i < descriptors.length ? descriptors[i] : null;
      final stage = descriptor?.stage ?? 'المستوى المنهجي';

      // Insert stage divider when stage transitions
      if (stage != currentStage) {
        currentStage = stage;
        widgets.add(
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: AppSpace.md,
              bottom: AppSpace.sm,
            ),
            child: _buildStageHeader(stage, palette, textTheme),
          ),
        );
      }

      final progress = _progressMap[level.id];
      final isUnlocked = progress?.isUnlocked ?? false;
      final isCompleted = progress?.isCompleted ?? false;
      final stars = progress?.stars ?? 0;
      final highScore = progress?.highScore ?? 0;

      final activeSession = _progressService?.getActiveSession(level.id);
      final bool hasActiveSession = activeSession != null &&
          activeSession.currentIndex > 0 &&
          activeSession.currentIndex < level.totalQuestions;

      widgets.add(
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
          child: FanQuizLevelCard(
            level: level,
            isUnlocked: isUnlocked,
            isCompleted: isCompleted,
            hasActiveSession: hasActiveSession,
            activeSession: activeSession,
            stars: stars,
            highScore: highScore,
            onTap: () => _startLevel(level),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildStageHeader(String stage, AppPalette palette, dynamic textTheme) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: palette.goldSoft,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: palette.gold.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_rounded, color: palette.gold, size: AppIcon.xs),
          const SizedBox(width: AppSpace.xs),
          Text(
            stage,
            style: textTheme.caption.copyWith(
              color: palette.gold,
            ),
          ),
        ],
      ),
    );
  }
}
