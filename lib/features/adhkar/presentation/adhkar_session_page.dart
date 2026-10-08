import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../app/theme/theme_colors.dart';
import '../../../core/services/adhkar_session_service.dart';
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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goPrev() {
    if (_loading || _index <= 0) return;
    HapticFeedback.selectionClick();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
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
    final isDark = context.isDark;
    final gold = context.goldColor;
    final textColor = context.textPrimaryColor;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (_items.isNotEmpty)
              Text(
                'الذكر ${_index + 1} من ${_items.length}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: gold,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: gold),
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: gold))
            : _items.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد أذكار في هذه الفئة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: context.textSecondaryColor,
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  child: Center(
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Container(
                                        padding: const EdgeInsets.all(22),
                                        decoration: BoxDecoration(
                                          color: context.surfaceContainer,
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                            color: gold.withValues(
                                              alpha: isDark ? 0.25 : 0.2,
                                            ),
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: isDark ? 0.25 : 0.04,
                                              ),
                                              blurRadius: 14,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Arabic Sacred Text
                                            Text(
                                              item.arabic,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Amiri',
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                height: 1.8,
                                                color: textColor,
                                              ),
                                            ),
                                            if (item.meaning.isNotEmpty) ...[
                                              const SizedBox(height: 14),
                                              Divider(
                                                color: context.outlineColor
                                                    .withValues(alpha: 0.15),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                item.meaning,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 13,
                                                  height: 1.6,
                                                  color: context.textSecondaryColor,
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

                          const SizedBox(height: 10),

                          // Counter Dial
                          _buildCounterArea(_items[_index]),

                          const SizedBox(height: 16),

                          // Bottom Navigation Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Previous
                                IconButton.filledTonal(
                                  onPressed: _index > 0 ? _goPrev : null,
                                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                                  style: IconButton.styleFrom(
                                    backgroundColor: context.surfaceContainer,
                                    foregroundColor: textColor,
                                  ),
                                  tooltip: 'السابق',
                                ),

                                // Reset
                                OutlinedButton.icon(
                                  onPressed: _resetCount,
                                  icon: Icon(
                                    Icons.replay_rounded,
                                    size: 16,
                                    color: context.textSecondaryColor,
                                  ),
                                  label: Text(
                                    'إعادة العداد',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      color: context.textSecondaryColor,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: context.outlineColor.withValues(alpha: 0.2),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),

                                // Next
                                IconButton.filledTonal(
                                  onPressed: _index + 1 < _items.length ? _goNext : null,
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                                  style: IconButton.styleFrom(
                                    backgroundColor: context.surfaceContainer,
                                    foregroundColor: textColor,
                                  ),
                                  tooltip: 'التالي',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),

                      // Completion Ripple
                      if (_showSuccessRipple)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              color: context.islamicGreenColor.withValues(alpha: 0.12),
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
    final gold = context.goldColor;
    final primary = context.primaryColor;

    return GestureDetector(
      onTap: _handleTap,
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
                trackColor: context.outlineColor.withValues(alpha: 0.15),
                progressColor: isComplete ? context.islamicGreenColor : gold,
              ),
            ),
          ),

          // Inner Numbers & Details
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text(
                  '$_count',
                  key: ValueKey(_count),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: isComplete ? context.islamicGreenColor : context.textPrimaryColor,
                    height: 1,
                  ),
                ),
              ),
              if (repeat > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'من $repeat',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (isComplete) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.islamicGreenColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: context.islamicGreenColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'اكتمل',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.islamicGreenColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  'المس للعد',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
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
