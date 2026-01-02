import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/services/asset_service.dart';
import '../../../core/services/last_activity_service.dart';
import '../../../core/services/last_sharh_service.dart';
import '../../../core/services/progress_service.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../core/utils/prayer_countdown.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../ilm/data/models/mutun_models.dart';
import '../../ilm/data/models/sharh_model.dart';
import '../../ilm/presentation/ilm_page.dart';
import '../../ilm/presentation/pages/book_view_page.dart';
import '../../adhkar/presentation/adhkar_page.dart';
import '../../library/presentation/library_page.dart';
import '../domain/models/hadith.dart';
import '../domain/services/hadith_service.dart';
import '../presentation/widgets/hadith_of_the_day_card.dart';
import '../../prayer/data/models/prayer_models.dart';
import '../../prayer/presentation/prayer_page.dart';
import '../../prayer/presentation/widgets/next_prayer_card.dart';
import '../../../shared/widgets/pressable_card.dart';
import '../../../shared/widgets/app_overflow_menu.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LastActivityService _lastActivityService = LastActivityService();
  final LastSharhService _lastSharhService = LastSharhService();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final HadithService _hadithService = HadithService();
  final ProgressService _progressService = ProgressService();

  late final Future<_ContinueData?> _continueFuture;
  late final Future<PrayerTimesDay> _prayerFuture;
  late final Future<Hadith> _hadithFuture;
  PrayerCountdownController? _countdownController;
  PrayerTimesDay? _cachedPrayerDay;

  @override
  void initState() {
    super.initState();
    _continueFuture = _loadContinueData();
    _prayerFuture = _prayerTimeService.getPrayerTimesDay();
    _prayerFuture.then((day) {
      if (!mounted) return;
      _ensureCountdown(day);
    });
    _hadithFuture = _hadithService.getHadithOfTheDay();
  }

  @override
  void dispose() {
    _countdownController?.dispose();
    super.dispose();
  }

  Future<_ContinueData?> _loadContinueData() async {
    final lastActivity = await _lastActivityService.getLastActivity();
    if (lastActivity == null) return null;

    final program = await AssetService.loadMutunProgram();
    final book = _findBook(program, lastActivity.bookId);
    if (book == null) return null;

    var tab = lastActivity.tab;
    if (tab == LastActivityService.tabLessons && book.playlistId == null) {
      tab = LastActivityService.tabMutn;
    }
    if (tab == LastActivityService.tabSharh && book.shuruh.isEmpty) {
      tab = LastActivityService.tabMutn;
    }

    String? sharhFile = lastActivity.sharhFile;
    if (tab == LastActivityService.tabSharh && sharhFile == null) {
      sharhFile = await _lastSharhService.get(book.id);
    }

    Sharh? sharh;
    if (tab == LastActivityService.tabSharh && sharhFile != null) {
      sharh = _findSharhByFile(book, sharhFile);
    }

    int? progressPercent;
    if (lastActivity.page != null &&
        lastActivity.total != null &&
        lastActivity.total! > 0) {
      final value = (lastActivity.page! / lastActivity.total!) * 100;
      progressPercent = value.clamp(0, 100).round();
    } else {
      final progress = await _progressService.getProgress(book.id);
      if (progress != null && progress.totalLessons > 0) {
        progressPercent = progress.percent.clamp(0, 100).round();
      }
    }

    return _ContinueData(
      book: book,
      tab: tab,
      sharhFile: sharhFile,
      sharh: sharh,
      page: lastActivity.page,
      total: lastActivity.total,
      progressPercent: progressPercent,
    );
  }

  IlmBook? _findBook(MutunProgram program, String bookId) {
    for (final level in program.levels) {
      for (final book in level.books) {
        if (book.id == bookId) return book;
      }
    }
    return null;
  }

  Sharh? _findSharhByFile(IlmBook book, String file) {
    for (final sharh in book.shuruh) {
      if (sharh.file == file) return sharh;
    }
    return null;
  }

  Future<void> _continueLearning(
    BuildContext context,
    _ContinueData data,
  ) async {
    final tabIndex = switch (data.tab) {
      LastActivityService.tabSharh => 1,
      LastActivityService.tabLessons => 2,
      _ => 0,
    };

    await _lastActivityService.setLastBook(data.book.id);
    await _lastActivityService.setLastTab(data.book.id, data.tab);

    if (!context.mounted) return;

    await Navigator.push(
      context,
      buildFadeRoute(
        page: BookViewPage(
          book: data.book,
          initialTabIndex: tabIndex,
          autoOpenSharhFile:
              data.tab == LastActivityService.tabSharh ? data.sharhFile : null,
          openLessonsOnStart: data.tab == LastActivityService.tabLessons,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'الرئيسية',
          style: AppText.headingXL.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: const [AppOverflowMenu()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _HomeGreeting(
              greeting: _greetingText(),
              subtitle: _greetingSubtitle(),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Hadith>(
              future: _hadithFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                final data = snapshot.data;
                if (data == null || data.text.isEmpty) {
                  return const SizedBox.shrink();
                }

                return HadithOfTheDayCard(initialHadith: data);
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<PrayerTimesDay>(
              future: _prayerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const NextPrayerCardPlaceholder();
                }

                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final data = snapshot.data!;
                _ensureCountdown(data);
                return _buildNextPrayerCard(context, data);
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<_ContinueData?>(
              future: _continueFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final data = snapshot.data;
                return _ContinueLearningCard(
                  data: data,
                  onTap: data == null
                      ? () => _openIlm(context)
                      : () => _continueLearning(context, data),
                );
              },
            ),
            const SizedBox(height: 24),
            _QuickAccessSection(
              onOpenIlm: () => _openIlm(context),
              onOpenAdhkar: () => _openAdhkar(context),
              onOpenLibrary: () => _openLibrary(context),
            ),
          ],
        ),
      ),
    );
  }

  String _greetingText() {
    return 'السلام عليكم';
  }

  String _greetingSubtitle() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 18) return 'نهار مبارك';
    return 'مساء الخير';
  }

  Widget _buildNextPrayerCard(
    BuildContext context,
    PrayerTimesDay day,
  ) {
    final controller = _countdownController;
    if (controller == null) {
      return NextPrayerCard(
        prayer: _buildNextPrayer(day),
        onTap: () => _openPrayer(context),
      );
    }

    return ValueListenableBuilder<PrayerCountdownState>(
      valueListenable: controller.state,
      builder: (context, state, _) {
        final nextPrayer = NextPrayer(
          prayer: prayerFromLabel(state.nextPrayerName) ?? Prayer.fajr,
          time: state.nextPrayerTime,
          minutesRemaining: state.remaining.inMinutes,
        );

        return NextPrayerCard(
          prayer: nextPrayer,
          onTap: () => _openPrayer(context),
          countdownText: 'متبقي ${_formatCountdown(state.remaining)}',
        );
      },
    );
  }

  NextPrayer _buildNextPrayer(PrayerTimesDay day) {
    final now = DateTime.now();
    final time = day.prayers[day.nextPrayer] ?? now;
    final minutes = time.difference(now).inMinutes;
    return NextPrayer(
      prayer: prayerFromLabel(day.nextPrayer) ?? Prayer.fajr,
      time: time,
      minutesRemaining: minutes < 0 ? 0 : minutes,
    );
  }

  void _ensureCountdown(PrayerTimesDay day) {
    if (_cachedPrayerDay?.date == day.date &&
        _countdownController != null) {
      return;
    }

    _countdownController?.dispose();
    _cachedPrayerDay = day;
    _countdownController = PrayerCountdownController(
      day: day,
      prayerTimeService: _prayerTimeService,
    )..start();
  }

  String _formatCountdown(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _openIlm(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const IlmPage()));
  }

  void _openAdhkar(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: AdhkarPage()));
  }

  void _openLibrary(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const LibraryPage()));
  }

  void _openPrayer(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const PrayerPage()));
  }
}

