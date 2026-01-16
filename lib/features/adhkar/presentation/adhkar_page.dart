import 'package:flutter/material.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../core/services/adhkar_session_service.dart';
import '../data/adhkar_models.dart';
import '../data/adhkar_service.dart';
import 'adhkar_session_page.dart';
import 'after_prayer_athkar_page.dart';
import 'duas_misc_page.dart';
import 'evening_athkar_page.dart';
import 'morning_athkar_page.dart';
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

  @override
  void initState() {
    super.initState();
    _future = _service.loadCatalog();
  }

  void _reload() {
    setState(() {
      _service.resetCache();
      _future = _service.loadCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
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
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الأذكار والأدعية',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'احفظ أذكار اليوم والليلة',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
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
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 16,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '7',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
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
                    child: Row(
                      children: [
                        _buildCategoryTab(
                          'الكل',
                          Icons.grid_view_rounded,
                          true,
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryTab(
                          'الصباح',
                          Icons.wb_sunny_rounded,
                          false,
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryTab(
                          'المساء',
                          Icons.nightlight_round,
                          false,
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryTab(
                          'بعد الصلاة',
                          Icons.mosque_outlined,
                          false,
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryTab(
                          'متنوعة',
                          Icons.auto_awesome_outlined,
                          false,
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

                final items = _dashboardItems(context, catalog);

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 720 ? 3 : 2;
                    final tileAspect = constraints.maxWidth < 360
                        ? 0.78
                        : AppUi.gridAspect;
                    return GridView.builder(
                      padding: AppUi.screenPaddingCompact,
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: AppUi.gapMD,
                        mainAxisSpacing: AppUi.gapMD,
                        childAspectRatio: tileAspect,
                      ),
                      itemBuilder: (context, index) {
                        return _CategoryTile(
                          data: items[index],
                          progressLoader: items[index].showProgress
                              ? () => _progressFor(items[index])
                              : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String label, IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF59E0B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
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
    final sleeping = byId('general') ?? byId('before_prayer');

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
    if (category == null) {
      _openDuas(context);
      return;
    }
    final parsed = adhkarCategoryFromId(category.id);
    if (parsed == null) {
      _openDuas(context);
      return;
    }
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
}

class _CategoryTile extends StatelessWidget {
  final _CategoryCardData data;
  final Future<_CategoryProgress> Function()? progressLoader;

  const _CategoryTile({required this.data, this.progressLoader});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: Icon(data.icon, size: AppUi.iconSizeLG, color: data.tint),
        ),
        const SizedBox(height: AppUi.gapSM),
        Text(
          data.title,
          style: AppText.body.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppUi.gapXS),
        Text(
          _subtitleLabel(data.total),
          style: AppText.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        if (progressLoader != null) const SizedBox.shrink(),
      ],
    );

    return Material(
      color: Colors.transparent,
      elevation: 2,
      shadowColor: AppColors.primaryDark.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppUi.radiusMD),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(AppUi.radiusMD),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppUi.radiusMD),
            border: Border.all(
              color: AppColors.primaryLight,
              width: AppUi.dividerThickness,
            ),
          ),
          child: Padding(padding: AppUi.cardPadding, child: content),
        ),
      ),
    );
  }

  String _subtitleLabel(int total) {
    return '$total دعاء';
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
