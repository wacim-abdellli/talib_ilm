import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/services/adhkar_session_service.dart';
import '../../../shared/widgets/empty_state.dart';
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
      const ringCompleteDelay = Duration(milliseconds: 360);
      Future.delayed(ringCompleteDelay, () {
        if (!mounted) return;
        _goNext();
      });
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: _loading
            ? const SizedBox.shrink()
            : SafeArea(
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
    final repeat = _repeatFor(_items, _index);
    final overallProgress = _overallProgress(repeat);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final isCompact = maxHeight < 620;
        final counterSize = math.min(
          200.0,
          math.max(160.0, constraints.maxWidth * 0.6),
        );
        final topPadding = isCompact ? AppUi.gapSM : AppUi.gapMD;
        final sidePadding = isCompact ? AppUi.gapLG : AppUi.gapXL;
        final isComplete = repeat > 0 && _count >= repeat;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LinearProgressIndicator(
              value: overallProgress,
              minHeight: 4,
              backgroundColor: AppColors.secondaryLight.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(
                AppColors.secondaryLight,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppUi.paddingMD,
                vertical: topPadding,
              ),
              child: Row(
                children: [
                  Text(
                    AppStrings.numberPair(_index + 1, _items.length),
                    style: AppText.caption.copyWith(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  if (item.audio.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                      },
                      icon: const Icon(Icons.volume_up_outlined),
                      color: Colors.white,
                      tooltip: AppStrings.actionDetails,
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                    tooltip: AppStrings.actionClose,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: _handlePageChange,
                reverse: Directionality.of(context) == TextDirection.rtl,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final translation = _translationFor(item);
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: sidePadding,
                                vertical: AppUi.gapLG,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.arabic,
                                    textAlign: TextAlign.center,
                                    style: AppText.dhikrText.copyWith(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.8,
                                    ),
                                  ),
                                  if (translation.isNotEmpty) ...[
                                    const SizedBox(height: AppUi.gapLG),
                                    Text(
                                      translation,
                                      textAlign: TextAlign.center,
                                      style: AppText.body.copyWith(
                                        fontSize: 18,
                                        color: Colors.white70,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ],
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
            const SizedBox(height: AppUi.gapLG),
            _CounterButton(
              count: _count,
              size: counterSize,
              isComplete: isComplete,
              onTap: _handleTap,
            ),
            const SizedBox(height: AppUi.gapXL),
          ],
        );
      },
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

  String _translationFor(AthkarItem item) {
    if (item.meaning.isNotEmpty) return item.meaning;
    if (item.transliteration.isNotEmpty) return item.transliteration;
    return '';
  }

  double _overallProgress(int repeat) {
    if (_items.isEmpty) return 0;
    final perItem = repeat <= 0 ? 1.0 : (_count / repeat).clamp(0.0, 1.0);
    final progress = (_index + perItem) / _items.length;
    return progress.clamp(0.0, 1.0);
  }

}

class _CounterButton extends StatelessWidget {
  final int count;
  final double size;
  final bool isComplete;
  final VoidCallback onTap;

  const _CounterButton({
    required this.count,
    required this.size,
    required this.isComplete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isComplete ? 1.06 : 1,
      duration: AppUi.animationMedium,
      curve: Curves.easeOut,
      child: Material(
        color: AppColors.secondary.withOpacity(0.4),
        shape: const CircleBorder(),
        child: InkResponse(
          onTap: onTap,
          radius: size / 2,
          containedInkWell: true,
          splashColor: AppColors.secondaryLight.withOpacity(0.35),
          highlightColor: AppColors.secondary.withOpacity(0.2),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: AnimatedOpacity(
                opacity: isComplete ? 0.6 : 1.0,
                duration: AppUi.animationMedium,
                curve: Curves.easeOut,
                child: FittedBox(
                  child: Text(
                    '$count',
                    style: AppText.heading.copyWith(
                      fontSize: 72,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
