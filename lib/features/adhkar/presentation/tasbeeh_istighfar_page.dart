import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../data/adhkar_models.dart';
import '../data/adhkar_service.dart';

class TasbeehIstighfarPage extends StatefulWidget {
  final int initialTabIndex;

  const TasbeehIstighfarPage({super.key, this.initialTabIndex = 0});

  @override
  State<TasbeehIstighfarPage> createState() => _TasbeehIstighfarPageState();
}

class _TasbeehIstighfarPageState extends State<TasbeehIstighfarPage>
    with SingleTickerProviderStateMixin {
  final AthkarService _service = AthkarService();
  late final TabController _tabController;
  bool _loading = true;
  int _tasbeehCount = 0;
  int _istighfarCount = 0;
  int _tasbeehIndex = 0;
  int _istighfarIndex = 0;
  int? _tasbeehTarget = 33;
  int? _istighfarTarget = 100;

  List<AthkarItem> _tasbeehItems = const [];
  List<AthkarItem> _istighfarItems = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final catalog = await _service.loadCatalog();
    final tasbeeh = catalog.byId('tasbeeh');
    final istighfar = catalog.byId('istighfar');
    if (!mounted) return;
    setState(() {
      _tasbeehItems = tasbeeh?.items ?? const [];
      _istighfarItems = istighfar?.items ?? const [];
      _tasbeehTarget = _defaultTarget(_tasbeehItems, _tasbeehIndex) ?? 33;
      _istighfarTarget = _defaultTarget(_istighfarItems, _istighfarIndex) ?? 100;
      _loading = false;
    });
  }

  int? _defaultTarget(List<AthkarItem> items, int index) {
    if (items.isEmpty || index >= items.length) return null;
    final target = items[index].target;
    return target <= 0 ? null : target;
  }

  void _increment() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_tabController.index == 0) {
        _tasbeehCount += 1;
        _maybeNotifyTarget(_tasbeehCount, _tasbeehTarget);
      } else {
        _istighfarCount += 1;
        _maybeNotifyTarget(_istighfarCount, _istighfarTarget);
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_tabController.index == 0) {
        _tasbeehCount = 0;
      } else {
        _istighfarCount = 0;
      }
    });
    AppSnackbar.info(context, 'تمت إعادة ضبط العداد');
  }

  Future<void> _changeDhikr() async {
    final isTasbeeh = _tabController.index == 0;
    final options = isTasbeeh ? _tasbeehItems : _istighfarItems;
    final currentIndex = isTasbeeh ? _tasbeehIndex : _istighfarIndex;

    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: context.goldColor.withValues(alpha: isDark ? 0.3 : 0.15),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: context.outlineVariantColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Icon(
                      isTasbeeh ? Icons.all_inclusive_rounded : Icons.favorite_rounded,
                      color: context.goldColor,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isTasbeeh ? 'اختر صيغة التسبيح' : 'اختر صيغة الاستغفار',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: options.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = options[index];
                    final isSelected = index == currentIndex;
                    return InkWell(
                      onTap: () => Navigator.pop(context, index),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.goldColor.withValues(alpha: isDark ? 0.16 : 0.1)
                              : context.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? context.goldColor
                                : context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.arabic,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimaryColor,
                                      height: 1.5,
                                    ),
                                  ),
                                  if (item.fadl.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.fadl,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12,
                                        color: context.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (isSelected)
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: context.goldColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              )
                            else if (item.target > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: context.outlineVariantColor.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${item.target}x',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null || selected == currentIndex) return;
    setState(() {
      if (isTasbeeh) {
        _tasbeehIndex = selected;
        _tasbeehCount = 0;
        _tasbeehTarget = _defaultTarget(_tasbeehItems, _tasbeehIndex) ?? _tasbeehTarget;
      } else {
        _istighfarIndex = selected;
        _istighfarCount = 0;
        _istighfarTarget = _defaultTarget(_istighfarItems, _istighfarIndex) ?? _istighfarTarget;
      }
    });
  }

  Future<void> _setTarget() async {
    final isTasbeeh = _tabController.index == 0;
    final currentTarget = isTasbeeh ? _tasbeehTarget : _istighfarTarget;
    final controller = TextEditingController(
      text: currentTarget != null ? currentTarget.toString() : '',
    );

    final selected = await showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: context.goldColor.withValues(alpha: isDark ? 0.3 : 0.15),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.outlineVariantColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.flag_rounded, color: context.goldColor, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      AppStrings.targetTitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Quick preset pills
                Text(
                  'أهداف مقترحة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [33, 100, 1000].map((preset) {
                    final isCurrent = currentTarget == preset;
                    return InkWell(
                      onTap: () => Navigator.pop(context, preset),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? context.goldColor.withValues(alpha: 0.2)
                              : context.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent ? context.goldColor : context.outlineVariantColor,
                          ),
                        ),
                        child: Text(
                          '$num مرة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                            color: isCurrent ? context.goldColor : context.textPrimaryColor,
                          ),
                        ),
                      ),
                    );
                  }).toList()
                    ..add(
                      InkWell(
                        onTap: () => Navigator.pop(context, 0),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: currentTarget == null
                                ? context.primaryColor.withValues(alpha: 0.2)
                                : context.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: currentTarget == null
                                  ? context.primaryColor
                                  : context.outlineVariantColor,
                            ),
                          ),
                          child: Text(
                            'بدون هدف (حر)',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600,
                              color: currentTarget == null
                                  ? context.primaryColor
                                  : context.textPrimaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                ),
                const SizedBox(height: 20),
                Text(
                  'أو حدد رقماً مخصصاً:',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        autofocus: false,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          color: context.textPrimaryColor,
                          fontSize: 18,
                        ),
                        decoration: InputDecoration(
                          hintText: 'مثال: 500',
                          filled: true,
                          fillColor: context.surfaceContainer,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: context.outlineVariantColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: context.goldColor, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () {
                        final val = int.tryParse(controller.text);
                        Navigator.pop(context, val);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: context.goldColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'حفظ',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    setState(() {
      final newTarget = selected <= 0 ? null : selected;
      if (isTasbeeh) {
        _tasbeehTarget = newTarget;
      } else {
        _istighfarTarget = newTarget;
      }
    });
  }

  void _maybeNotifyTarget(int count, int? target) {
    if (target == null || count != target) return;
    HapticFeedback.heavyImpact();
    AppSnackbar.success(
      context,
      '🎉 ما شاء الله! أتممت هدف الذكر ($target مرة)',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: UnifiedAppBar(
        title: AppStrings.tasbeehTitle,
        showBack: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.primaryColor,
                    context.primaryColor.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: context.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: context.textSecondaryColor,
              labelStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.all_inclusive_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(AppStrings.tasbeehTab),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(AppStrings.istighfarTab),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _RosaryDial(
                  label: _tasbeehItems.isEmpty
                      ? AppStrings.tasbeehDefault
                      : _tasbeehItems[_tasbeehIndex].arabic,
                  count: _tasbeehCount,
                  target: _tasbeehTarget,
                  onTap: _increment,
                  onReset: _reset,
                  onChangeDhikr: _changeDhikr,
                  onSetTarget: _setTarget,
                ),
                _RosaryDial(
                  label: _istighfarItems.isEmpty
                      ? AppStrings.istighfarDefault
                      : _istighfarItems[_istighfarIndex].arabic,
                  count: _istighfarCount,
                  target: _istighfarTarget,
                  onTap: _increment,
                  onReset: _reset,
                  onChangeDhikr: _changeDhikr,
                  onSetTarget: _setTarget,
                ),
              ],
            ),
    );
  }
}

