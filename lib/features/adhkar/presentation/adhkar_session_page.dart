import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/services/adhkar_session_service.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../shared/widgets/app_back_button.dart';
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
  final PrayerTimeService _prayerTimeService = PrayerTimeService();

  late final PageController _pageController;
  List<AthkarItem> _items = const [];
  String? _categoryTitle;
  int _index = 0;
  int _count = 0;
  bool _loading = true;
  bool _ritualLocked = false;
  final bool _autoResetRitual = true;

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
    final ritual = _isRitual(widget.category);
    final completion = ritual
        ? await _sessionService.loadCompletion(widget.category)
        : null;
    DateTime? windowStart;
    if (ritual) {
      windowStart = await _windowStart(widget.category);
    }

    final needsReset = ritual &&
        windowStart != null &&
        completion != null &&
        completion.isBefore(windowStart);
    final locked = ritual &&
        completion != null &&
        windowStart != null &&
        (completion.isAfter(windowStart) ||
            completion.isAtSameMomentAs(windowStart));
    final autoReset = _autoResetRitual && locked;

    if (needsReset || autoReset) {
      await _sessionService.clearCompletion(widget.category);
      await _sessionService.saveState(
        widget.category,
        const AdhkarSessionState(index: 0, count: 1),
      );
    }

    if (!mounted) return;

    final maxIndex = items.length;
    final initialIndex =
        (needsReset || autoReset) ? 0 : state.index.clamp(0, maxIndex);
    var initialCount = 1;
    if (!(needsReset || autoReset) && initialIndex < items.length) {
      final repeat = _repeatFor(items, initialIndex);
      final stored = state.count <= 0 ? 1 : state.count;
      initialCount = stored.clamp(1, repeat);
    }

    setState(() {
      _items = items;
      _categoryTitle = categoryData?.title;
      _index = initialIndex;
      _count = initialCount;
      _ritualLocked = locked && !_autoResetRitual;
      _loading = false;
    });

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

  void _handleTap() {
    if (_loading || _ritualLocked) return;
    if (_index >= _items.length) return;

    HapticFeedback.selectionClick();

    final repeat = _repeatFor(_items, _index);
    final current = _count <= 0 ? 1 : _count;

    if (current >= repeat) {
      _advanceToNext();
      return;
    }

    final nextCount = current + 1;
    if (nextCount >= repeat) {
      _advanceToNext();
      return;
    }

    setState(() => _count = nextCount);
    _saveState();
  }

  void _handleStepBack() {
    if (_loading || _ritualLocked) return;
    if (_index >= _items.length) return;

    HapticFeedback.selectionClick();

    final current = _count <= 0 ? 1 : _count;
    if (current <= 1) return;

    setState(() => _count = current - 1);
    _saveState();
  }

  void _advanceToNext() {
    if (_index + 1 >= _items.length) {
      _handleCompletion();
      return;
    }
    setState(() {
      _index += 1;
      _count = 1;
    });
    _animateToIndex(_index);
    _saveState();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.titleOverride ?? _categoryTitle ?? widget.category.label;
    final progressText = (!_loading && _items.isNotEmpty)
        ? '${_index + 1} / ${_items.length}'
        : '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppText.headingXL),
            if (progressText.isNotEmpty)
              Text(
                progressText,
                style: AppText.caption.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
        leading: const AppBackButton(),
        actions: [
          IconButton(
            tooltip: 'الخيارات',
            icon: const Icon(Icons.more_horiz),
            onPressed: _openActionsSheet,
          ),
        ],
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
    final secondary = Theme.of(context).colorScheme.onSurface.withValues(
          alpha: 0.6,
        );
    final currentItem = _items[_index];
    final repeat = _repeatFor(_items, _index);
    final displayCount = _count <= 0 ? 1 : _count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.contextLabel != null) ...[
          Text(
            widget.contextLabel!,
            style: AppText.caption.copyWith(color: secondary),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          widget.category.label,
          style: AppText.bodyMuted.copyWith(color: secondary),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
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
                  onLongPress: () => _openDetailsSheet(item),
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.arabic,
                                    textAlign: TextAlign.center,
                                    style: AppText.athkarBody.copyWith(
                                      color: AppColors.textPrimary.withValues(
                                        alpha: 0.92,
                                      ),
                                    ),
                                  ),
                                ],
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
        const SizedBox(height: 12),
        if (currentItem.countDescription.isNotEmpty || repeat > 1)
          Text(
            currentItem.countDescription.isNotEmpty
                ? 'العدد: ${currentItem.countDescription}'
                : 'العدد المطلوب: $repeat',
            style: AppText.caption.copyWith(color: secondary),
          ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StepArrow(
                    icon: Icons.chevron_left,
                    enabled: displayCount > 1,
                    onTap: _handleStepBack,
                  ),
                  const SizedBox(width: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      '$displayCount / $repeat',
                      key: ValueKey('$displayCount-$repeat'),
                      style: AppText.heading.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StepArrow(
                    icon: Icons.chevron_right,
                    enabled: !(_index >= _items.length - 1 &&
                        displayCount >= repeat),
                    onTap: _handleTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    final secondary = Theme.of(context).colorScheme.onSurface.withValues(
          alpha: 0.6,
        );
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
      _count = 1;
      _ritualLocked = false;
    });
    _jumpToIndex(0);
    await _saveState();
  }

  void _handleCompletion() {
    if (_isRitual(widget.category)) {
      _sessionService.saveCompletion(widget.category, DateTime.now());
    }
    _sessionService.saveState(
      widget.category,
      const AdhkarSessionState(index: 0, count: 1),
    );
  }

  void _openActionsSheet() {
    if (_items.isEmpty) return;
    final item = _items[_index];
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
                leading: const Icon(Icons.refresh),
                title: const Text('إعادة العد'),
                onTap: () {
                  Navigator.pop(context);
                  _resetSession();
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('عرض الفضل'),
                enabled: item.fadl.isNotEmpty,
                onTap: item.fadl.isEmpty
                    ? null
                    : () {
                        Navigator.pop(context);
                        _showTextSheet('الفضل', item.fadl);
                      },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('عرض المصدر'),
                enabled: item.source.isNotEmpty,
                onTap: item.source.isEmpty
                    ? null
                    : () {
                        Navigator.pop(context);
                        _showTextSheet('المصدر', item.source);
                      },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('نسخ النص'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: item.arabic));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم النسخ'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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

  void _showTextSheet(String title, String content) {
    _showDetailSections(title, [
      _DetailSection(title: title, content: content),
    ]);
  }

  void _showDetailSections(String title, List<_DetailSection> sections) {
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
                Text(title, style: AppText.heading),
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
                            color: AppColors.textSecondary,
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
    setState(() {
      _index = index;
      _count = 1;
    });
    _saveState();
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
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
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

  bool _isRitual(AdhkarCategory category) {
    return category == AdhkarCategory.morning ||
        category == AdhkarCategory.evening ||
        category == AdhkarCategory.afterPrayer;
  }

  Future<DateTime?> _windowStart(AdhkarCategory category) async {
    try {
      final now = DateTime.now();
      final key = _ritualResetKey(category);
      if (key == null) return null;

      final today = await _prayerTimeService.getPrayerTimesDay(date: now);
      DateTime? boundary = today.prayers[key];
      if (boundary == null) return DateTime(now.year, now.month, now.day);

      if (now.isBefore(boundary)) {
        final yesterday = now.subtract(const Duration(days: 1));
        final previous =
            await _prayerTimeService.getPrayerTimesDay(date: yesterday);
        boundary = previous.prayers[key] ??
            boundary.subtract(const Duration(days: 1));
      }
      return boundary;
    } catch (_) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
  }

  String? _ritualResetKey(AdhkarCategory category) {
    switch (category) {
      case AdhkarCategory.morning:
        return 'الفجر';
      case AdhkarCategory.evening:
        return 'المغرب';
      case AdhkarCategory.afterPrayer:
        return 'الفجر';
      default:
        return null;
    }
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
    final color =
        enabled ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.5);
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
