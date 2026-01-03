import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/services/adhkar_session_service.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../../../core/services/favorites_service.dart';
import '../../../core/models/favorite_item.dart';
import '../data/adhkar_models.dart';
import '../data/adhkar_service.dart';

class AdhkarSessionPage extends StatefulWidget {
  final AdhkarCategory category;
  final String? titleOverride;
  final String? contextLabel;

  const AdhkarSessionPage({
    super.key,
    required this.category,
    this.titleOverride,
    this.contextLabel,
  });

  @override
  State<AdhkarSessionPage> createState() => _AdhkarSessionPageState();
}

class _AdhkarSessionPageState extends State<AdhkarSessionPage> {
  final AthkarService _athkarService = AthkarService();
  final AdhkarSessionService _sessionService = AdhkarSessionService();
  final FavoritesService _favoritesService = FavoritesService();

  late final PageController _pageController;
  List<AthkarItem> _items = const [];
  Map<String, int> _counts = {};
  String? _categoryTitle;
  int _index = 0;
  int _count = 0;
  bool _loading = true;
  bool _ritualLocked = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final catalog = await _athkarService.loadCatalog();
    final categoryId = _catalogIdFor(widget.category);
    final categoryData = catalog.byId(categoryId);
    final items = categoryData?.items ?? const <AthkarItem>[];

    final state = await _sessionService.loadState(widget.category);
    final counts = await _sessionService.loadCounts(widget.category);

    if (!mounted) return;

    final maxIndex = items.length;
    final initialIndex =
        maxIndex == 0 ? 0 : state.index.clamp(0, maxIndex - 1);
    if (items.isNotEmpty) {
      final currentKey = _favoriteIdFor(items[initialIndex]);
      counts[currentKey] = 0;
    }

    setState(() {
      _items = items;
      _counts = counts;
      _categoryTitle = categoryData?.title;
      _index = initialIndex;
      _count = 0;
      _ritualLocked = false;
      _loading = false;
    });

