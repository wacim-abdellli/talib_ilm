import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../app/theme/app_colors.dart';
import '../../../core/services/adhkar_session_service.dart';
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
  bool _showConfetti = false;

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

  Future<void> _saveState() async {
    // Placeholder for saving session state
    return;
  }

  Future<void> _saveCounts() async {
    // Placeholder for saving counts
    return;
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
        _showConfetti = true;
      }
    });

    if (repeat > 0 && nextCount >= repeat) {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() => _showConfetti = false);
          if (_index + 1 < _items.length) {
            _goNext();
          }
        }
      });
    }

    _saveCounts();
    _saveState();
  }

  void _resetCount() {
    if (_loading || _index >= _items.length) return;
    HapticFeedback.selectionClick();
    final key = _favoriteIdFor(_items[_index]);
    setState(() {
      _count = 0;
      _counts[key] = 0;
    });
    _saveCounts();
    _saveState();
  }

  void _goNext() {
    if (_loading || _index + 1 >= _items.length) return;
    HapticFeedback.selectionClick();
    _pageController.nextPage(
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

  void _openSettings() {
    // Placeholder for settings
    AppPopup.show(
      context: context,
      title: 'الإعدادات',
      message: 'خيارات العرض والصوت ستتوفر قريباً',
      icon: Icons.settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.titleOverride ?? _categoryTitle ?? widget.category.label;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: UnifiedAppBar(
        title: title,
        showBack: true,
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAFAF9), // Off-white
              Color(0xFFF5F5F4), // Light grey
            ],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    // Main Content (Swipeable Text + Counter)
                    // We need the counter to be persistent but update values,
                    // OR swipe the whole thing. "Swipe left/right: PageView to next/previous dhikr".
                    // Usually better to swipe specific content and keep controls static,
                    // BUT "Smooth transition" usually implies the whole card swipes.
                    // Given the request separates "Above circle: Dhikr..." and "Center Circle...",
                    // let's try swiping the TEXT and keeping the counter static but updating?
                    // "Center CircularProgressIndicator... Tap circle area: increment".
                    // If I swipe, the count changes.
                    // Let's use a PageView for the TOP part (Text) and update the bottom part (Counter).
                    Column(
                      children: [
                        // PageView for Dhikr Text
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
                                  horizontal: 24,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Spacer(),
                                    // Arabic
                                    Text(
                                      item.arabic,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        height: 1.6,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Meaning/Translation
                                    if (item.meaning.isNotEmpty)
                                      Text(
                                        item.meaning,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          // fontFamily: 'Cairo', // Fallback to safe default or implicit
                                          fontSize: 16,
                                          height: 1.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    const SizedBox(
                                      height: 40,
                                    ), // "padding bottom 40" relative to text area
                                    const Spacer(),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // Counter Area (Static position, updates values)
                        if (_items.isNotEmpty)
                          _buildCounterArea(_items[_index]),

                        const SizedBox(height: 40),

                        // Bottom Controls Layer is overlay, or row here?
                        // "Reset button: bottom-left".
                        // Let's create a dedicated bottom area or use Stack for the button.
                        // Ideally strictly separated.
                        const SizedBox(height: 80), // Space for bottom controls
                      ],
                    ),

                    // Reset Button (Bottom Left)
                    Positioned(
                      left: 24,
                      bottom: 24,
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _resetCount,
                          customBorder: const CircleBorder(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Icon(
                              Icons.replay,
                              color: AppColors.error,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Confetti/Completion Overlay
                    if (_showConfetti)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            color: AppColors.success.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCounterArea(AthkarItem item) {
    final repeat = _repeatFor(_items, _index);
    final isComplete = repeat > 0 && _count >= repeat;

    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Circle
          SizedBox(
            width: 280,
            height: 280,
            child: CustomPaint(
              painter: _DhikrProgressPainter(count: _count, total: repeat),
            ),
          ),

          // Inner Text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text(
                  isComplete ? '$_count' : '$_count', // Just count
                  key: ValueKey(_count),
                  style: const TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.w900, // Extra bold
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
              ),
              if (repeat > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'من $repeat',
                  style: const TextStyle(
                    fontSize: 20,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (isComplete) ...[
                const SizedBox(height: 8),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 32,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Helpers
  String _catalogIdFor(AdhkarCategory category) {
    return category
        .name; // Simplified, assumes mapping matches or handles in service
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

  _DhikrProgressPainter({required this.count, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - 16) / 2; // Stroke 16

    // Track
    final trackPaint = Paint()
      ..color =
          const Color(0xFFE5E5E5) // Light grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (total <= 0) return;

    // Progress
    final progress = (count / total).clamp(0.0, 1.0);
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = const SweepGradient(
        colors: [
          Color(0xFFD4AF37), // Axcent
          Color(0xFFF5EDD6), // Light Accent
          Color(0xFFD4AF37), // Accent
        ],
        // stops: [0.0, 0.5, 1.0],
        transform: GradientRotation(-math.pi / 2),
      );

      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
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
    return count != oldDelegate.count || total != oldDelegate.total;
  }
}
