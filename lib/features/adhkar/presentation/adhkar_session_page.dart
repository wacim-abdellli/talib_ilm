import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/services/adhkar_session_service.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_app_bar.dart';
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

  late final PageController _pageController;
  List<AthkarItem> _items = const [];
  Map<String, int> _counts = {};
  String? _categoryTitle;
  int _index = 0;
  int _count = 0;
  bool _loading = true;
  bool _ritualLocked = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadItems();
  }

  Future<void> _loadItems() async {
    await _clearPersistedSession();
    final catalog = await _athkarService.loadCatalog();
    final categoryId = _catalogIdFor(widget.category);
    final categoryData = catalog.byId(categoryId);
    final items = categoryData?.items ?? const <AthkarItem>[];

    if (!mounted) return;

    final maxIndex = items.length;
    final initialIndex = maxIndex == 0 ? 0 : 0;
    final initialKey =
        items.isNotEmpty ? _favoriteIdFor(items[initialIndex]) : null;
    const savedCount = 0;

    setState(() {
      _items = items;
      _counts = {};
      _categoryTitle = categoryData?.title;
      _index = initialIndex;
      _count = savedCount < 0 ? 0 : savedCount;
      _ritualLocked = false;
      _loading = false;
      if (initialKey != null) {
        _counts.putIfAbsent(initialKey, () => _count);
      }
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
    return;
  }

  Future<void> _saveCounts() async {
    return;
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
      HapticFeedback.lightImpact();
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
      appBar: UnifiedAppBar(
        title: title,
        showBack: true,
      ),
      body: _loading
          ? const SizedBox.shrink()
          : SafeArea(
              child: Padding(
                padding: AppUi.screenPaddingTopLarge,
                child: _items.isEmpty ? _buildEmpty() : _buildSession(),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _index = 0;
    _count = 0;
    _counts = {};
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSession() {
    final item = _items[_index];
    final showSource = item.source.isNotEmpty;
    final showFadl = item.fadl.isNotEmpty;
    final repeat = _repeatFor(_items, _index);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleTap,
              child: Container(
                width: double.infinity,
                padding: AppUi.cardPadding.copyWith(
                  top: AppUi.gapXL,
                  bottom: AppUi.gapXL,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppUi.radiusXXL),
                  border: Border.all(
                    color: AppColors.stroke,
                    width: AppUi.dividerThickness,
                  ),
                  boxShadow: AppUi.cardShadow,
                ),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _items.length,
                  onPageChanged: _handlePageChange,
                  reverse: Directionality.of(context) == TextDirection.rtl,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return LayoutBuilder(
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
                                  horizontal: AppUi.gapMD,
                                  vertical: AppUi.gapSMPlus,
                                ),
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(
                                        maxWidth: AppUi.maxContentWidth,
                                      ),
                                  child: Text(
                                    item.arabic,
                                    textAlign: TextAlign.center,
                                    style: AppText.body,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppUi.gapSM),
        Center(
          child: Text(
            '$_count / $repeat',
            style: AppText.caption,
          ),
        ),
        const SizedBox(height: AppUi.gapSM),
        if (showSource || showFadl) ...[
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppUi.gapMD,
            runSpacing: AppUi.gapSM,
            children: [
              if (showSource)
                _ActionLink(
                  label: AppStrings.adhkarSource,
                  onTap: () =>
                      _showTextSheet(AppStrings.adhkarSource, item.source),
                ),
              if (showFadl)
                _ActionLink(
                  label: AppStrings.adhkarVirtue,
                  onTap: () =>
                      _showTextSheet(AppStrings.adhkarVirtue, item.fadl),
                ),
            ],
          ),
          const SizedBox(height: AppUi.gapMD),
        ],
        const SizedBox(height: AppUi.gapSM),
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
              const SizedBox(width: AppUi.gapLG),
              Text(
                '${_index + 1} / ${_items.length}',
                style: AppText.caption,
              ),
              const SizedBox(width: AppUi.gapLG),
              _StepArrow(
                icon: Icons.chevron_right,
                enabled: _index < _items.length - 1,
                onTap: _goNext,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return EmptyState(
      icon: Icons.menu_book_outlined,
      title: AppStrings.adhkarSessionEmptyTitle,
      message: AppStrings.adhkarSessionEmptyMessage,
      actionLabel: AppStrings.actionBack,
      onAction: () => Navigator.pop(context),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.primary),
            const SizedBox(width: AppUi.gapSM),
            Expanded(
              child: Text(message, style: AppText.body),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(
          AppUi.paddingMD,
          0,
          AppUi.paddingMD,
          AppUi.paddingMD,
        ),
        duration: AppUi.snackDurationLong,
        showCloseIcon: true,
        closeIconColor: AppColors.textMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppUi.radiusSMPlus),
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
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppUi.radiusLG),
        ),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppUi.paddingMD,
              AppUi.gapMD,
              AppUi.paddingMD,
              AppUi.paddingMD,
            ),
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
                      tooltip: AppStrings.actionCopy,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: combined));
                        _showSnackBar(AppStrings.copyDone);
                      },
                      icon: const Icon(Icons.copy_outlined),
                    ),
                    IconButton(
                      tooltip: AppStrings.actionClose,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppUi.gapMD),
                ...sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: AppUi.gapMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.title, style: AppText.caption),
                        const SizedBox(height: AppUi.gapXSPlus),
                        Text(
                          section.content,
                          style: AppText.bodyMuted,
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
      duration: AppUi.animationQuick,
      curve: Curves.easeOut,
    );
  }

  void _applyIndex(int index, {required bool animate}) {
    if (_loading || _ritualLocked) return;
    if (index < 0 || index >= _items.length) return;
    final key = _favoriteIdFor(_items[index]);
    final restored = _counts[key] ?? 0;
    setState(() {
      _index = index;
      _count = restored < 0 ? 0 : restored;
      _counts.putIfAbsent(key, () => _count);
    });
    if (animate) {
      _animateToIndex(index);
    }
    _saveState();
    _saveCounts();
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

  Future<void> _clearPersistedSession() async {
    await _sessionService.clearState(widget.category);
    await _sessionService.saveCounts(widget.category, const {});
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
        : AppColors.textMuted;
    return InkWell(
      borderRadius: BorderRadius.circular(AppUi.radiusCard),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(AppUi.gapXSPlus),
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppUi.gapSMPlus,
            vertical: AppUi.gapXSPlus,
          ),
          minimumSize: const Size(0, AppUi.tapTargetMin),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: AppText.caption,
        ),
      ),
    );
  }
}