    if (_items.isNotEmpty) {
      _loadFavoriteFor(_items[_index]);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToIndex(_index);
    });
  }

  int _repeatFor(List<AthkarItem> items, int index) {
    if (index >= items.length) return 1;
    final target = items[index].target;
    return target <= 0 ? 1 : target;
  }

  Future<void> _saveState() async {
    await _sessionService.saveState(
      widget.category,
      AdhkarSessionState(index: _index, count: _count),
    );
  }

  Future<void> _saveCounts() async {
    await _sessionService.saveCounts(widget.category, _counts);
  }

  void _handleTap() {
    if (_loading || _ritualLocked) return;
    if (_index >= _items.length) return;

    HapticFeedback.selectionClick();

    final repeat = _repeatFor(_items, _index);
    final current = _count;
    if (repeat > 0 && current >= repeat) return;

    final nextCount = current + 1;
    final item = _items[_index];
    final key = _favoriteIdFor(item);

    setState(() {
      _count = nextCount;
      _counts[key] = nextCount;
    });
    _saveCounts();
    _saveState();

    if (repeat > 0 && nextCount >= repeat && _index + 1 < _items.length) {
      _goNext();
    }
  }

  void _goPrev() {
    if (_loading || _ritualLocked) return;
    if (_index <= 0) return;
    _applyIndex(_index - 1, animate: true);
  }

  void _goNext() {
    if (_loading || _ritualLocked) return;
    if (_index + 1 >= _items.length) return;
    _applyIndex(_index + 1, animate: true);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.titleOverride ?? _categoryTitle ?? widget.category.label;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PrimaryAppBar(
        title: title,
        showBack: true,
      ),
      body: _loading
          ? const SizedBox.shrink()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: _items.isEmpty ? _buildEmpty() : _buildSession(),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSession() {
    const secondary = AppColors.textSecondary;
    final repeat = _repeatFor(_items, _index);
    final displayCount = _count < 0 ? 0 : _count;
    final item = _items[_index];
    final showSource = item.source.isNotEmpty;
    final showFadl = item.fadl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(26),
                boxShadow: AppUi.cardShadow,
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: _handlePageChange,
                reverse: Directionality.of(context) == TextDirection.rtl,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return InkWell(
                    onTap: _handleTap,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 520),
                                  child: Text(
                                    item.arabic,
                                    textAlign: TextAlign.center,
                                    style: AppText.dhikrText.copyWith(
                                      color: AppColors.textPrimary.withValues(
                                        alpha: 0.92,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'التكرار: $displayCount / $repeat',
          style: AppText.caption.copyWith(color: secondary),
        ),
        const SizedBox(height: 12),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepArrow(
                icon: Icons.chevron_left,
                enabled: _index > 0,
                onTap: _goPrev,
              ),
              const SizedBox(width: 16),
              Text(
                '${_index + 1} / ${_items.length}',
                style: AppText.caption.copyWith(color: secondary),
              ),
              const SizedBox(width: 16),
              _StepArrow(
                icon: Icons.chevron_right,
                enabled: _index < _items.length - 1,
                onTap: _goNext,
              ),
            ],
          ),
        ),
        if (showSource || showFadl) ...[
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              if (showSource)
                _ActionLink(
                  label: 'المصدر',
                  onTap: () => _showTextSheet('المصدر', item.source),
                ),
              if (showFadl)
                _ActionLink(
                  label: 'الفضل',
                  onTap: () => _showTextSheet('الفضل', item.fadl),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        _ActionLink(
          label: 'الخيارات',
          onTap: _openActionsSheet,
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    const secondary = AppColors.textSecondary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('لا توجد أذكار متاحة', style: AppText.heading),
          const SizedBox(height: 8),
          Text(
            'أضف أذكارًا من البيانات لاحقًا',
            style: AppText.body.copyWith(color: secondary),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('رجوع'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetSession() async {
    setState(() {
      _index = 0;
      _count = 0;
      _ritualLocked = false;
      _counts = {};
    });
    _jumpToIndex(0);
    await _saveState();
    await _saveCounts();
  }

  void _openActionsSheet() {
    if (_items.isEmpty) return;
    final item = _items[_index];
    final hasDetails =
        item.meaning.isNotEmpty || item.transliteration.isNotEmpty;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  _isFavorite ? Icons.star : Icons.star_border,
                ),
                title: Text(
                  _isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleFavorite();
                },
              ),
              if (hasDetails)
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('التفاصيل'),
                  onTap: () {
                    Navigator.pop(context);
                    _openDetailsSheet(item);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('إعادة العد'),
                onTap: () {
                  Navigator.pop(context);
                  _resetSession();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('نسخ النص'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: item.arabic));
                  _showSnackBar('تم النسخ');
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('مشاركة'),
                onTap: () {
                  Navigator.pop(context);
                  Share.share(item.arabic);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _openDetailsSheet(AthkarItem item) {
    if (item.meaning.isEmpty && item.transliteration.isEmpty) return;
    final sections = <_DetailSection>[
      if (item.transliteration.isNotEmpty)
        _DetailSection(title: 'النطق', content: item.transliteration),
      if (item.meaning.isNotEmpty)
        _DetailSection(title: 'المعنى', content: item.meaning),
    ];
    _showDetailSections('التفاصيل', sections);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: AppText.body),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
        showCloseIcon: true,
        closeIconColor: AppColors.textMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showTextSheet(String title, String content) {
    _showDetailSections(title, [
      _DetailSection(title: title, content: content),
    ]);
  }

  void _showDetailSections(String title, List<_DetailSection> sections) {
    final combined = sections.map((s) => s.content).join('\n\n');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: AppText.heading),
                    ),
                    IconButton(
                      tooltip: 'نسخ',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: combined));
                        _showSnackBar('تم النسخ');
                      },
                      icon: const Icon(Icons.copy_outlined),
                    ),
                    IconButton(
                      tooltip: 'إغلاق',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.title, style: AppText.caption),
                        const SizedBox(height: 6),
                        Text(
                          section.content,
                          style: AppText.body.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handlePageChange(int index) {
    if (_loading || _ritualLocked || index == _index) return;
    _applyIndex(index, animate: false);
  }

  void _jumpToIndex(int index) {
    if (!_pageController.hasClients || _items.isEmpty) return;
    if (index >= _items.length) return;
    final target = index.clamp(0, _items.length - 1);
    _pageController.jumpToPage(target);
  }

  void _animateToIndex(int index) {
    if (!_pageController.hasClients || _items.isEmpty) return;
    if (index >= _items.length) return;
    final target = index.clamp(0, _items.length - 1);
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _applyIndex(int index, {required bool animate}) {
    if (_loading || _ritualLocked) return;
    if (index < 0 || index >= _items.length) return;
    final key = _favoriteIdFor(_items[index]);
    setState(() {
      _index = index;
      _count = 0;
      _counts[key] = 0;
    });
    if (animate) {
      _animateToIndex(index);
    }
    _saveState();
    _saveCounts();
    _loadFavoriteFor(_items[index]);
  }

  String _catalogIdFor(AdhkarCategory category) {
    switch (category) {
      case AdhkarCategory.morning:
        return 'morning';
      case AdhkarCategory.evening:
        return 'evening';
      case AdhkarCategory.afterPrayer:
        return 'after_prayer';
      case AdhkarCategory.beforePrayer:
        return 'before_prayer';
      case AdhkarCategory.general:
        return 'general';
      case AdhkarCategory.tasbeeh:
        return 'tasbeeh';
      case AdhkarCategory.istighfar:
        return 'istighfar';
      case AdhkarCategory.duas:
        return 'duas';
    }
  }

  String _favoriteIdFor(AthkarItem item) {
    if (item.id.isNotEmpty) return item.id;
    return item.arabic;
  }

  Future<void> _loadFavoriteFor(AthkarItem item) async {
    final saved = await _favoritesService.isFavorite(
      FavoriteType.dhikr,
      _favoriteIdFor(item),
    );
    if (!mounted) return;
    setState(() => _isFavorite = saved);
  }

  Future<void> _toggleFavorite() async {
    if (_items.isEmpty || _index >= _items.length) return;
    final item = _items[_index];
    final saved = await _favoritesService.toggle(
      FavoriteItem(
        type: FavoriteType.dhikr,
        id: _favoriteIdFor(item),
        title: item.arabic,
        subtitle: item.source,
      ),
    );
    if (!mounted) return;
    setState(() => _isFavorite = saved);
  }

}

class _DetailSection {
  final String title;
  final String content;

  const _DetailSection({
    required this.title,
    required this.content,
  });
}

class _StepArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? AppColors.textSecondary
        : AppColors.textMuted.withValues(alpha: 0.5);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: color),
      ),
    );
  }
}

class _ActionLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionLink({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: AppText.caption.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
