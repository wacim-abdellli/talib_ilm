import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../data/catalogs/islamic_quiz_catalog.dart';
import '../../data/models/islamic_quiz_models.dart';
import '../../data/services/quiz_progress_service.dart';
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
          subtitle: '١٠ أسئلة منوعة من سائر فنون الشريعة',
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
              horizontal: AppSpace.xl,
              vertical: AppSpace.lg,
            ),
            children: [
              // Scholarly Rank & Stats Hero Banner
              _buildHeroStatsBanner(palette: palette, textTheme: textTheme),
              const SizedBox(height: AppSpace.lg),

              // Daily Challenge Card
              _buildDailyChallengeCard(palette: palette, textTheme: textTheme),
              const SizedBox(height: AppSpace.xl),

              // Discipline Filter Chips
              _buildCategoryFilter(palette: palette, textTheme: textTheme),
              const SizedBox(height: AppSpace.lg),

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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'رجوع',
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: Text(
            'مسابقات واختبارات الفنون',
            style: textTheme.titleSmall,
          ),
        ),
        body: content,
      ),
    );
  }

  Widget _buildHeroStatsBanner({
    required AppPalette palette,
    required dynamic textTheme,
  }) {
    final stats = _userStats;
    final xp = stats?.totalXp ?? 0;
    final stars = stats?.totalStars ?? 0;
    final completed = stats?.completedLevelsCount ?? 0;
    final rank = stats?.rankTitle ?? 'مبتدئ في طلب العلم';
    final rankIcon = stats?.rankIcon ?? '🌱';

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: palette.border),
        boxShadow: palette.shadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: AppSpace.xxl * 1.5,
                height: AppSpace.xxl * 1.5,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  rankIcon,
                  style: textTheme.title,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رتبة طالب العلم',
                      style: textTheme.caption.copyWith(color: palette.textSubtle),
                    ),
                    Text(
                      rank,
                      style: textTheme.titleSmall.copyWith(color: palette.primary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(color: palette.gold.withAlpha(70)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: palette.gold, size: AppIcon.sm),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      '$xp XP',
                      style: textTheme.label.copyWith(color: palette.gold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  icon: Icons.star_rounded,
                  iconColor: palette.gold,
                  value: '$stars',
                  label: 'نجوم الإتقان',
                  palette: palette,
                  textTheme: textTheme,
                ),
                _buildMetric(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: palette.primary,
                  value: '$completed / ${IslamicQuizCatalog.totalLevelsCount}',
                  label: 'المستويات المتقنة',
                  palette: palette,
                  textTheme: textTheme,
                ),
                _buildMetric(
                  icon: Icons.question_answer_outlined,
                  iconColor: palette.textMuted,
                  value: '${stats?.totalCorrectAnswers ?? 0}',
                  label: 'إجابة صحيحة',
                  palette: palette,
                  textTheme: textTheme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required AppPalette palette,
    required dynamic textTheme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: AppIcon.sm),
            const SizedBox(width: AppSpace.xxs),
            Text(value, style: textTheme.label.copyWith(color: palette.text)),
          ],
        ),
        const SizedBox(height: AppSpace.xxs),
        Text(label, style: textTheme.caption.copyWith(color: palette.textSubtle)),
      ],
    );
  }

  Widget _buildDailyChallengeCard({
    required AppPalette palette,
    required dynamic textTheme,
  }) {
    final isDone = _progressService?.isDailyChallengeCompletedToday() ?? false;

    return Material(
      color: palette.primarySoft,
      borderRadius: AppRadius.lgRadius,
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: _openDailyChallenge,
        child: Container(
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: palette.primary.withAlpha(90)),
          ),
          child: Row(
            children: [
              Container(
                width: AppSpace.xxl * 1.3,
                height: AppSpace.xxl * 1.3,
                decoration: BoxDecoration(
                  color: palette.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: palette.onPrimary,
                  size: AppIcon.lg,
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
                          style: textTheme.titleSmall.copyWith(color: palette.primary),
                        ),
                        if (isDone) ...[
                          const SizedBox(width: AppSpace.xs),
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.xs,
                              vertical: AppSpace.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius: AppRadius.pillRadius,
                            ),
                            child: Text(
                              'أُنجز اليوم ✓',
                              style: textTheme.caption.copyWith(color: palette.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      '١٠ أسئلة عشوائية متجددة يومياً لتثبيت العلم ومضاعفة النقاط',
                      style: textTheme.caption.copyWith(color: palette.text),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Icon(
                Icons.arrow_back_rounded,
                color: palette.primary,
                size: AppIcon.md,
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
      {'id': 'aqidah', 'label': 'العقيدة'},
      {'id': 'fiqh', 'label': 'الفقه'},
      {'id': 'hadith', 'label': 'الحديث'},
      {'id': 'quran', 'label': 'القرآن'},
      {'id': 'seerah', 'label': 'السيرة'},
      {'id': 'prophets_names', 'label': 'الأنبياء والأسماء'},
      {'id': 'adab', 'label': 'الآداب'},
    ];

    return SizedBox(
      height: AppSize.buttonH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpace.xs),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['id'];

          return ChoiceChip(
            label: Text(
              cat['label']!,
              style: textTheme.caption.copyWith(
                color: isSelected ? palette.onPrimarySoft : palette.textMuted,
              ),
            ),
            selected: isSelected,
            selectedColor: palette.primarySoft,
            backgroundColor: palette.surface,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.pillRadius,
              side: BorderSide(
                color: isSelected ? palette.primary : palette.border,
              ),
            ),
            onSelected: (_) {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = cat['id']!);
            },
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
    for (final level in fan.levels) {
      final p = _userStats?.levelProgress[level.id];
      if (p != null) {
        fanStars += p.stars;
        if (p.isCompleted) fanCompletedLevels++;
      }
    }
    final maxStars = fan.levels.length * 3;

    return Material(
      color: palette.surface,
      borderRadius: AppRadius.lgRadius,
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: () => _openFanLevels(fan),
        child: Container(
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: palette.border),
            boxShadow: palette.shadow,
          ),
          child: Row(
            children: [
              Container(
                width: AppSpace.xxl * 1.4,
                height: AppSpace.xxl * 1.4,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(fan.icon, color: palette.primary, size: AppIcon.lg),
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
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      children: [
                        Text(
                          '$fanCompletedLevels من ${fan.levels.length} مستويات',
                          style: textTheme.caption.copyWith(color: palette.textSubtle),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: palette.gold, size: AppIcon.sm),
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
              const SizedBox(width: AppSpace.sm),
              Icon(Icons.arrow_back_rounded, color: palette.textSubtle, size: AppIcon.md),
            ],
          ),
        ),
      ),
    );
  }
}
