import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/services/adhkar_session_service.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../data/adhkar_models.dart';
import '../data/adhkar_service.dart';
import 'widgets/adhkar_session_card.dart';
import 'widgets/dhikr_counter_dial.dart';

/// Immersive, scholarly recitation session for Adhkar with tactile counting
/// and ergonomically placed RTL navigation arrows.
class AdhkarSessionPage extends StatefulWidget {
  final AdhkarCategory category;
  final String? categoryId;
  final String? titleOverride;
  final String? contextLabel;
  final AthkarCategoryData? categoryData;

  const AdhkarSessionPage({
    super.key,
    required this.category,
    this.categoryId,
    this.titleOverride,
    this.contextLabel,
    this.categoryData,
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

  double _fontScale = 1.0;
  bool _showTashkeel = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadItems();
  }

  Future<void> _loadItems() async {
    await _clearPersistedSession();
    var categoryData = widget.categoryData;
    if (categoryData == null) {
      final catalog = await _athkarService.loadCatalog();
      final categoryId = widget.categoryId ?? _catalogIdFor(widget.category);
      categoryData = catalog.byId(categoryId);

      // Fallbacks for sleeping
      if (categoryData == null && widget.category == AdhkarCategory.sleeping) {
        categoryData = catalog.byId('general') ?? catalog.byId('before_prayer');
      }
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
      Future.delayed(AppMotion.base, () {
        if (mounted) {
          setState(() => _showSuccessRipple = false);
          if (_index + 1 < _items.length) {
            _goNext();
          }
        }
      });
    }
  }

  void _cycleFontSize() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_fontScale == 1.0) {
        _fontScale = 1.15;
      } else if (_fontScale == 1.15) {
        _fontScale = 1.30;
      } else {
        _fontScale = 1.0;
      }
    });
  }

  void _toggleTashkeel() {
    HapticFeedback.selectionClick();
    setState(() {
      _showTashkeel = !_showTashkeel;
    });
  }

  void _shareCurrentDhikr() {
    if (_items.isEmpty || _index >= _items.length) return;
    HapticFeedback.selectionClick();
    final item = _items[_index];
    final buffer = StringBuffer();
    buffer.writeln(item.arabic);
    if (item.fadl.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('الفضل: ${item.fadl}');
    }
    if (item.source.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('المصدر: ${item.source}');
    }
    buffer.writeln();
    buffer.writeln('— من تطبيق طالب علم');
    Share.share(buffer.toString());
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
    if (!_pageController.hasClients) return;
    HapticFeedback.selectionClick();
    _pageController.nextPage(
      duration: AppMotion.base,
      curve: AppMotion.easeOut,
    );
  }

  void _goPrev() {
    if (_loading || _index <= 0) return;
    if (!_pageController.hasClients) return;
    HapticFeedback.selectionClick();
    _pageController.previousPage(
      duration: AppMotion.base,
      curve: AppMotion.easeOut,
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
    final totalItems = _items.length;
    final progressRatio = totalItems > 0 ? (_index + 1) / totalItems : 0.0;

    final repeat = _repeatFor(_items, _index);
    final isCurrentComplete = repeat > 0 && _count >= repeat;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: PrimaryAppBar(
        title: title,
        showBack: true,
        bottom: totalItems > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.xl,
                        vertical: AppSpace.xs,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الذكر ${_index + 1} من $totalItems',
                            style: context.text.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: palette.gold,
                            ),
                          ),
                          Text(
                            '${(progressRatio * 100).round()}%',
                            style: context.text.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        minHeight: 3,
                        backgroundColor: palette.surfaceMuted,
                        valueColor: AlwaysStoppedAnimation<Color>(palette.gold),
                      ),
                    ),
                  ],
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
                : InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: _handleTap,
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            // ── 1. Dhikr Card Carousel & Floating Side Arrows ──
                            Expanded(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // PageView
                                  PageView.builder(
                                    controller: _pageController,
                                    itemCount: totalItems,
                                    onPageChanged: _onPageChanged,
                                    physics: const PageScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    itemBuilder: (context, index) {
                                      final item = _items[index];
                                      final itemRepeat = _repeatFor(_items, index);
                                      final itemKey = _favoriteIdFor(item);
                                      final itemCount = _counts[itemKey] ?? 0;
                                      final isDone = itemRepeat > 0 && itemCount >= itemRepeat;

                                      return AdhkarSessionCard(
                                        item: item,
                                        repeat: itemRepeat,
                                        isDone: isDone,
                                        onTap: _handleTap,
                                        fontScale: _fontScale,
                                        showTashkeel: _showTashkeel,
                                        onShare: _shareCurrentDhikr,
                                        onToggleTashkeel: _toggleTashkeel,
                                        onCycleFontSize: _cycleFontSize,
                                      );
                                    },
                                  ),

                                // Floating Previous Arrow (Right side in RTL)
                                if (_index > 0)
                                  PositionedDirectional(
                                    start: AppSpace.xs,
                                    child: FloatingChevronButton(
                                      icon: Icons.chevron_left_rounded,
                                      tooltip: 'الذكر السابق',
                                      onTap: _goPrev,
                                    ),
                                  ),

                                // Floating Next Arrow (Left side in RTL)
                                if (_index + 1 < totalItems)
                                  PositionedDirectional(
                                    end: AppSpace.xs,
                                    child: FloatingChevronButton(
                                      icon: Icons.chevron_right_rounded,
                                      tooltip: 'الذكر التالي',
                                      isHighlighted: isCurrentComplete,
                                      onTap: _goNext,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpace.xs),

                          // ── 2. Tactile Counter Dial ────────────────────────
                          DhikrCounterDial(
                            count: _count,
                            total: repeat,
                            isComplete: isCurrentComplete,
                            onTap: _handleTap,
                          ),

                          const SizedBox(height: AppSpace.md),

                          // ── 3. Ergonomic Bottom Navigation Dock ────────────
                          Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.xl,
                              vertical: AppSpace.sm,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Previous Dhikr Button (Right in RTL)
                                NavigationPillButton(
                                  icon: Icons.chevron_left_rounded,
                                  label: 'السابق',
                                  isLeadingIcon: true,
                                  isEnabled: _index > 0,
                                  onTap: _index > 0 ? _goPrev : null,
                                ),

                                // Reset Counter Button (Center)
                                Tooltip(
                                  message: 'إعادة العداد',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _resetCount,
                                      borderRadius: AppRadius.pillRadius,
                                      child: Container(
                                        padding: const EdgeInsetsDirectional.symmetric(
                                          horizontal: AppSpace.md,
                                          vertical: AppSpace.sm,
                                        ),
                                        decoration: BoxDecoration(
                                          color: palette.surfaceMuted,
                                          borderRadius: AppRadius.pillRadius,
                                          border: Border.all(color: palette.border),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.refresh_rounded,
                                              size: AppIcon.sm,
                                              color: palette.textMuted,
                                            ),
                                            const SizedBox(width: AppSpace.xs),
                                            Text(
                                              'إعادة',
                                              style: context.text.caption.copyWith(
                                                color: palette.textMuted,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Next Dhikr Button (Left in RTL)
                                NavigationPillButton(
                                  icon: Icons.chevron_right_rounded,
                                  label: 'التالي',
                                  isLeadingIcon: false,
                                  isHighlighted: isCurrentComplete,
                                  isEnabled: _index + 1 < totalItems,
                                  onTap: _index + 1 < totalItems ? _goNext : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpace.xs),
                        ],
                      ),

                      // Completion Golden Aurora Halo
                      if (_showSuccessRipple)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Center(
                              child: TweenAnimationBuilder<double>(
                                duration: AppMotion.slow,
                                curve: AppMotion.easeOut,
                                tween: Tween(begin: 0.8, end: 1.8),
                                builder: (context, scale, child) {
                                  final opacity =
                                      ((1.8 - scale) / 1.0).clamp(0.0, 1.0);
                                  return Transform.scale(
                                    scale: scale,
                                    child: Opacity(
                                      opacity: opacity,
                                      child: Container(
                                        width: 220,
                                        height: 220,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: palette.goldSoft
                                              .withValues(alpha: 0.35),
                                          border: Border.all(
                                            color: palette.gold
                                                .withValues(alpha: 0.6),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }

  String _catalogIdFor(AdhkarCategory category) {
    switch (category) {
      case AdhkarCategory.sleeping:
        return 'sleeping';
      case AdhkarCategory.afterPrayer:
        return 'after_prayer';
      case AdhkarCategory.prayerSunan:
        return 'prayer_sunan';
      case AdhkarCategory.beforePrayer:
        return 'before_prayer';
      case AdhkarCategory.waking:
        return 'waking';
      case AdhkarCategory.home:
        return 'home';
      case AdhkarCategory.mosqueAdhan:
        return 'mosque_adhan';
      case AdhkarCategory.wuduFood:
      case AdhkarCategory.wuduTaharah:
        return 'wudu_taharah';
      case AdhkarCategory.foodDrink:
        return 'food_drink';
      case AdhkarCategory.distress:
        return 'distress';
      case AdhkarCategory.travel:
        return 'travel';
      case AdhkarCategory.sicknessFunerals:
        return 'sickness_funerals';
      case AdhkarCategory.natureWeather:
        return 'nature_weather';
      case AdhkarCategory.socialManners:
        return 'social_manners';
      case AdhkarCategory.fastingHajj:
        return 'fasting_hajj';
      default:
        return category.name;
    }
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
