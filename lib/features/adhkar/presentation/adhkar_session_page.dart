import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../app/theme/app_palette.dart';
import '../../../core/services/adhkar_session_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_states.dart';
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
  bool _showSuccessRipple = false;

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
    var categoryData = catalog.byId(categoryId);

    // Fallbacks for sleeping
    if (categoryData == null && widget.category == AdhkarCategory.sleeping) {
      categoryData = catalog.byId('general') ?? catalog.byId('before_prayer');
    }

    final items = categoryData?.items ?? const <AthkarItem>[];

    if (!mounted) return;

    final initialKey = items.isNotEmpty ? _favoriteIdFor(items[0]) : null;

    setState(() {
      _items = items;
      _counts = {};
      _categoryTitle = categoryData?.title;
      _index = 0;
      _count = 0;
      _loading = false;
      if (initialKey != null) {
        _counts.putIfAbsent(initialKey, () => 0);
      }
    });
  }

  int _repeatFor(List<AthkarItem> items, int index) {
    if (index >= items.length) return 1;
    final target = items[index].target;
    return target <= 0 ? 1 : target;
  }

  void _handleTap() {
    if (_loading || _index >= _items.length) return;

    final repeat = _repeatFor(_items, _index);
    final current = _count;

    if (repeat > 0 && current >= repeat) return;

    HapticFeedback.lightImpact();

    final nextCount = current + 1;
    final key = _favoriteIdFor(_items[_index]);

    setState(() {
      _count = nextCount;
      _counts[key] = nextCount;
      if (repeat > 0 && nextCount >= repeat) {
        _showSuccessRipple = true;
      }
    });

    if (repeat > 0 && nextCount >= repeat) {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) {
          setState(() => _showSuccessRipple = false);
          if (_index + 1 < _items.length) {
            _goNext();
          }
        }
      });
    }
  }

  void _resetCount() {
    if (_loading || _index >= _items.length) return;
    HapticFeedback.selectionClick();
    final key = _favoriteIdFor(_items[_index]);
    setState(() {
      _count = 0;
      _counts[key] = 0;
    });
  }

  void _goNext() {
    if (_loading || _index + 1 >= _items.length) return;
    HapticFeedback.selectionClick();
    _pageController.nextPage(
      duration: AppMotion.slow,
      curve: Curves.easeInOut,
    );
  }

  void _goPrev() {
    if (_loading || _index <= 0) return;
    HapticFeedback.selectionClick();
    _pageController.previousPage(
      duration: AppMotion.slow,
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    if (index < 0 || index >= _items.length) return;
    final key = _favoriteIdFor(_items[index]);
    setState(() {
      _index = index;
      _count = _counts[key] ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.titleOverride ?? _categoryTitle ?? widget.category.label;
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: PrimaryAppBar(
        title: title,
        showBack: true,
        bottom: _items.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: AppSpace.xs),
                  child: Text(
                    'الذكر ${_index + 1} من ${_items.length}',
                    style: context.text.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: palette.gold,
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: AppLoadingIndicator())
            : _items.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد أذكار في هذه الفئة',
                      style: context.text.body.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      Column(
                        children: [
                          // Dhikr Text Carousel
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: _items.length,
                              onPageChanged: _onPageChanged,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return Padding(
                                  padding: const EdgeInsetsDirectional.symmetric(
                                    horizontal: AppSpace.xl,
                                    vertical: AppSpace.sm,
                                  ),
                                  child: Center(
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: AppCard(
                                        padding: const EdgeInsetsDirectional.all(
                                          AppSpace.xxl,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Arabic Sacred Text
                                            Text(
                                              item.arabic,
                                              textAlign: TextAlign.center,
                                              style: context.text.sacredLarge.copyWith(
                                                color: palette.text,
                                                fontWeight: FontWeight.w700,
                                                height: 1.8,
                                              ),
                                            ),
                                            if (item.meaning.isNotEmpty) ...[
                                              const SizedBox(height: AppSpace.md),
                                              Divider(
                                                color: palette.border,
                                              ),
                                              const SizedBox(height: AppSpace.sm),
                                              Text(
                                                item.meaning,
                                                textAlign: TextAlign.center,
                                                style: context.text.bodySmall.copyWith(
                                                  color: palette.textMuted,
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
                            ),
                          ),

                          const SizedBox(height: AppSpace.sm),

                          // Counter Dial
                          _buildCounterArea(_items[_index]),

                          const SizedBox(height: AppSpace.lg),

                          // Bottom Navigation Bar
                          Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.xxl,
                              vertical: AppSpace.md,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Previous
                                AppIconButton(
                                  icon: Icons.arrow_forward_ios_rounded,
                                  tooltip: 'السابق',
                                  onPressed: _index > 0 ? _goPrev : null,
                                ),

                                // Reset
                                AppButton(
                                  label: 'إعادة العداد',
                                  icon: Icons.replay_rounded,
                                  variant: AppButtonVariant.outline,
                                  size: AppButtonSize.sm,
                                  onPressed: _resetCount,
                                ),

                                // Next
                                AppIconButton(
                                  icon: Icons.arrow_back_ios_new_rounded,
                                  tooltip: 'التالي',
                                  onPressed: _index + 1 < _items.length ? _goNext : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpace.sm),
                        ],
                      ),

                      // Completion Ripple
                      if (_showSuccessRipple)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedContainer(
                              duration: AppMotion.slow,
                              color: palette.success.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildCounterArea(AthkarItem item) {
    final repeat = _repeatFor(_items, _index);
    final isComplete = repeat > 0 && _count >= repeat;
    final palette = context.palette;

    return Semantics(
      button: true,
      label: 'عداد الذكر، اضغط للعد',
      child: InkWell(
        onTap: _handleTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular Progress Dial
            SizedBox(
              width: 210,
              height: 210,
              child: CustomPaint(
                painter: _DhikrProgressPainter(
                  count: _count,
                  total: repeat,
                  trackColor: palette.border,
                  progressColor: isComplete ? palette.success : palette.gold,
                ),
              ),
            ),

            // Inner Numbers & Details
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: AppMotion.fast,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Text(
                    '$_count',
                    key: ValueKey(_count),
                    textScaler: const TextScaler.linear(2.5),
                    style: context.text.display.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isComplete
                          ? palette.success
                          : palette.text,
                      height: 1,
                    ),
                  ),
                ),
                if (repeat > 0) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'من $repeat',
                    style: context.text.label.copyWith(
                      color: palette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (isComplete) ...[
                  const SizedBox(height: AppSpace.xs),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: palette.primarySoft,
                      borderRadius: AppRadius.smRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: palette.success,
                          size: AppIcon.sm,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          'اكتمل',
                          style: context.text.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'المس للعد',
                    style: context.text.caption.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _catalogIdFor(AdhkarCategory category) {
    if (category == AdhkarCategory.sleeping) {
      return 'sleeping';
    }
    if (category == AdhkarCategory.afterPrayer) {
      return 'after_prayer';
    }
    if (category == AdhkarCategory.beforePrayer) {
      return 'before_prayer';
    }
    return category.name;
  }

  String _favoriteIdFor(AthkarItem item) {
    return item.id.isNotEmpty ? item.id : item.arabic;
  }

  Future<void> _clearPersistedSession() async {
    await _sessionService.clearState(widget.category);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _DhikrProgressPainter extends CustomPainter {
  final int count;
  final int total;
  final Color trackColor;
  final Color progressColor;

  _DhikrProgressPainter({
    required this.count,
    required this.total,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - 14) / 2;

    // Track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (total <= 0) return;

    // Progress arc
    final progress = (count / total).clamp(0.0, 1.0);
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DhikrProgressPainter oldDelegate) {
    return count != oldDelegate.count ||
        total != oldDelegate.total ||
        trackColor != oldDelegate.trackColor ||
        progressColor != oldDelegate.progressColor;
  }
}
