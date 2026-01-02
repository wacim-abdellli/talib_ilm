import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../shared/widgets/app_overflow_menu.dart';
import '../../../shared/widgets/pressable_card.dart';
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
      appBar: AppBar(
        title: const Text('الأذكار', style: AppText.headingXL),
        actions: const [AppOverflowMenu()],
      ),
      body: FutureBuilder<AthkarCatalog>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _EmptyState(
              title: 'تعذر تحميل الأذكار',
              subtitle: 'تحقق من ملف البيانات ثم أعد المحاولة',
              onRetry: _reload,
            );
          }

          final categories = snapshot.data?.categories ?? [];

          if (categories.isEmpty) {
            return _EmptyState(
              title: 'لا توجد أذكار متاحة',
              subtitle: 'أضف بيانات الأذكار ثم أعد المحاولة',
              onRetry: _reload,
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              final meta = _metaFor(category.id) ??
                  const _CategoryMeta(
                    icon: Icons.menu_book_outlined,
                    accent: AppColors.primaryAlt,
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
          MaterialPageRoute(builder: (_) => const MorningAthkarPage()),
        );
        return;
      case 'evening':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EveningAthkarPage()),
        );
        return;
      case 'after_prayer':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AfterPrayerAthkarPage()),
        );
        return;
      case 'tasbeeh':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TasbeehIstighfarPage(initialTabIndex: 0),
          ),
        );
        return;
      case 'istighfar':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TasbeehIstighfarPage(initialTabIndex: 1),
          ),
        );
        return;
      case 'duas':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DuasMiscPage()),
        );
        return;
    }

    final parsed = adhkarCategoryFromId(category.id);
    if (parsed == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdhkarSessionPage(
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
          accent: Color(0xFFFFC857),
        );
      case 'evening':
        return const _CategoryMeta(
          icon: Icons.nights_stay_outlined,
          accent: Color(0xFF5A7DE7),
        );
      case 'after_prayer':
        return const _CategoryMeta(
          icon: Icons.auto_awesome_outlined,
          accent: Color(0xFFB388EB),
        );
      case 'tasbeeh':
        return const _CategoryMeta(
          icon: Icons.circle_outlined,
          accent: Color(0xFF4CC9A6),
        );
      case 'istighfar':
        return const _CategoryMeta(
          icon: Icons.refresh,
          accent: Color(0xFF67B3E6),
        );
      case 'duas':
        return const _CategoryMeta(
          icon: Icons.menu_book_outlined,
          accent: Color(0xFFB388EB),
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
    final gradient = LinearGradient(
      colors: [
        accent.withValues(alpha: 0.22),
        AppColors.surface,
      ],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );

    return PressableCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppColors.textPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 12),
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
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppText.caption.copyWith(
                    color: AppColors.textSecondary,
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

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurface.withValues(
          alpha: 0.6,
        );
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppText.heading),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: secondary),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
