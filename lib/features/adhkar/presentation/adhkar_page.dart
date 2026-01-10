import 'package:flutter/material.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../../shared/widgets/empty_state.dart';
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
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Adhkar & Duas',
          style: AppText.heading.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<AthkarCatalog>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: AppStrings.adhkarLoadErrorTitle,
              message: AppStrings.adhkarLoadErrorMessage,
              actionLabel: AppStrings.actionRetry,
              onAction: _reload,
            );
          }

          final catalog = snapshot.data;
          if (catalog == null || catalog.categories.isEmpty) {
            return EmptyState(
              icon: Icons.menu_book_outlined,
              title: AppStrings.adhkarEmptyTitle,
              message: AppStrings.adhkarEmptyMessage,
              actionLabel: AppStrings.actionRetry,
              onAction: _reload,
            );
          }

          final items = _dashboardItems(context, catalog);

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 720 ? 3 : 2;
              return GridView.builder(
                padding: AppUi.screenPaddingCompact,
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppUi.gapMD,
                  mainAxisSpacing: AppUi.gapMD,
                  childAspectRatio: AppUi.gridAspect,
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
        title: morning?.title ?? 'Morning Athkar',
        total: morning?.items.length ?? 0,
        icon: Icons.wb_sunny_outlined,
        tint: Colors.orange,
        showProgress: true,
        onTap: () => _openCategory(context, morning),
      ),
      _CategoryCardData(
        id: 'evening',
        title: evening?.title ?? 'Evening Athkar',
        total: evening?.items.length ?? 0,
        icon: Icons.nights_stay_outlined,
        tint: Colors.purple,
        showProgress: true,
        onTap: () => _openCategory(context, evening),
      ),
      _CategoryCardData(
        id: 'after_prayer',
        title: afterPrayer?.title ?? 'After Prayer',
        total: afterPrayer?.items.length ?? 0,
        icon: Icons.auto_awesome_outlined,
        tint: Colors.teal,
        onTap: () => _openCategory(context, afterPrayer),
      ),
      _CategoryCardData(
        id: 'duas',
        title: duas?.title ?? 'General Duas',
        total: duas?.items.length ?? 0,
        icon: Icons.menu_book_outlined,
        tint: const Color(0xFF8B6F47),
        onTap: () => _openDuas(context),
      ),
      _CategoryCardData(
        id: 'tasbeeh',
        title: tasbeeh?.title ?? 'Tasbeeh Counter',
        total: tasbeeh?.items.length ?? 0,
        icon: Icons.circle_outlined,
        tint: AppColors.secondary,
        onTap: () => _openTasbeeh(context),
      ),
      _CategoryCardData(
        id: sleeping?.id ?? 'sleeping',
        title: sleeping?.title ?? 'Sleeping Duas',
        total: sleeping?.items.length ?? 0,
        icon: Icons.bedtime_outlined,
        tint: Colors.blue,
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
          buildFadeRoute(
            page: const TasbeehIstighfarPage(initialTabIndex: 0),
          ),
        );
        return;
      case 'istighfar':
        Navigator.push(
          context,
          buildFadeRoute(
            page: const TasbeehIstighfarPage(initialTabIndex: 1),
          ),
        );
        return;
      case 'duas':
        Navigator.push(
          context,
          buildFadeRoute(page: DuasMiscPage()),
        );
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
    Navigator.push(
      context,
      buildFadeRoute(page: DuasMiscPage()),
    );
  }

  void _openTasbeeh(BuildContext context) {
    Navigator.push(
      context,
      buildFadeRoute(
        page: const TasbeehIstighfarPage(initialTabIndex: 0),
      ),
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

  int _completedCount(
    List<AthkarItem> items,
    Map<String, int> counts,
  ) {
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

  const _CategoryTile({
    required this.data,
    this.progressLoader,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: data.tint.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(
            data.icon,
            size: AppUi.iconSizeLG,
            color: data.tint,
          ),
        ),
        const SizedBox(height: AppUi.gapMD),
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
        if (progressLoader != null)
          FutureBuilder<_CategoryProgress>(
            future: progressLoader!(),
            builder: (context, snapshot) {
              final progress = snapshot.data ?? _CategoryProgress(0, data.total);
              final isComplete =
                  progress.total > 0 && progress.completed >= progress.total;
              final value = progress.total == 0
                  ? 0.0
                  : (progress.completed / progress.total).clamp(0.0, 1.0);
              final progressColor =
                  isComplete ? AppColors.success : AppColors.primary;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: value,
                    minHeight: AppUi.progressBarHeight,
                    backgroundColor:
                        AppColors.textPrimary.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation(progressColor),
                  ),
                  const SizedBox(height: AppUi.gapXS),
                  Text(
                    '${progress.completed}/${progress.total} completed today',
                    style: AppText.caption.copyWith(
                      color: progressColor,
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );

    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: AppColors.textPrimary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(AppUi.radiusMD),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(AppUi.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppUi.gapXL),
          child: content,
        ),
      ),
    );
  }

  String _subtitleLabel(int total) {
    return '$total duas';
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
