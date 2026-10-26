import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../data/catalogs/islamic_quiz_catalog.dart';
import '../../data/models/islamic_quiz_models.dart';
import '../../data/services/quiz_dump_service.dart';
import '../../data/services/quiz_progress_service.dart';
import '../widgets/quiz_hero_stats_banner.dart';
import 'fan_quiz_levels_page.dart';
import 'quiz_session_page.dart';

/// The central competitive hub for all Islamic quizzes, tests, and knowledge competitions.
class IslamicQuizHubPage extends StatefulWidget {
  final bool showAppBar;

  const IslamicQuizHubPage({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<IslamicQuizHubPage> createState() => _IslamicQuizHubPageState();
}

class _IslamicQuizHubPageState extends State<IslamicQuizHubPage> {
  QuizProgressService? _progressService;
  UserQuizStats? _userStats;
  bool _isLoading = true;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    await QuizDumpService.instance.loadDump();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _progressService = QuizProgressService(prefs);

    setState(() {
      _userStats = _progressService!.getUserStats();
      _isLoading = false;
    });
  }

  void _openDailyChallenge() async {
    final questions = IslamicQuizCatalog.getDailyChallengeQuestions();
    if (questions.isEmpty) return;

    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      buildFadeRoute(
        page: QuizSessionPage(
          title: 'التحدي اليومي السريع',
          subtitle: '10 أسئلة منوعة من سائر فنون الشريعة',
          questions: questions,
          isDailyChallenge: true,
        ),
      ),
    );

    await _loadStats();
  }

