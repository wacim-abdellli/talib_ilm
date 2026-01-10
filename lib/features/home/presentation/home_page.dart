import 'package:flutter/material.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/services/asset_service.dart';
import '../../../core/services/last_activity_service.dart';
import '../../../core/services/last_sharh_service.dart';
import '../../../core/services/progress_service.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../core/utils/prayer_countdown.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../adhkar/presentation/adhkar_page.dart';
import '../../ilm/data/models/mutun_models.dart';
import '../../ilm/data/models/sharh_model.dart';
import '../../ilm/presentation/ilm_page.dart';
import '../../ilm/presentation/pages/book_view_page.dart';
import '../../library/presentation/library_page.dart';
import '../domain/models/hadith.dart';
import '../domain/services/hadith_service.dart';
import '../presentation/widgets/hadith_of_the_day_card.dart';
import '../presentation/widgets/home_section_card.dart';
import '../../prayer/data/models/prayer_models.dart';
import '../../prayer/presentation/prayer_page.dart';
import '../../prayer/presentation/widgets/next_prayer_card.dart';
import '../../../shared/widgets/pressable_card.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/pressable_scale.dart';

class HomePage extends StatefulWidget {
  final bool isActive;

  const HomePage({super.key, this.isActive = true});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LastActivityService _lastActivityService = LastActivityService();
  final LastSharhService _lastSharhService = LastSharhService();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final HadithService _hadithService = HadithService();
  final ProgressService _progressService = ProgressService();

