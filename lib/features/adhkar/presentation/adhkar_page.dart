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
import 'widgets/adhkar_notification_sheet.dart';

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
            onNotifications: () => AdhkarNotificationSheet.show(context),
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
                            childAspectRatio: 0.94,
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
      return all
          .where((i) => [
                'prayer_sunan',
                'prayer_opening',
                'prayer_rukuh_sujud',
                'tashahhud_salat',
                'prayer_before_salam',
                'witr_istikharah',
                'after_prayer',
              ].contains(i.id))
          .toList();
    }
    if (_selectedCategory == 'daily') {
      return all
          .where((i) => [
                'waking',
                'sleeping',
                'home',
                'mosque_adhan',
                'adhan_iqamah',
                'mosque_etiquette',
                'wudu_taharah',
                'food_drink',
                'travel',
                'nature_weather',
                'social_manners',
              ].contains(i.id))
          .toList();
    }
    if (_selectedCategory == 'distress') {
      return all
          .where((i) => [
                'distress',
                'distress_relief',
                'protection_ruqyah',
                'sickness_ruqyah',
                'funerals_graves',
                'sickness_funerals',
              ].contains(i.id))
          .toList();
    }
    if (_selectedCategory == 'tasbeeh') {
      return all.where((i) => ['tasbeeh', 'istighfar'].contains(i.id)).toList();
    }
    if (_selectedCategory == 'duas') {
      return all
          .where((i) => [
                'duas',
                'quranic_duas',
                'prophetic_duas',
                'fasting_adhkar',
                'hajj_umrah',
                'fasting_hajj',
              ].contains(i.id))
          .toList();
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
        subtitle: cat.subtitle.trim().isNotEmpty
            ? cat.subtitle.trim()
            : _fallbackSubtitle(cat.id),
        total: cat.items.length,
        icon: _iconForCategory(cat.id),
        showProgress: isMorning || isEvening,
        onTap: () => _openCategory(context, cat),
      );
    }).toList();
  }

  String _fallbackSubtitle(String id) {
    switch (id) {
      case 'morning':
        return 'الحفظ والسكينة وبداية اليوم بذكر الله';
      case 'evening':
        return 'حصن المسلم والسكينة عند إقبال الليل';
      case 'after_prayer':
        return 'الاستغفار والتسبيح دبر الصلوات المكتوبة';
      case 'prayer_sunan':
        return 'أدعية الاستفتاح والركوع والسجود وقنوت الوتر';
      case 'prayer_opening':
        return 'استفتاح الفريضة وقيام الليل الثابت عن النبي ﷺ';
      case 'prayer_rukuh_sujud':
        return 'تسبيحات الركوع والرفع منه والسجود وسجود التلاوة';
      case 'tashahhud_salat':
        return 'صيغ التشهد المأثورة والصلاة على النبي ﷺ بعد التشهد';
      case 'prayer_before_salam':
        return 'الاستعاذة من الأربع وجوامع الدعاء في دبر الصلاة';
      case 'witr_istikharah':
        return 'دعاء الاستخارة وقنوت الوتر وقيام الليل والذكر بعده';
      case 'waking':
        return 'حمد الله والثناء عليه بعد بعث الروح';
      case 'sleeping':
        return 'الحفظ والسكينة وأدعية النوم والاستيقاظ';
      case 'mosque_adhan':
        return 'المشي إلى المسجد ودخوله وإجابة المؤذن';
      case 'adhan_iqamah':
        return 'إجابة المؤذن والصلاة على النبي ﷺ ودعاء الوسيلة';
      case 'mosque_etiquette':
        return 'المشي إلى المسجد ودخوله باليمين والخروج منه باليسار';
      case 'home':
        return 'أذكار الدخول والخروج والسلام على الأهل';
      case 'wudu_taharah':
      case 'wudu_food':
        return 'أذكار الوضوء والخلاء وطهارة البدن';
      case 'food_drink':
        return 'الآداب النبوية عند الأكل والشرب والضيافة';
      case 'travel':
        return 'الحفظ والمعونة والبركة في السفر والترحال';
      case 'distress':
      case 'distress_relief':
        return 'دعاء ذي النون وتفريج الهموم والغموم وقضاء الدين';
      case 'protection_ruqyah':
        return 'التحصين من نزغات الشيطان والرؤيا المكروهة ودفع العين';
      case 'sickness_funerals':
        return 'عيادة المريض والرقية والمصائب والصبر';
      case 'sickness_ruqyah':
        return 'عيادة المريض، الرقية النبوية، والتعوذ عند الألم';
      case 'funerals_graves':
        return 'تلقين المحتضر، صلاة الجنازة، التعزية، وزيارة القبور';
      case 'nature_weather':
        return 'أدعية الرياح ونزول المطر ورؤية الهلال';
      case 'social_manners':
        return 'كفارة المجلس وإفشاء السلام والعطاس وسجود الشكر';
      case 'fasting_hajj':
        return 'أدعية الصائم والإفطار ومناسك الحج';
      case 'fasting_adhkar':
        return 'رؤية الهلال، سنن الإفطار والسحور، ودعاء ليلة القدر';
      case 'hajj_umrah':
        return 'التلبية، الطواف، السعي، عرفة، ومناسك الحج والعمرة';
      case 'tasbeeh':
        return 'فضائل التسبيح والتحميد والأجور المضاعفة';
      case 'istighfar':
        return 'صيغ الاستغفار الثابتة وأبواب الرحمة';
      case 'quranic_duas':
        return 'أدعية الأنبياء والرسل والراسخين في العلم من القرآن';
      case 'prophetic_duas':
        return 'أكمل وأجمع الأدعية المأثورة عن رسول الله ﷺ';
      case 'duas':
      default:
        return 'جوامع الدعاء من القرآن وصحيح السنة';
    }
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
      case 'prayer_opening':
        return Icons.auto_awesome_rounded;
      case 'prayer_rukuh_sujud':
        return Icons.accessibility_new_rounded;
      case 'tashahhud_salat':
        return Icons.favorite_border_rounded;
      case 'prayer_before_salam':
        return Icons.mark_chat_read_rounded;
      case 'witr_istikharah':
        return Icons.nights_stay_outlined;
      case 'waking':
        return Icons.wb_twilight_rounded;
      case 'sleeping':
        return Icons.bedtime_rounded;
      case 'mosque_adhan':
      case 'adhan_iqamah':
        return Icons.notifications_active_rounded;
      case 'mosque_etiquette':
        return Icons.mosque_rounded;
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
      case 'distress_relief':
        return Icons.shield_rounded;
      case 'protection_ruqyah':
        return Icons.verified_user_rounded;
      case 'sickness_funerals':
      case 'sickness_ruqyah':
        return Icons.healing_rounded;
      case 'funerals_graves':
        return Icons.hourglass_bottom_rounded;
      case 'nature_weather':
        return Icons.cloud_queue_rounded;
      case 'social_manners':
        return Icons.diversity_3_rounded;
      case 'fasting_hajj':
      case 'fasting_adhkar':
        return Icons.brightness_medium_rounded;
      case 'hajj_umrah':
        return Icons.explore_rounded;
      case 'tasbeeh':
        return Icons.fingerprint_rounded;
      case 'istighfar':
        return Icons.restart_alt_rounded;
      case 'quranic_duas':
        return Icons.menu_book_rounded;
      case 'prophetic_duas':
        return Icons.format_quote_rounded;
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