  void _openFanLevels(FanQuiz fan) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      buildFadeRoute(
        page: FanQuizLevelsPage(fan: fan),
      ),
    );

    await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final allFounoun = IslamicQuizCatalog.founoun;
    final filteredFounoun = _selectedCategory == 'all'
        ? allFounoun
        : allFounoun.where((f) => f.id == _selectedCategory).toList();

    final content = _isLoading
        ? Center(child: CircularProgressIndicator(color: palette.primary))
        : ListView(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.md,
            ),
            children: [
              // Scholarly Rank & Stats Hero Banner
              QuizHeroStatsBanner(stats: _userStats),
              const SizedBox(height: AppSpace.md),

              // Daily Challenge Card
              _buildDailyChallengeCard(palette: palette, textTheme: textTheme),
              const SizedBox(height: AppSpace.lg),

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'فنون العلم الشرعي المنهجية',
                    style: textTheme.titleSmall,
                  ),
                  Text(
                    '${allFounoun.length} فنون · ${IslamicQuizCatalog.totalLevelsCount} مستويات',
                    style: textTheme.caption.copyWith(color: palette.textSubtle),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),

              // Discipline Filter Chips
              _buildCategoryFilter(palette: palette, textTheme: textTheme),
              const SizedBox(height: AppSpace.md),

              // Founoun List
              ...filteredFounoun.map((fan) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
                  child: _buildFanCard(
                    fan: fan,
                    palette: palette,
                    textTheme: textTheme,
                  ),
                );
              }),

              SizedBox(height: AppSize.navClearance(context)),
            ],
          );

    if (!widget.showAppBar) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: content,
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: palette.bg,
        appBar: AppBar(
          backgroundColor: palette.surface,
          elevation: 0,
          leading: const AppBackButton(),
          centerTitle: true,
          title: Text(
            'المسابقات والمنهج العلمي',
            style: textTheme.titleSmall,
          ),
        ),
        body: content,
      ),
    );
  }

  Widget _buildDailyChallengeCard({
    required AppPalette palette,
    required dynamic textTheme,
  }) {
    final isDone = _progressService?.isDailyChallengeCompletedToday() ?? false;

    return Material(
      color: palette.surface,
      borderRadius: AppRadius.xlRadius,
      child: InkWell(
        borderRadius: AppRadius.xlRadius,
        onTap: _openDailyChallenge,
        child: Container(
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AppRadius.xlRadius,
            border: Border.all(
              color: isDone
                  ? palette.primary.withAlpha(90)
                  : palette.gold.withAlpha(100),
              width: 1.2,
            ),
            boxShadow: palette.shadow,
          ),
          child: Row(
            children: [
              Container(
                width: AppSpace.xxl * 1.3,
                height: AppSpace.xxl * 1.3,
                decoration: BoxDecoration(
                  color: isDone ? palette.primarySoft : palette.goldSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone
                        ? palette.primary.withAlpha(80)
                        : palette.gold.withAlpha(90),
                  ),
                ),
                child: Icon(
                  isDone ? Icons.check_circle_rounded : Icons.bolt_rounded,
                  color: isDone ? palette.primary : palette.gold,
                  size: AppIcon.md,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'التحدي اليومي السريع',
                          style: textTheme.titleSmall.copyWith(
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.xs,
                            vertical: AppSpace.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: isDone ? palette.primarySoft : palette.goldSoft,
                            borderRadius: AppRadius.pillRadius,
                          ),
                          child: Text(
                            isDone ? 'مكتمل' : '+50 XP',
                            style: textTheme.caption.copyWith(
                              color: isDone ? palette.primary : palette.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      isDone
                          ? 'أُنجز تحدي اليوم بحمد الله ✓'
                          : '10 أسئلة منتقاة يومياً لتثبيت العلم ومدارسته',
                      style: textTheme.caption.copyWith(color: palette.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Container(
                padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: palette.textSubtle,
                  size: AppIcon.sm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter({
    required AppPalette palette,
    required dynamic textTheme,
  }) {
    final categories = [
      {'id': 'all', 'label': 'جميع الفنون'},
      {'id': 'quran', 'label': 'القرآن وعلومه'},
      {'id': 'tajweed', 'label': 'التجويد'},
      {'id': 'hadith', 'label': 'الحديث'},
      {'id': 'aqidah', 'label': 'العقيدة'},
      {'id': 'fiqh', 'label': 'الفقه'},
      {'id': 'usul', 'label': 'أصول الفقه'},
      {'id': 'seerah', 'label': 'السيرة'},
      {'id': 'sahaba', 'label': 'الصحابة'},
      {'id': 'prophets_names', 'label': 'الأنبياء والأسماء'},
      {'id': 'adab', 'label': 'الآداب'},
      {'id': 'arabic', 'label': 'العربية'},
    ];

    return SizedBox(
      height: AppSpace.xxl,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpace.xs),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['id'];

          return Material(
            color: isSelected ? palette.primary : palette.surface,
            borderRadius: AppRadius.pillRadius,
            child: InkWell(
              borderRadius: AppRadius.pillRadius,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = cat['id']!);
              },
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.md,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: isSelected ? palette.primary : palette.border,
                  ),
                ),
                child: Text(
                  cat['label']!,
                  style: textTheme.caption.copyWith(
                    color: isSelected ? palette.onPrimary : palette.textMuted,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFanCard({
    required FanQuiz fan,
    required AppPalette palette,
    required dynamic textTheme,
  }) {
    int fanStars = 0;
    int fanCompletedLevels = 0;
    int totalQuestionsInFan = 0;

    QuizActiveSession? fanActiveSession;
    QuizLevel? fanActiveLevel;

    for (final level in fan.levels) {
      totalQuestionsInFan += level.totalQuestions;
      final p = _userStats?.levelProgress[level.id];
      if (p != null) {
        fanStars += p.stars;
        if (p.isCompleted) fanCompletedLevels++;
      }

      if (fanActiveSession == null) {
        final active = _progressService?.getActiveSession(level.id);
        if (active != null &&
            active.currentIndex > 0 &&
            active.currentIndex < level.totalQuestions) {
          fanActiveSession = active;
          fanActiveLevel = level;
        }
      }
    }

    final maxStars = fan.levels.length * 3;
    final progressFraction = fan.levels.isEmpty
        ? 0.0
        : (fanCompletedLevels / fan.levels.length).clamp(0.0, 1.0);

    final hasActiveResume = fanActiveSession != null && fanActiveLevel != null;
    final fanTheme = palette.fanColor(fan.id);

    return Material(
      color: palette.surface,
      borderRadius: AppRadius.xlRadius,
      child: InkWell(
        borderRadius: AppRadius.xlRadius,
        onTap: () => _openFanLevels(fan),
        child: Container(
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.xlRadius,
            border: Border.all(
              color: hasActiveResume
                  ? fanTheme.primary.withValues(alpha: 0.6)
                  : fanTheme.border.withValues(alpha: 0.45),
              width: hasActiveResume ? 1.4 : 1.0,
            ),
            boxShadow: palette.shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: AppSpace.xxl * 1.3,
                    height: AppSpace.xxl * 1.3,
                    decoration: BoxDecoration(
                      color: fanTheme.softBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: fanTheme.border,
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      fan.icon,
                      color: fanTheme.primary,
                      size: AppIcon.md,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fan.title, style: textTheme.titleSmall),
                        const SizedBox(height: AppSpace.xxs),
                        Text(
                          fan.subtitle,
                          style: textTheme.caption.copyWith(color: palette.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: fanTheme.primary.withValues(alpha: 0.7),
                    size: AppIcon.md,
                  ),
                ],
              ),

              // Active Resume Box on Outside Card (if stopped mid-level)
              if (hasActiveResume) ...[
                const SizedBox(height: AppSpace.sm),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: fanTheme.softBg,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(
                      color: fanTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_circle_fill_rounded,
                        color: fanTheme.primary,
                        size: AppIcon.sm,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          'متابعة: المستوى ${fanActiveLevel.levelNumber} (السؤال ${fanActiveSession.currentIndex + 1} من ${fanActiveLevel.totalQuestions})',
                          style: textTheme.captionBold.copyWith(
                            color: fanTheme.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: AppSpace.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: fanTheme.primary,
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Text(
                          'استئناف',
                          style: textTheme.caption.copyWith(
                            color: palette.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpace.sm),
              ClipRRect(
                borderRadius: AppRadius.pillRadius,
                child: LinearProgressIndicator(
                  value: progressFraction,
                  backgroundColor: palette.surfaceMuted,
                  color: fanTheme.primary,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  Text(
                    '$fanCompletedLevels من ${fan.levels.length} مستويات',
                    style: textTheme.caption.copyWith(color: palette.textSubtle),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: AppSpace.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: fanTheme.softBg,
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Text(
                      '$totalQuestionsInFan سؤالاً',
                      style: textTheme.captionBold.copyWith(
                        color: fanTheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
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
                        '$fanStars / $maxStars',
                        style: textTheme.caption.copyWith(color: palette.gold),
                      ),
                    ],
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
