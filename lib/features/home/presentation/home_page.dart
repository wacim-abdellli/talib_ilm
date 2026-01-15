import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:talib_ilm/core/utils/responsive.dart';
import 'package:talib_ilm/shared/widgets/app_popup.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/services/asset_service.dart';
import '../../../core/services/last_activity_service.dart';
import '../../../core/services/last_sharh_service.dart';
import '../../../core/services/progress_service.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../ilm/data/models/mutun_models.dart';
import '../../ilm/data/models/sharh_model.dart';
import '../../ilm/presentation/ilm_page.dart';
import '../../ilm/presentation/pages/book_view_page.dart';
import '../../favorites/presentation/favorites_page.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/models/favorite_item.dart';
import '../domain/models/hadith.dart';
import '../domain/services/hadith_service.dart';
import '../../prayer/data/models/prayer_models.dart';
import '../../prayer/presentation/qibla_page.dart';
import '../../library/presentation/library_page.dart';
import '../../adhkar/presentation/adhkar_page.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/app_drawer.dart';

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
  final FavoritesService _favoritesService = FavoritesService();
  final ProgressService _progressService = ProgressService();
  late Future<_ContinueData?> _continueFuture;
  late final Future<PrayerTimesDay> _prayerFuture;
  final ValueNotifier<Hadith?> _hadithNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _hadithFavoriteNotifier = ValueNotifier(false);

  Hadith? _latestHadith;
  Timer? _dateSwapTimer;
  bool _showGregorian = true;
  @override
  void initState() {
    super.initState();
    _continueFuture = _loadContinueData();
    _prayerFuture = _prayerTimeService.getPrayerTimesDay();

    _loadHadith().then((hadith) {
      if (!mounted) return;
      _hadithNotifier.value = hadith;
    });
    _dateSwapTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _showGregorian = !_showGregorian;
      });
    });
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
    _hadithNotifier.dispose();
    _hadithFavoriteNotifier.dispose();
    _dateSwapTimer?.cancel();
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

  Future<Hadith> _loadHadith({Hadith? exclude}) async {
    final hadith = await _hadithService.getRandomHadith(exclude: exclude);
    _latestHadith = hadith;
    await _loadHadithFavoriteState(hadith);
    return hadith;
  }

  String _hadithId(Hadith hadith) {
    return '${hadith.text}||${hadith.source}';
  }

  Future<void> _loadHadithFavoriteState(Hadith hadith) async {
    final isFavorite = await _favoritesService.isFavorite(
      FavoriteType.hadith,
      _hadithId(hadith),
    );
    if (!mounted) return;
    _hadithFavoriteNotifier.value = isFavorite;
  }

  Future<void> _toggleHadithFavorite(Hadith hadith) async {
    final saved = await _favoritesService.toggle(
      FavoriteItem(
        type: FavoriteType.hadith,
        id: _hadithId(hadith),
        title: hadith.text,
        subtitle: hadith.source,
      ),
    );
    if (!mounted) return;
    _hadithFavoriteNotifier.value = saved;
  }

  void _copyHadith(Hadith hadith) {
    final content = hadith.source.isNotEmpty
        ? '${hadith.text}\n\n${hadith.source}'
        : hadith.text;

    Clipboard.setData(ClipboardData(text: content));

    AppPopup.show(
      context: context,
      title: 'تم النسخ',
      message: 'تم نسخ الحديث إلى الحافظة',
      icon: Icons.copy_rounded,
    );
  }

  Future<void> _reloadHadith(Hadith? current) async {
    final next = await _loadHadith(exclude: current);
    if (!mounted) return;
    _hadithNotifier.value = next;
  }

  Future<void> _handlePullRefresh() async {
    await _reloadHadith(_hadithNotifier.value ?? _latestHadith);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final hasUnread = _hasUnread();
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F3),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/images/logo.png',
          height: responsive.hp(15),
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(responsive.smallGap),
          child: Container(
            height: responsive.smallGap,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEFE7DA), Color(0x00FAF8F3)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B7355).withValues(alpha: 0.08),
                  blurRadius: responsive.sp(8),
                  offset: Offset(0, responsive.sp(2)),
                ),
              ],
            ),
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: AppStrings.tooltipMenu,
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu),
            color: const Color(0xFF5D4E37),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textSecondary,
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: responsive.smallGap),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handlePullRefresh,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  SizedBox(height: responsive.smallGap),
                  _buildHeroGreetingCard(),
                  // Countdown card moved to PrayerPage
                  // SizedBox(height: responsive.largeGap),
                  // _buildPrayerCountdownCard(context),
                  SizedBox(height: responsive.largeGap),
                  _buildContinueSection(context),
                  SizedBox(height: responsive.mediumGap),
                  _buildHadithSection(),
                  SizedBox(height: responsive.hp(4)),
                  _buildQuickActionsRow(context),
                  SizedBox(height: responsive.hp(6)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _hasUnread() => false;

  String _formatHijriDate(DateTime date) {
    HijriCalendar.setLocal('ar');
    final hijri = HijriCalendar.fromDate(date);
    return '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}';
  }

  String _formatGregorianDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  void _openIlm(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const IlmPage()));
  }

  void _openAdhkar(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const AdhkarPage()));
  }

  void _openLibrary(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const LibraryPage()));
  }

  void _openQibla(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const QiblaPage()));
  }

  void _openFavorites(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const FavoritesPage()));
  }

  Widget _buildHeroGreetingCard() {
    return FutureBuilder<PrayerTimesDay>(
      future: _prayerFuture,
      builder: (context, snapshot) {
        final responsive = Responsive(context);
        final day = snapshot.data;
        final location = day?.city ?? AppStrings.locationDefaultCity;
        final date = day?.date ?? DateTime.now();

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.safeHorizontalPadding,
          ),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: responsive.wp(92)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(responsive.wp(5)),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF5),
                  borderRadius: BorderRadius.circular(AppUi.radiusMD),
                  border: Border.all(
                    color: const Color(0xFFE8DCC8),
                    width: AppUi.dividerThickness,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'السلام عليكم',
                            style: TextStyle(
                              fontSize: responsive.sp(18),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2C1810),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: responsive.smallGap),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsive.wp(2.2),
                                  vertical: responsive.hp(0.6),
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFB8860B,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    AppUi.radiusPill,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: responsive.sp(14),
                                      color: const Color(0xFFB8860B),
                                    ),
                                    SizedBox(width: responsive.smallGap * 0.5),
                                    Text(
                                      location,
                                      style: TextStyle(
                                        fontSize: responsive.sp(12),
                                        color: const Color(0xFF2C1810),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.smallGap * 0.5),
                    Text(
                      AppStrings.appTagline,
                      style: TextStyle(
                        fontSize: responsive.sp(13),
                        color: const Color(0xFF8B7355),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: responsive.smallGap),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeOut,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Text(
                        _showGregorian
                            ? _formatGregorianDate(date)
                            : _formatHijriDate(date),
                        key: ValueKey(_showGregorian),
                        style: TextStyle(
                          fontSize: responsive.sp(12),
                          color: const Color(0xFFB8860B),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinueSection(BuildContext context) {
    final responsive = Responsive(context);
    return FutureBuilder<_ContinueData?>(
      future: _continueFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data;
        final tabLabel = data == null
            ? null
            : switch (data.tab) {
                LastActivityService.tabSharh => AppStrings.continueTabSharh,
                LastActivityService.tabLessons => AppStrings.continueTabLessons,
                _ => AppStrings.continueTabMutn,
              };
        final sectionLabel = tabLabel == null
            ? null
            : AppStrings.sectionValue(tabLabel);
        final page = data?.page;
        final total = data?.total;
        final pageInfo = page == null ? null : AppStrings.lastPage(page, total);
        final progressLabel = data == null
            ? AppStrings.homeStartLearningMessage
            : pageInfo == null
            ? (sectionLabel ?? '')
            : '$sectionLabel • $pageInfo';
        final percentText = data?.progressPercent == null
            ? null
            : '${data!.progressPercent}%';
        final progressValue = data == null
            ? 0.0
            : ((data.progressPercent ?? 0) / 100).clamp(0.0, 1.0);

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.safeHorizontalPadding,
          ),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: responsive.wp(92)),
              child: PressableScale(
                pressedScale: AppUi.pressScale,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppUi.radiusMD),
                  child: InkWell(
                    onTap: data == null
                        ? () => _openIlm(context)
                        : () => _continueLearning(context, data),
                    borderRadius: BorderRadius.circular(AppUi.radiusMD),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(responsive.wp(5)),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F1E8),
                        borderRadius: BorderRadius.circular(AppUi.radiusMD),
                        border: Border.all(
                          color: const Color(0xFFE8DCC8),
                          width: AppUi.dividerThickness,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: responsive.wp(12),
                            height: responsive.wp(12),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFD4AF37,
                              ).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.menu_book,
                              color: const Color(0xFFB8860B),
                              size: responsive.largeIcon,
                            ),
                          ),
                          SizedBox(width: responsive.mediumGap),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data == null
                                      ? 'ابدأ رحلة التعلّم'
                                      : 'واصل التعلّم',
                                  style: TextStyle(
                                    fontSize: responsive.sp(16),
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2C1810),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: responsive.smallGap * 0.5),
                                Text(
                                  data == null
                                      ? 'استكشف الكتب المتاحة'
                                      : 'الكتاب: ${data.book.title}',
                                  style: TextStyle(
                                    fontSize: data == null
                                        ? responsive.sp(13)
                                        : responsive.sp(14),
                                    fontWeight: data == null
                                        ? FontWeight.w400
                                        : FontWeight.w600,
                                    color: data == null
                                        ? const Color(0xFF5D4E37)
                                        : const Color(0xFF2C1810),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: responsive.smallGap),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppUi.radiusXS,
                                  ),
                                  child: LinearProgressIndicator(
                                    value: progressValue,
                                    backgroundColor: const Color(0xFFE8DCC8),
                                    valueColor: const AlwaysStoppedAnimation(
                                      Color(0xFFB8860B),
                                    ),
                                    minHeight: responsive.sp(4),
                                  ),
                                ),
                                SizedBox(height: responsive.smallGap * 0.5),
                                Text(
                                  percentText == null
                                      ? progressLabel
                                      : '$progressLabel • $percentText',
                                  style: TextStyle(
                                    fontSize: responsive.sp(11),
                                    color: const Color(0xFF8B7355),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHadithSection() {
    final responsive = Responsive(context);
    return ValueListenableBuilder<Hadith?>(
      valueListenable: _hadithNotifier,
      builder: (context, data, _) {
        if (data == null || data.text.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.safeHorizontalPadding,
          ),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: responsive.wp(92)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(responsive.wp(5)),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(AppUi.radiusMD),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B7355).withValues(alpha: 0.06),
                      blurRadius: responsive.sp(8),
                      offset: Offset(0, responsive.sp(2)),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '﴿ حديث اليوم ﴾',
                            style: TextStyle(
                              fontSize: responsive.sp(14),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5D4E37),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _reloadHadith(data),
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: AppStrings.actionUpdate,
                          color: const Color(0xFF8B7355),
                          iconSize: responsive.mediumIcon,
                        ),
                        IconButton(
                          onPressed: () => _copyHadith(data),
                          icon: const Icon(Icons.content_copy_outlined),
                          tooltip: AppStrings.actionCopy,
                          color: const Color(0xFF8B7355),
                          iconSize: responsive.mediumIcon,
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: _hadithFavoriteNotifier,
                          builder: (context, isFavorite, _) {
                            return IconButton(
                              onPressed: () => _toggleHadithFavorite(data),
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                              ),
                              tooltip: AppStrings.actionSave,
                              color: isFavorite
                                  ? const Color(0xFFB8860B)
                                  : const Color(0xFF8B7355),
                              iconSize: responsive.mediumIcon,
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.mediumGap),
                    Text(
                      data.text,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: responsive.sp(16),
                        height: 1.8,
                        color: const Color(0xFF2C1810),
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.fade,
                    ),
                    SizedBox(height: responsive.mediumGap),
                    Divider(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                      thickness: responsive.sp(1),
                    ),
                    SizedBox(height: responsive.smallGap),
                    Text(
                      data.source,
                      style: TextStyle(
                        fontSize: responsive.sp(12),
                        color: const Color(0xFF8B7355),
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    final responsive = Responsive(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.safeHorizontalPadding,
      ),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: responsive.wp(92)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickAction(
                Icons.menu_book,
                'الأذكار',
                () => _openAdhkar(context),
              ),
              _buildQuickAction(
                Icons.explore_outlined,
                'القبلة',
                () => _openQibla(context),
              ),
              _buildQuickAction(
                Icons.favorite_border,
                'المفضلة',
                () => _openFavorites(context),
              ),
              _buildQuickAction(
                Icons.library_books_outlined,
                'المكتبة',
                () => _openLibrary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    final responsive = Responsive(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: responsive.wp(14.5),
            height: responsive.wp(14.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F1E8),
              borderRadius: BorderRadius.circular(responsive.sp(14)),
              border: Border.all(
                color: const Color(0xFFE8DCC8),
                width: AppUi.dividerThickness,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFB8860B),
              size: responsive.sp(26),
            ),
          ),
          SizedBox(height: responsive.smallGap),
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.sp(11),
              color: const Color(0xFF5D4E37),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