class _HomeGreeting extends StatelessWidget {
  final String greeting;
  final String subtitle;

  const _HomeGreeting({
    required this.greeting,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: AppText.headingXL.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: AppText.bodyMuted.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _QuickAccessSection extends StatelessWidget {
  final VoidCallback onOpenIlm;
  final VoidCallback onOpenAdhkar;
  final VoidCallback onOpenLibrary;

  const _QuickAccessSection({
    required this.onOpenIlm,
    required this.onOpenAdhkar,
    required this.onOpenLibrary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'وصول سريع',
          style: AppText.heading.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAccessTile(
                icon: Icons.menu_book_outlined,
                label: 'العلم',
                onTap: onOpenIlm,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAccessTile(
                icon: Icons.favorite_border,
                label: 'الأذكار',
                onTap: onOpenAdhkar,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAccessTile(
                icon: Icons.local_library_outlined,
                label: 'المكتبة',
                onTap: onOpenLibrary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      borderRadius: BorderRadius.circular(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textPrimary.withValues(alpha: 0.8)),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppText.body.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  final _ContinueData? data;
  final VoidCallback? onTap;

  const _ContinueLearningCard({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = data;

    if (content == null) {
      return _HeroCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ابدأ التعلّم',
              style: AppText.heading.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ بالمتن المناسب وسنكمل معك خطوة بخطوة.',
              style: AppText.body.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: _ContinueButton(
                label: 'ابدأ الآن',
                onTap: onTap,
              ),
            ),
          ],
        ),
      );
    }

    final tabLabel = switch (content.tab) {
      LastActivityService.tabSharh => 'الشرح',
      LastActivityService.tabLessons => 'الدروس',
      _ => 'المتن',
    };

    String subtitle = 'آخر قراءة: $tabLabel';
    if (content.tab == LastActivityService.tabLessons) {
      subtitle = 'آخر نشاط: الدروس';
    } else if (content.tab == LastActivityService.tabSharh &&
        content.sharh != null) {
      subtitle = 'آخر قراءة: الشرح — ${content.sharh!.title}';
    }

    final progressPercent = content.progressPercent;
    final progressValue =
        progressPercent == null ? 0.0 : progressPercent / 100;

    final pageInfo = content.page == null
        ? null
        : content.total == null || content.total == 0
            ? 'آخر صفحة: ${content.page}'
            : 'آخر صفحة: ${content.page} / ${content.total}';

    return _HeroCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.book.title,
            style: AppText.headingXL.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'القسم: $tabLabel',
            style: AppText.body.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'التقدم',
                style: AppText.caption.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Text(
                progressPercent == null ? '—' : '$progressPercent%',
                style: AppText.caption.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progressValue),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor:
                      AppColors.textPrimary.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: AppText.body.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.6),
            ),
          ),
          if (pageInfo != null) ...[
            const SizedBox(height: 8),
            Text(
              pageInfo,
              style: AppText.caption.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: _ContinueButton(
              label: 'متابعة',
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _HeroCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: PressableCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ContinueButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      child: Text(label),
    );
  }
}

class _ContinueData {
  final IlmBook book;
  final String tab;
  final String? sharhFile;
  final Sharh? sharh;
  final int? page;
  final int? total;
  final int? progressPercent;

  const _ContinueData({
    required this.book,
    required this.tab,
    this.sharhFile,
    this.sharh,
    this.page,
    this.total,
    this.progressPercent,
  });
}
