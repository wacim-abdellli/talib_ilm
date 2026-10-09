import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../data/adhkar_models.dart';
import '../data/adhkar_service.dart';
import 'widgets/change_dhikr_sheet.dart';
import 'widgets/rosary_dial.dart';
import 'widgets/set_target_sheet.dart';

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

    final selected = await showChangeDhikrSheet(
      context: context,
      options: options,
      currentIndex: currentIndex,
      isTasbeeh: isTasbeeh,
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

    final selected = await showSetTargetSheet(
      context: context,
      currentTarget: currentTarget,
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
              RosaryDial(
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
              RosaryDial(
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