class _RosaryDial extends StatefulWidget {
  final String label;
  final int count;
  final int? target;
  final VoidCallback onTap;
  final VoidCallback onReset;
  final VoidCallback onChangeDhikr;
  final VoidCallback onSetTarget;

  const _RosaryDial({
    required this.label,
    required this.count,
    required this.target,
    required this.onTap,
    required this.onReset,
    required this.onChangeDhikr,
    required this.onSetTarget,
  });

  @override
  State<_RosaryDial> createState() => _RosaryDialState();
}

class _RosaryDialState extends State<_RosaryDial> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _pulseController.forward().then((_) {
      if (mounted) _pulseController.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = widget.target != null && widget.target! > 0
        ? (widget.count / widget.target!).clamp(0.0, 1.0)
        : 0.0;
    final isCompleted = widget.target != null && widget.count >= widget.target!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Top Dhikr Display Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: context.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.goldColor.withValues(alpha: isDark ? 0.3 : 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: widget.onChangeDhikr,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: context.goldColor.withValues(alpha: isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.goldColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz_rounded, size: 16, color: context.goldColor),
                          const SizedBox(width: 6),
                          Text(
                            AppStrings.changeDhikr,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: context.goldColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Interactive Astrolabe Rosary Medallion
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer decorative halo
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            (isCompleted ? context.goldColor : context.primaryColor)
                                .withValues(alpha: isDark ? 0.18 : 0.1),
                            Colors.transparent,
                          ],
                          stops: const [0.7, 1.0],
                        ),
                      ),
                    ),

                    // Custom Painter Dial Rings & Progress
                    CustomPaint(
                      size: const Size(220, 220),
                      painter: _RosaryPainter(
                        progress: progress,
                        baseColor: context.outlineVariantColor.withValues(alpha: 0.4),
                        activeColor: isCompleted ? context.goldColor : context.primaryColor,
                        accentGold: context.goldColor,
                        isCompleted: isCompleted,
                      ),
                    ),

                    // Center Glassmorphic Dial Core
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.surfaceColor,
                        border: Border.all(
                          color: (isCompleted ? context.goldColor : context.primaryColor)
                              .withValues(alpha: isDark ? 0.4 : 0.25),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.count.toString(),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 54,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: isCompleted ? context.goldColor : context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.target != null
                                ? 'الهدف: ${widget.target}'
                                : 'عدّ حر',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isCompleted
                                  ? context.goldColor
                                  : context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              'المس الشاشة للتسبيح',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: context.textTertiaryColor,
              ),
            ),

            const Spacer(),

            // Bottom Action Control Island
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: context.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.outlineColor.withValues(alpha: isDark ? 0.2 : 0.08),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Set Target Button
                  InkWell(
                    onTap: widget.onSetTarget,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 20, color: context.goldColor),
                          const SizedBox(width: 8),
                          Text(
                            widget.target != null ? '${widget.target} مرة' : 'تحديد هدف',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 24,
                    color: context.outlineVariantColor,
                  ),

                  // Reset Button
                  InkWell(
                    onTap: widget.onReset,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.refresh_rounded, size: 20, color: context.textSecondaryColor),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.reset,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _RosaryPainter extends CustomPainter {
  final double progress;
  final Color baseColor;
  final Color activeColor;
  final Color accentGold;
  final bool isCompleted;

  _RosaryPainter({
    required this.progress,
    required this.baseColor,
    required this.activeColor,
    required this.accentGold,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background track
    final trackPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 6, trackPaint);

    // Decorative Astrolabe Ticks (33 ticks)
    final tickPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;

    const tickCount = 33;
    for (int i = 0; i < tickCount; i++) {
      final angle = (i * 2 * math.pi / tickCount) - (math.pi / 2);
      final outerX = center.dx + (radius + 2) * math.cos(angle);
      final outerY = center.dy + (radius + 2) * math.sin(angle);
      final innerX = center.dx + (radius - 1) * math.cos(angle);
      final innerY = center.dy + (radius - 1) * math.sin(angle);
      canvas.drawLine(Offset(innerX, innerY), Offset(outerX, outerY), tickPaint);
    }

    // Active progress arc
    if (progress > 0) {
      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 6),
        -math.pi / 2,
        sweepAngle,
        false,
        activePaint,
      );

      // Gold bead at the tip of progress
      final tipAngle = -math.pi / 2 + sweepAngle;
      final tipX = center.dx + (radius - 6) * math.cos(tipAngle);
      final tipY = center.dy + (radius - 6) * math.sin(tipAngle);

      final beadGlowPaint = Paint()
        ..color = accentGold.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tipX, tipY), 10, beadGlowPaint);

      final beadPaint = Paint()
        ..color = accentGold
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tipX, tipY), 6, beadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RosaryPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.isCompleted != isCompleted;
  }
}
