import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../core/services/adhkar_session_service.dart';
import '../data/adhkar_models.dart';
import '../data/adhkar_service.dart';
import '../../quran/data/services/reading_stats_service.dart';
import 'adhkar_session_page.dart';
import 'after_prayer_athkar_page.dart';
import 'duas_misc_page.dart';
import 'evening_athkar_page.dart';
import 'morning_athkar_page.dart';
import 'sleeping_athkar_page.dart';
import 'tasbeeh_istighfar_page.dart';

class AdhkarPage extends StatefulWidget {
  const AdhkarPage({super.key});

  @override
  State<AdhkarPage> createState() => _AdhkarPageState();
}

class _AdhkarPageState extends State<AdhkarPage> {
  final AthkarService _service = AthkarService();
  final AdhkarSessionService _sessionService = AdhkarSessionService();
  late Future<AthkarCatalog> _future;
  String _selectedCategory = 'all';
  int _streak = 1;

  @override
  void initState() {
    super.initState();
    _future = _service.loadCatalog();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final streak = await ReadingStatsService().getStreak();
    if (mounted) {
      setState(() {
        _streak = streak > 0 ? streak : 1;
      });
    }
  }

  void _reload() {
    setState(() {
      _service.resetCache();
      _future = _service.loadCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Header Colors
    final headerBg = context.surfaceColor;
    final headerGradient = isDark ? AppColors.premiumDarkGradient : null;
    final headerBorder = context.outlineVariantColor;
    final titleColor = context.textPrimaryColor;
    final subtitleColor = context.textSecondaryColor;

    // Icon Container
    final iconContainerDecoration = BoxDecoration(
      color: context.primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: context.primaryColor.withValues(alpha: 0.25),
        width: 1,
      ),
    );
    final iconColor = context.primaryColor;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Column(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: headerBg,
              gradient: headerGradient,
              border: Border(bottom: BorderSide(color: headerBorder, width: 1)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: iconContainerDecoration,
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: iconColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الأذكار والأدعية',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'احفظ أذكار اليوم والليلة',
                              style: TextStyle(
                                fontSize: 14,
                                color: subtitleColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: context.goldColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: context.goldColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 16,
                              color: context.goldColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_streak',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.goldColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Category tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildCategoryTab(
                          'الكل',
                          Icons.grid_view_rounded,
                          _selectedCategory == 'all',
                          () => setState(() => _selectedCategory = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryTab(
                          'الصباح',
                          Icons.wb_sunny_rounded,
                          _selectedCategory == 'morning',
                          () => setState(() => _selectedCategory = 'morning'),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryTab(
                          'المساء',
                          Icons.nights_stay_rounded,
                          _selectedCategory == 'evening',
                          () => setState(() => _selectedCategory = 'evening'),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryTab(
                          'بعد الصلاة',
                          Icons.mosque_outlined,
                          _selectedCategory == 'after_prayer',
                          () => setState(() => _selectedCategory = 'after_prayer'),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryTab(
                          'متنوعة',
                          Icons.auto_awesome_outlined,
                          _selectedCategory == 'misc',
                          () => setState(() => _selectedCategory = 'misc'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<AthkarCatalog>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingIndicator();
                }

                if (snapshot.hasError) {
                  return EmptyState(
                    icon: Icons.error_outline,
                    title: AppStrings.adhkarLoadErrorTitle,
                    subtitle: AppStrings.adhkarLoadErrorMessage,
                    actionLabel: AppStrings.actionRetry,
                    onAction: _reload,
                  );
                }

                final catalog = snapshot.data;
                if (catalog == null || catalog.categories.isEmpty) {
                  return EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: AppStrings.adhkarEmptyTitle,
                    subtitle: AppStrings.adhkarEmptyMessage,
                    actionLabel: AppStrings.actionRetry,
                    onAction: _reload,
                  );
                }

                final allItems = _dashboardItems(context, catalog);
                final items = _filteredItems(allItems);

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    // Contextual Hero Recommendation (Visible on 'all' tab)
                    if (_selectedCategory == 'all')
                      SliverToBoxAdapter(
                        child: _buildContextualHero(context, catalog, isDark),
                      ),

                    // Grid of Adhkar Categories
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _CategoryTile(
                              data: items[index],
                              progressLoader: items[index].showProgress
                                  ? () => _progressFor(items[index])
                                  : null,
                            );
                          },
                          childCount: items.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    final activeBg = context.primaryColor;
    const activeText = Colors.white;

    final inactiveBg = context.surfaceColor;
    final inactiveBorder = context.outlineVariantColor;
    final inactiveText = context.textSecondaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(12),
            border: isActive ? null : Border.all(color: inactiveBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? activeText : inactiveText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? activeText : inactiveText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_CategoryCardData> _filteredItems(List<_CategoryCardData> all) {
    if (_selectedCategory == 'all') return all;
    if (_selectedCategory == 'morning') {
      return all.where((i) => i.id == 'morning').toList();
    }
    if (_selectedCategory == 'evening') {
      return all.where((i) => i.id == 'evening').toList();
    }
    if (_selectedCategory == 'after_prayer') {
      return all.where((i) => i.id == 'after_prayer').toList();
    }
    if (_selectedCategory == 'misc') {
      return all
          .where((i) => ['duas', 'tasbeeh', 'sleeping'].contains(i.id))
          .toList();
    }
    return all;
  }

  List<_CategoryCardData> _dashboardItems(
    BuildContext context,
    AthkarCatalog catalog,
  ) {
    AthkarCategoryData? byId(String id) => catalog.byId(id);

    final morning = byId('morning');
    final evening = byId('evening');
    final afterPrayer = byId('after_prayer');
    final duas = byId('duas');
    final tasbeeh = byId('tasbeeh');
    final sleeping =
        byId('sleeping') ?? byId('general') ?? byId('before_prayer');

    return [
      _CategoryCardData(
        id: 'morning',
        title: morning?.title ?? 'أذكار الصباح',
        total: morning?.items.length ?? 0,
        icon: Icons.wb_sunny_outlined,
        tint: AppColors.primary,
        showProgress: true,
        onTap: () => _openCategory(context, morning),
      ),
      _CategoryCardData(
        id: 'evening',
        title: evening?.title ?? 'أذكار المساء',
        total: evening?.items.length ?? 0,
        icon: Icons.nights_stay_outlined,
        tint: AppColors.primaryDark,
        showProgress: true,
        onTap: () => _openCategory(context, evening),
      ),
      _CategoryCardData(
        id: 'after_prayer',
        title: afterPrayer?.title ?? 'أذكار بعد الصلاة',
        total: afterPrayer?.items.length ?? 0,
        icon: Icons.auto_awesome_outlined,
        tint: AppColors.accent,
        onTap: () => _openCategory(context, afterPrayer),
      ),
      _CategoryCardData(
        id: 'duas',
        title: duas?.title ?? 'أدعية عامة',
        total: duas?.items.length ?? 0,
        icon: Icons.menu_book_outlined,
        tint: AppColors.textSecondary,
        onTap: () => _openDuas(context),
      ),
      _CategoryCardData(
        id: 'tasbeeh',
        title: tasbeeh?.title ?? 'عداد التسبيح',
        total: tasbeeh?.items.length ?? 0,
        icon: Icons.circle_outlined,
        tint: AppColors.primary,
        onTap: () => _openTasbeeh(context),
      ),
      _CategoryCardData(
        id: sleeping?.id ?? 'sleeping',
        title: sleeping?.title ?? 'أذكار النوم',
        total: sleeping?.items.length ?? 0,
        icon: Icons.bedtime_outlined,
        tint: AppColors.primaryDark,
        onTap: () => _openSleeping(context, sleeping),
      ),
    ];
  }

  void _openCategory(BuildContext context, AthkarCategoryData? category) {
    if (category == null) return;
    final id = _normalizeId(category.id);
    switch (id) {
      case 'morning':
        Navigator.push(
          context,
          buildFadeRoute(page: const MorningAthkarPage()),
        );
        return;
      case 'evening':
        Navigator.push(
          context,
          buildFadeRoute(page: const EveningAthkarPage()),
        );
        return;
      case 'after_prayer':
        Navigator.push(
          context,
          buildFadeRoute(page: const AfterPrayerAthkarPage()),
        );
        return;
      case 'tasbeeh':
        Navigator.push(
          context,
          buildFadeRoute(page: const TasbeehIstighfarPage(initialTabIndex: 0)),
        );
        return;
      case 'istighfar':
        Navigator.push(
          context,
          buildFadeRoute(page: const TasbeehIstighfarPage(initialTabIndex: 1)),
        );
        return;
      case 'duas':
        Navigator.push(context, buildFadeRoute(page: DuasMiscPage()));
        return;
    }

    final parsed = adhkarCategoryFromId(category.id);
    if (parsed == null) return;
    Navigator.push(
      context,
      buildFadeRoute(
        page: AdhkarSessionPage(
          category: parsed,
          titleOverride: category.title,
        ),
      ),
    );
  }

  void _openDuas(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: DuasMiscPage()));
  }

  void _openTasbeeh(BuildContext context) {
    Navigator.push(
      context,
      buildFadeRoute(page: const TasbeehIstighfarPage(initialTabIndex: 0)),
    );
  }

  void _openSleeping(BuildContext context, AthkarCategoryData? category) {
    Navigator.push(context, buildFadeRoute(page: const SleepingAthkarPage()));
  }

  String _normalizeId(String id) {
    final normalized = id.trim().toLowerCase();
    switch (normalized) {
      case 'afterprayer':
        return 'after_prayer';
      case 'after prayer':
        return 'after_prayer';
      case 'beforeprayer':
        return 'before_prayer';
      case 'tasbih':
        return 'tasbeeh';
      case 'misc':
        return 'duas';
    }
    return normalized;
  }

  Future<_CategoryProgress> _progressFor(_CategoryCardData data) async {
    final total = data.total;
    final parsed = adhkarCategoryFromId(data.id);
    if (parsed == null || total == 0) {
      return _CategoryProgress(0, total);
    }
    final counts = await _sessionService.loadCounts(parsed);
    final items = await _itemsForCategory(parsed);
    final completed = _completedCount(items, counts);
    return _CategoryProgress(completed, total);
  }

  Future<List<AthkarItem>> _itemsForCategory(AdhkarCategory category) async {
    final catalog = await _future;
    final categoryId = _normalizeId(category.id);
    return catalog.byId(categoryId)?.items ?? const [];
  }

  int _completedCount(List<AthkarItem> items, Map<String, int> counts) {
    var completed = 0;
    for (final item in items) {
      final key = item.id.isNotEmpty ? item.id : item.arabic;
      final target = item.target <= 0 ? 1 : item.target;
      final value = counts[key] ?? 0;
      if (value >= target) completed++;
    }
    return completed;
  }

  Widget _buildContextualHero(
    BuildContext context,
    AthkarCatalog catalog,
    bool isDark,
  ) {
    final now = DateTime.now();
    final hour = now.hour;
    final String recId;
    final String recTitle;
    final String recSubtitle;
    final IconData recIcon;
    final Color recColor;

    if (hour >= 4 && hour < 12) {
      recId = 'morning';
      recTitle = 'أذكار الصباح';
      recSubtitle = 'ابدأ يومك بنور الذكر وبركة الاستفتاح';
      recIcon = Icons.wb_sunny_rounded;
      recColor = context.goldColor;
    } else if (hour >= 12 && hour < 20) {
      recId = 'evening';
      recTitle = 'أذكار المساء';
      recSubtitle = 'حصّن يومك ومساءك بذكر الرحمن';
      recIcon = Icons.nights_stay_rounded;
      recColor = context.primaryColor;
    } else {
      recId = 'sleeping';
      recTitle = 'أذكار النوم';
      recSubtitle = 'اختم يومك بالسكينة والاستغفار';
      recIcon = Icons.bedtime_rounded;
      recColor = AppColors.categoryLanguage;
    }

    final cat = catalog.byId(recId) ?? catalog.byId('sleeping');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _openCategory(context, cat);
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      recColor.withValues(alpha: 0.22),
                      context.surfaceContainer,
                    ]
                  : [
                      recColor.withValues(alpha: 0.12),
                      Colors.white,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: recColor.withValues(alpha: isDark ? 0.35 : 0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: recColor.withValues(alpha: 0.16),
                  border: Border.all(
                    color: recColor.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Icon(recIcon, color: recColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: recColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'أذكار الوقت الحالي',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: recColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      recTitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      recSubtitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: recColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: recColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ابدأ الآن',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: recColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 11,
                      color: recColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final _CategoryCardData data;
  final Future<_CategoryProgress> Function()? progressLoader;

  const _CategoryTile({required this.data, this.progressLoader});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColors = _getCategoryColors(data.id);
    final accentColor = accentColors[0];
    final tileBg = context.surfaceContainer;
    final textColor = context.textPrimaryColor;
    final subtitleColor = context.textSecondaryColor;

    return Container(
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.25 : 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            data.onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Medallion + Count Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        _getCategoryIcon(data.id),
                        size: 24,
                        color: accentColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _subtitleLabel(data.id, data.total),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  data.title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'عرض الأذكار',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 9,
                      color: subtitleColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  List<Color> _getCategoryColors(String id) {
    switch (id) {
      case 'morning':
        return const [AppColors.gold, AppColors.goldDark]; // Divine Gold
      case 'evening':
        return const [AppColors.categoryLanguage, Color(0xFF2A4860)]; // Slate Dusk
      case 'after_prayer':
        return const [AppColors.primary, AppColors.primaryDark]; // Noble Teal
      case 'duas':
        return const [AppColors.categoryHadith, Color(0xFF1E683E)]; // Medina Emerald
      case 'tasbeeh':
        return const [AppColors.darkGold, AppColors.gold]; // Luminous Gold
      case 'sleeping':
        return const [Color(0xFF476070), Color(0xFF334652)]; // Night Slate
      default:
        return const [AppColors.primary, AppColors.primaryDark]; // Noble Teal
    }
  }

  IconData _getCategoryIcon(String id) {
    switch (id) {
      case 'morning':
        return Icons.wb_sunny_rounded;
      case 'evening':
        return Icons.nights_stay_rounded;
      case 'after_prayer':
        return Icons.mosque_rounded;
      case 'duas':
        return Icons.menu_book_rounded;
      case 'tasbeeh':
        return Icons.fingerprint_rounded;
      case 'sleeping':
        return Icons.bedtime_rounded;
      default:
        return Icons.auto_stories_rounded;
    }
  }

  String _subtitleLabel(String id, int total) {
    if (id == 'tasbeeh') return 'تسبيح';
    if (id == 'duas') return '$total دعاء';
    return '$total ذكراً';
  }
}

class _CategoryCardData {
  final String id;
  final String title;
  final int total;
  final IconData icon;
  final Color tint;
  final bool showProgress;
  final VoidCallback onTap;

  const _CategoryCardData({
    required this.id,
    required this.title,
    required this.total,
    required this.icon,
    required this.tint,
    required this.onTap,
    this.showProgress = false,
  });
}

class _CategoryProgress {
  final int completed;
  final int total;

  const _CategoryProgress(this.completed, this.total);
}
