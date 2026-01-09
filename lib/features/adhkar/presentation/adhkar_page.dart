import 'package:flutter/material.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../shared/widgets/pressable_card.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../../shared/widgets/empty_state.dart';
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
      appBar: UnifiedAppBar(
        title: AppStrings.adhkarTitle,
        showMenu: true,
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

          final categories = snapshot.data?.categories ?? [];

          if (categories.isEmpty) {
            return EmptyState(
              icon: Icons.menu_book_outlined,
              title: AppStrings.adhkarEmptyTitle,
              message: AppStrings.adhkarEmptyMessage,
              actionLabel: AppStrings.actionRetry,
              onAction: _reload,
            );
          }

          return GridView.builder(
            padding: AppUi.screenPaddingCompact,
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppUi.gapLG,
              mainAxisSpacing: AppUi.gapLG,
              childAspectRatio: AppUi.gridAspect,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              final meta = _metaFor(category.id) ??
                  const _CategoryMeta(
                    icon: Icons.menu_book_outlined,
                    accent: AppColors.primary,
                  );
              return _CategoryTile(
                title: category.title,
                subtitle: category.subtitle,
                icon: meta.icon,
                accent: meta.accent,
                onTap: () => _openCategory(context, category),
              );
            },
          );
        },
      ),
    );
  }

  void _openCategory(BuildContext context, AthkarCategoryData category) {
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

  _CategoryMeta? _metaFor(String id) {
    switch (_normalizeId(id)) {
      case 'morning':
        return const _CategoryMeta(
          icon: Icons.wb_sunny_outlined,
          accent: AppColors.primary,
        );
      case 'evening':
        return const _CategoryMeta(
          icon: Icons.nights_stay_outlined,
          accent: AppColors.primary,
        );
      case 'after_prayer':
        return const _CategoryMeta(
          icon: Icons.auto_awesome_outlined,
          accent: AppColors.primary,
        );
      case 'tasbeeh':
        return const _CategoryMeta(
          icon: Icons.circle_outlined,
          accent: AppColors.primary,
        );
      case 'istighfar':
        return const _CategoryMeta(
          icon: Icons.refresh_outlined,
          accent: AppColors.primary,
        );
      case 'duas':
        return const _CategoryMeta(
          icon: Icons.menu_book_outlined,
          accent: AppColors.primary,
        );
    }
    return null;
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
}

class _CategoryMeta {
  final IconData icon;
  final Color accent;

  const _CategoryMeta({
    required this.icon,
    required this.accent,
  });
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onTap,
      padding: AppUi.cardPadding,
      borderRadius: BorderRadius.circular(AppUi.radiusCard),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppUi.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppUi.iconBoxSize,
            height: AppUi.iconBoxSize,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppUi.radiusSMPlus),
            ),
            child: Icon(
              icon,
              color: AppColors.textPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppUi.gapMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppUi.gapXSPlus),
                Text(
                  subtitle,
                  style: AppText.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
