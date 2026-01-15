import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/services/adhkar_session_service.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../data/adhkar_models.dart';
import '../data/adhkar_service.dart';
import '../../../shared/widgets/app_popup.dart';

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
    final initialKey = items.isNotEmpty
        ? _favoriteIdFor(items[initialIndex])
        : null;
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
    final title =
        widget.titleOverride ?? _categoryTitle ?? widget.category.label;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: UnifiedAppBar(title: title, showBack: true),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final isCompact = maxHeight < 620;
        final cardPaddingVertical = isCompact ? AppUi.gapLG : AppUi.gapXXL;
        final contentGap = isCompact ? AppUi.gapSM : AppUi.gapLG;
        final sectionGap = isCompact ? AppUi.gapSM : AppUi.gapMD;
        final groupGap = isCompact ? AppUi.gapMD : AppUi.gapLG;
        final ringSize = math.min(72.0, math.max(56.0, maxHeight * 0.12));
        final ringStroke = isCompact ? 6.0 : 7.0;
        final textPaddingVertical = isCompact ? AppUi.gapSMPlus : AppUi.gapMD;

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
                      top: cardPaddingVertical,
                      bottom: cardPaddingVertical,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.surfaceElevatedGradient,
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppUi.gapMD,
                                      vertical: textPaddingVertical,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: AppUi.maxContentWidth,
                                      ),
                                      child: Text(
                                        item.arabic,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.dhikrLarge,
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
            SizedBox(height: contentGap),
            Center(
              child: _RepeatProgress(
                count: _count,
                repeat: repeat,
                size: ringSize,
                strokeWidth: ringStroke,
                onTap: _handleTap,
              ),
            ),
            SizedBox(height: contentGap),
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
              SizedBox(height: groupGap),
            ],
            SizedBox(height: sectionGap),
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

  void _showSnackBar(String message) {
    AppPopup.show(
      context: context,
      title: 'تم بنجاح',
      message: message,
      icon: Icons.check_circle_rounded,
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
                    Expanded(child: Text(title, style: AppText.heading)),
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
                        Text(section.content, style: AppText.bodyMuted),
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

  const _DetailSection({required this.title, required this.content});
}

class _ActionLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionLink({required this.label, required this.onTap});

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
        child: Text(label, style: AppText.caption),
      ),
    );
  }
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
        ? AppColors.textPrimary.withValues(alpha: 0.7)
        : AppColors.textPrimary.withValues(alpha: 0.35);
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

class _RepeatProgress extends StatelessWidget {
  final int count;
  final int repeat;
  final double size;
  final double strokeWidth;
  final VoidCallback onTap;

  const _RepeatProgress({
    required this.count,
    required this.repeat,
    this.size = 72.0,
    this.strokeWidth = 7.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeRepeat = repeat <= 0 ? 1 : repeat;
    final progress = (count / safeRepeat).clamp(0.0, 1.0);
    const progressDuration = Duration(milliseconds: 360);
    final ringSize = size;
    final ringRadius = ringSize / 2;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: progress),
      duration: progressDuration,
      curve: Curves.easeOut,
      onEnd: () {
        if (safeRepeat > 0 && count == safeRepeat) {
          HapticFeedback.mediumImpact();
        }
      },
      builder: (context, value, _) {
        final isComplete = value >= 1.0;
        return AnimatedOpacity(
          opacity: isComplete ? 0.0 : 1.0,
          duration: progressDuration,
          curve: Curves.easeOut,
          child: Material(
            color: AppColors.clear,
            shape: const CircleBorder(),
            child: InkResponse(
              radius: ringRadius,
              containedInkWell: true,
              onTap: onTap,
              child: SizedBox(
                width: ringSize,
                height: ringSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size.square(ringSize),
                      painter: _ProgressRingPainter(
                        progress: value,
                        strokeWidth: strokeWidth,
                        trackColor: AppColors.textPrimary.withValues(
                          alpha: 0.12,
                        ),
                        startColor: AppColors.primary,
                        endColor: AppColors.accent,
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: isComplete ? 0.0 : 1.0,
                      duration: progressDuration,
                      curve: Curves.easeOut,
                      child: Text(
                        '$count / $safeRepeat',
                        style: AppText.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color startColor;
  final Color endColor;

  const _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.startColor,
    required this.endColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);

    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: math.pi * 1.5,
      colors: [startColor, endColor],
    );
    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        strokeWidth != oldDelegate.strokeWidth ||
        trackColor != oldDelegate.trackColor ||
        startColor != oldDelegate.startColor ||
        endColor != oldDelegate.endColor;
  }
}
