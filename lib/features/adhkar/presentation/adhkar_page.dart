import 'package:flutter/material.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_palette.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/app_button.dart';
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
import 'widgets/adhkar_category_tile.dart';
import 'widgets/adhkar_contextual_hero.dart';
import 'widgets/adhkar_header.dart';

class _DhikrSearchResult {
  final AthkarItem item;
  final AthkarCategoryData category;
  const _DhikrSearchResult({required this.item, required this.category});
}

class AdhkarPage extends StatefulWidget {
  const AdhkarPage({super.key});

  @override
  State<AdhkarPage> createState() => _AdhkarPageState();
}

class _AdhkarPageState extends State<AdhkarPage> {
  static final RegExp _tashkeelRegex = RegExp(r'[\u064B-\u0652\u0670\u0640]');

  final AthkarService _service = AthkarService();
  final AdhkarSessionService _sessionService = AdhkarSessionService();
  late Future<AthkarCatalog> _future;
  String _selectedCategory = 'all';
  String _searchQuery = '';
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

  @override
  void reassemble() {
    super.reassemble();
    _reload();
  }

  Future<void> _reload() async {
    _service.resetCache();
    setState(() {
      _future = _service.loadCatalog();
    });
  }

  List<_DhikrSearchResult> _searchCatalog(AthkarCatalog catalog, String query) {
    final cleanQuery = query.toLowerCase().replaceAll(_tashkeelRegex, '').trim();
    if (cleanQuery.isEmpty) return const [];

    final results = <_DhikrSearchResult>[];
    for (final cat in catalog.categories) {
      for (final item in cat.items) {
        final cleanArabic = item.arabic.toLowerCase().replaceAll(_tashkeelRegex, '');
        final cleanFadl = item.fadl.toLowerCase().replaceAll(_tashkeelRegex, '');
        final cleanCat = cat.title.toLowerCase().replaceAll(_tashkeelRegex, '');
        if (cleanArabic.contains(cleanQuery) ||
            cleanFadl.contains(cleanQuery) ||
            cleanCat.contains(cleanQuery)) {
          results.add(_DhikrSearchResult(item: item, category: cat));
        }
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.bg,
      body: Column(
        children: [
          AdhkarHeader(
            streak: _streak,
            selectedCategory: _selectedCategory,
            onSelectCategory: (cat) => setState(() => _selectedCategory = cat),
            onSearch: (q) => setState(() => _searchQuery = q.trim()),
          ),
          Expanded(
            child: FutureBuilder<AthkarCatalog>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingIndicator();
                }

                if (snapshot.hasError) {
                  return AppEmptyState(
                    icon: Icons.error_outline,
                    title: AppStrings.adhkarLoadErrorTitle,
                    subtitle: AppStrings.adhkarLoadErrorMessage,
                    action: AppButton(
                      label: AppStrings.actionRetry,
                      onPressed: _reload,
                    ),
                  );
                }

                final catalog = snapshot.data;
                if (catalog == null || catalog.categories.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.menu_book_outlined,
                    title: AppStrings.adhkarEmptyTitle,
                    subtitle: AppStrings.adhkarEmptyMessage,
                    action: AppButton(
                      label: AppStrings.actionRetry,
                      onPressed: _reload,
                    ),
                  );
                }

                // If searching, show search results list
                if (_searchQuery.isNotEmpty) {
                  final searchResults = _searchCatalog(catalog, _searchQuery);
                  if (searchResults.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'لا توجد نتائج',
                      subtitle: 'لم نجد أذكاراً تطابق "$_searchQuery"',
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      AppSpace.lg,
                      AppSpace.md,
                      AppSpace.lg,
                      AppSize.navClearance(context),
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final res = searchResults[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.md),
                        child: AppCard(
                          onTap: () => _openCategory(context, res.category),
                          padding: AppSpace.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsetsDirectional.symmetric(
                                      horizontal: AppSpace.sm,
                                      vertical: AppSpace.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.primarySoft,
                                      borderRadius: AppRadius.pillRadius,
                                    ),
                                    child: Text(
                                      res.category.title,
                                      style: context.text.caption.copyWith(
                                        color: palette.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (res.item.countDescription.isNotEmpty)
                                    Text(
                                      res.item.countDescription,
                                      style: context.text.caption.copyWith(
                                        color: palette.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpace.sm),
                              Text(
                                res.item.arabic,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.sacred.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.bold,
                                  height: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                final allItems = _dashboardItems(context, catalog);
                final items = _filteredItems(allItems);

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      // Contextual Hero Recommendation (Visible on 'all' tab)
                      if (_selectedCategory == 'all')
                        SliverToBoxAdapter(
                          child: AdhkarContextualHero(
                            catalog: catalog,
                            onOpenCategory: _openCategory,
                          ),
                        ),

                      // Grid of Adhkar Categories
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpace.lg,
                          AppSpace.sm,
                          AppSpace.lg,
                          AppSize.navClearance(context),
                        ),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSpace.md,
                            mainAxisSpacing: AppSpace.md,
                            childAspectRatio: 0.86,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return CategoryTile(
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<CategoryCardData> _filteredItems(List<CategoryCardData> all) {
    if (_selectedCategory == 'all') return all;
    if (_selectedCategory == 'morning') {
      return all.where((i) => i.id == 'morning').toList();
    }
    if (_selectedCategory == 'evening') {
      return all.where((i) => i.id == 'evening').toList();
    }
    if (_selectedCategory == 'after_prayer') {
      return all.where((i) => ['after_prayer', 'prayer_sunan'].contains(i.id)).toList();
    }
    if (_selectedCategory == 'prayer_sunan') {
      return all.where((i) => ['prayer_sunan', 'after_prayer'].contains(i.id)).toList();
    }
    if (_selectedCategory == 'daily') {
      return all
          .where((i) => [
                'waking',
                'sleeping',
                'home',
                'mosque_adhan',
                'wudu_taharah',
                'food_drink',
                'travel',
                'nature_weather',
                'social_manners',
              ].contains(i.id))
          .toList();
    }
    if (_selectedCategory == 'distress') {
      return all.where((i) => ['distress', 'sickness_funerals'].contains(i.id)).toList();
    }
    if (_selectedCategory == 'tasbeeh') {
      return all.where((i) => ['tasbeeh', 'istighfar'].contains(i.id)).toList();
    }
    if (_selectedCategory == 'duas') {
      return all.where((i) => ['duas', 'fasting_hajj'].contains(i.id)).toList();
    }
    return all.where((i) => i.id == _selectedCategory).toList();
  }

  List<CategoryCardData> _dashboardItems(
    BuildContext context,
    AthkarCatalog catalog,
  ) {
    return catalog.categories.map((cat) {
      final isMorning = cat.id == 'morning';
      final isEvening = cat.id == 'evening';

      return CategoryCardData(
        id: cat.id,
        title: cat.title,
        total: cat.items.length,
        icon: _iconForCategory(cat.id),
        showProgress: isMorning || isEvening,
        onTap: () => _openCategory(context, cat),
      );
    }).toList();
  }

  IconData _iconForCategory(String id) {
    switch (id) {
      case 'morning':
        return Icons.wb_sunny_rounded;
      case 'evening':
        return Icons.nights_stay_rounded;
      case 'after_prayer':
        return Icons.mosque_rounded;
      case 'prayer_sunan':
        return Icons.access_time_filled_rounded;
      case 'waking':
        return Icons.wb_twilight_rounded;
      case 'sleeping':
        return Icons.bedtime_rounded;
      case 'mosque_adhan':
        return Icons.notifications_active_rounded;
      case 'home':
        return Icons.cottage_rounded;
      case 'wudu_taharah':
      case 'wudu_food':
        return Icons.clean_hands_rounded;
      case 'food_drink':
        return Icons.restaurant_rounded;
      case 'travel':
        return Icons.explore_rounded;
      case 'distress':
        return Icons.shield_rounded;
      case 'sickness_funerals':
        return Icons.healing_rounded;
      case 'nature_weather':
        return Icons.cloud_queue_rounded;
      case 'social_manners':
        return Icons.diversity_3_rounded;
      case 'fasting_hajj':
        return Icons.brightness_medium_rounded;
      case 'tasbeeh':
        return Icons.fingerprint_rounded;
      case 'istighfar':
        return Icons.restart_alt_rounded;
      case 'duas':
      default:
        return Icons.menu_book_rounded;
    }
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
        Navigator.push(context, buildFadeRoute(page: const DuasMiscPage()));
        return;
      case 'sleeping':
        Navigator.push(context, buildFadeRoute(page: const SleepingAthkarPage()));
        return;
    }

    final parsed = adhkarCategoryFromId(category.id) ?? AdhkarCategory.general;
    Navigator.push(
      context,
      buildFadeRoute(
        page: AdhkarSessionPage(
          category: parsed,
          categoryId: category.id,
          titleOverride: category.title,
          categoryData: category,
        ),
      ),
    );
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

  Future<CategoryProgress> _progressFor(CategoryCardData item) async {
    final category = adhkarCategoryFromId(item.id);
    if (category == null) return CategoryProgress(0, item.total);
    final counts = await _sessionService.loadCounts(category);
    final completed = counts.values.where((c) => c > 0).length;
    return CategoryProgress(completed, item.total);
  }
}