  late Future<_ContinueData?> _continueFuture;
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
    _hadithFuture = _hadithService.getRandomHadith();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _refreshStats();
    }
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
    int? safePage = lastActivity.page;
    int? safeTotal = lastActivity.total;
    if (safePage != null && safeTotal != null && safeTotal > 0) {
      final normalizedTotal = safeTotal < safePage ? safePage : safeTotal;
      final normalizedPage = safePage.clamp(1, normalizedTotal);
      safePage = normalizedPage;
      safeTotal = normalizedTotal;
      final value = (normalizedPage / normalizedTotal) * 100;
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
      page: safePage,
      total: safeTotal,
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
          autoOpenSharhFile: data.tab == LastActivityService.tabSharh
              ? data.sharhFile
              : null,
          openLessonsOnStart: data.tab == LastActivityService.tabLessons,
        ),
      ),
    );
    if (!mounted) return;
    _refreshStats();
  }

  void _refreshStats() {
    setState(() {
      _continueFuture = _loadContinueData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              centerTitle: true,
              title: Text(
                AppStrings.navHome,
                style: AppText.heading.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              leading: Builder(
                builder: (context) => IconButton(
                  tooltip: AppStrings.tooltipMenu,
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
          ];
        },
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppUi.paddingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(context),
                const SizedBox(height: AppUi.gapLG),
                _buildSectionTitle("Today's Wisdom"),
                _buildHadithSection(),
                const SizedBox(height: AppUi.paddingMD),
                _buildDhikrCard(context),
                const SizedBox(height: AppUi.gapXL),
                _buildSectionTitle('Quick Access'),
                _buildQuickAccessGrid(context),
                const SizedBox(height: AppUi.gapXXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextPrayerCard(BuildContext context, PrayerTimesDay day) {
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
          countdownText: AppStrings.prayerRemainingShort(
            _formatCountdown(state.remaining),
          ),
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
    if (_cachedPrayerDay?.date == day.date && _countdownController != null) {
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

  void _openPrayer(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const PrayerPage()));
  }

  void _openAdhkar(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const AdhkarPage()));
  }

  void _openLibrary(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const LibraryPage()));
  }

  Widget _buildHeroSection(BuildContext context) {
    return FutureBuilder<PrayerTimesDay>(
      future: _prayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const NextPrayerCardPlaceholder();
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final day = snapshot.data!;
        _ensureCountdown(day);
        return _buildNextPrayerCard(context, day);
      },
    );
  }

  Widget _buildContinueSection(BuildContext context) {
    return FutureBuilder<_ContinueData?>(
      future: _continueFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data;
        return _ContinueLearningCard(
          data: data,
          onTap: data == null
              ? () => _openIlm(context)
              : () => _continueLearning(context, data),
        );
      },
    );
  }

  Widget _buildHadithSection() {
    return FutureBuilder<Hadith>(
      future: _hadithFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data;
        if (data == null || data.text.isEmpty) {
          return const SizedBox.shrink();
        }

        return HadithOfTheDayCard(
          initialHadith: data,
          onReload: (current) =>
              _hadithService.getRandomHadith(exclude: current),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppUi.gapSM),
      child: Text(
        title,
        style: AppText.heading.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDhikrCard(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: PressableCard(
        onTap: () => _openAdhkar(context),
        padding: AppUi.cardPadding,
        borderRadius: BorderRadius.circular(AppUi.radiusMD),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppUi.radiusMD),
          border: Border.all(
            color: AppColors.stroke,
            width: AppUi.dividerThickness,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.homeDhikrTitle,
              style: AppText.heading.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppUi.gapSM),
            Text(
              AppStrings.adhkarTitle,
              style: AppText.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppUi.gapLG),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                AppStrings.actionStartNow,
                style: AppText.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppUi.gapMD,
      mainAxisSpacing: AppUi.gapMD,
      children: [
        HomeSectionCard(
          title: AppStrings.navPrayer,
          subtitle: AppStrings.prayerNext,
          icon: Icons.access_time_rounded,
          kind: HomeSectionKind.prayer,
          onTap: () => _openPrayer(context),
        ),
        HomeSectionCard(
          title: AppStrings.navAdhkar,
          subtitle: AppStrings.adhkarMorning,
          icon: Icons.self_improvement_rounded,
          kind: HomeSectionKind.adhkar,
          onTap: () => _openAdhkar(context),
        ),
        FutureBuilder<_ContinueData?>(
          future: _continueFuture,
          builder: (context, snapshot) {
            final data = snapshot.data;
            final subtitle =
                data?.book.title ?? AppStrings.homeStartLearningTitle;
            return HomeSectionCard(
              title: AppStrings.navIlm,
              subtitle: subtitle,
              icon: Icons.menu_book_rounded,
              kind: HomeSectionKind.ilm,
              onTap: data == null
                  ? () => _openIlm(context)
                  : () => _continueLearning(context, data),
            );
          },
        ),
        HomeSectionCard(
          title: AppStrings.navLibrary,
          subtitle: AppStrings.actionReadFull,
          icon: Icons.local_library_rounded,
          kind: HomeSectionKind.library,
          onTap: () => _openLibrary(context),
        ),
      ],
    );
  }

  Widget _buildGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.greeting,
          style: AppText.headingXL.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class HomeGreeting extends StatelessWidget {
  final String greeting;
  const HomeGreeting({super.key, required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: AppText.headingXL.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppUi.gapSM),
      ],
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  final _ContinueData? data;
  final VoidCallback? onTap;

  const _ContinueLearningCard({required this.data, required this.onTap});

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
              AppStrings.homeStartLearningTitle,
              style: AppText.heading.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppUi.gapMD),
            Text(
              AppStrings.homeStartLearningMessage,
              style: AppText.body.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppUi.gapXL),
            Align(
              alignment: Alignment.centerRight,
              child: _ContinueButton(
                label: AppStrings.actionStartNow,
                onTap: onTap,
              ),
            ),
          ],
        ),
      );
    }

    final tabLabel = switch (content.tab) {
      LastActivityService.tabSharh => AppStrings.continueTabSharh,
      LastActivityService.tabLessons => AppStrings.continueTabLessons,
      _ => AppStrings.continueTabMutn,
    };

    String subtitle = AppStrings.lastRead(tabLabel);
    if (content.tab == LastActivityService.tabLessons) {
      subtitle = AppStrings.lastActivityLessons;
    } else if (content.tab == LastActivityService.tabSharh &&
        content.sharh != null) {
      subtitle = AppStrings.lastReadSharh(content.sharh!.title);
    }

    final progressPercent = content.progressPercent;
    final progressValue = progressPercent == null ? 0.0 : progressPercent / 100;

    final pageInfo = content.page == null
        ? null
        : AppStrings.lastPage(content.page!, content.total);

    return _HeroCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: AppUi.iconSizeSM,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppUi.gapSM),
              Expanded(
                child: Text(
                  content.book.title,
                  style: AppText.headingXL.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppUi.gapMD),
          Text(
            AppStrings.sectionValue(tabLabel),
            style: AppText.body.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppUi.gapLG),
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: AppUi.iconSizeXS,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppUi.gapXS),
              Text(
                AppStrings.homeProgressLabel,
                style: AppText.caption.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Text(
                progressPercent == null
                    ? AppStrings.progressUnknown
                    : AppStrings.percentLabel(progressPercent),
                style: AppText.caption.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppUi.gapMD),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppUi.radiusPill),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: AppUi.progressBarHeight,
              backgroundColor: AppColors.textPrimary.withValues(
                alpha: 0.08,
              ),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppUi.gapLG),
          Text(
            subtitle,
            style: AppText.body.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.6),
            ),
          ),
          if (pageInfo != null) ...[
            const SizedBox(height: AppUi.gapMD),
            Text(
              pageInfo,
              style: AppText.caption.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: AppUi.gapXL),
          Align(
            alignment: Alignment.centerRight,
            child: _ContinueButton(
              label: AppStrings.actionContinue,
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppUi.radiusMD),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 40,
              spreadRadius: -10,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: PressableCard(
          onTap: onTap,
          padding: AppUi.cardPadding,
          borderRadius: BorderRadius.circular(AppUi.radiusMD),
          decoration: BoxDecoration(
            gradient: AppColors.surfaceElevatedGradient,
            borderRadius: BorderRadius.circular(AppUi.radiusMD),
          ),
          child: child,
        ),
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
    return PressableScale(
      enabled: onTap != null,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.play_arrow_rounded, size: AppUi.iconSizeMD),
        label: Text(label),
      ),
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
