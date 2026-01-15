import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talib_ilm/shared/widgets/app_popup.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../shared/widgets/primary_app_bar.dart';
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
  int? _tasbeehTarget;
  int? _istighfarTarget;

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
      _tasbeehTarget = _defaultTarget(_tasbeehItems, _tasbeehIndex);
      _istighfarTarget = _defaultTarget(_istighfarItems, _istighfarIndex);
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
    setState(() {
      if (_tabController.index == 0) {
        _tasbeehCount = 0;
      } else {
        _istighfarCount = 0;
      }
    });
  }

  Future<void> _changeDhikr() async {
    final isTasbeeh = _tabController.index == 0;
    final options = isTasbeeh ? _tasbeehItems : _istighfarItems;
    final currentIndex = isTasbeeh ? _tasbeehIndex : _istighfarIndex;
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return SafeArea(
          top: false,
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(options[index].arabic, style: AppText.athkarTitle),
                trailing: index == currentIndex
                    ? const Icon(Icons.check, size: AppUi.iconSizeSM)
                    : null,
                onTap: () => Navigator.pop(context, index),
              );
            },
          ),
        );
      },
    );

    if (!mounted || selected == null || selected == currentIndex) return;
    setState(() {
      if (isTasbeeh) {
        _tasbeehIndex = selected;
        _tasbeehCount = 0;
        _tasbeehTarget = _defaultTarget(_tasbeehItems, _tasbeehIndex);
      } else {
        _istighfarIndex = selected;
        _istighfarCount = 0;
        _istighfarTarget = _defaultTarget(_istighfarItems, _istighfarIndex);
      }
    });
  }

  Future<void> _setTarget() async {
    final isTasbeeh = _tabController.index == 0;
    final currentTarget = isTasbeeh ? _tasbeehTarget : _istighfarTarget;
    final controller = TextEditingController(
      text: currentTarget?.toString() ?? '',
    );

    final selected = await showDialog<int?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.targetTitle, style: AppText.heading),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: AppStrings.targetHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.targetCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 0),
              child: const Text(AppStrings.targetNoGoal),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                Navigator.pop(context, value);
              },
              child: const Text(AppStrings.targetSave),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    setState(() {
      if (isTasbeeh) {
        _tasbeehTarget = selected == null || selected <= 0 ? null : selected;
      } else {
        _istighfarTarget = selected == null || selected <= 0 ? null : selected;
      }
    });
  }

  void _maybeNotifyTarget(int count, int? target) {
    if (target == null || count != target) return;
    AppPopup.show(
      context: context,
      title: 'إنجاز الهدف',
      message: AppStrings.targetCompleted,
      icon: Icons.check_circle_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UnifiedAppBar(
        title: AppStrings.tasbeehTitle,
        showBack: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: AppStrings.tasbeehTab),
            Tab(text: AppStrings.istighfarTab),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _CounterCard(
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
                  _CounterCard(
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
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  final String label;
  final int count;
  final int? target;
  final VoidCallback onTap;
  final VoidCallback onReset;
  final VoidCallback onChangeDhikr;
  final VoidCallback onSetTarget;

  const _CounterCard({
    required this.label,
    required this.count,
    required this.target,
    required this.onTap,
    required this.onReset,
    required this.onChangeDhikr,
    required this.onSetTarget,
  });

  @override
  Widget build(BuildContext context) {
    const secondary = AppColors.textSecondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: AppUi.screenPaddingTopLarge,
        child: Column(
          children: [
            Text(label, style: AppText.athkarTitle.copyWith(color: secondary)),
            const SizedBox(height: AppUi.gapLG),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppUi.paddingLG),
                decoration: BoxDecoration(
                  gradient: AppColors.surfaceElevatedGradient,
                  borderRadius: BorderRadius.circular(AppUi.radiusLG),
                  boxShadow: AppUi.cardShadow,
                ),
                child: Center(
                  child: Text(
                    count.toString(),
                    style: AppText.athkarCounter.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppUi.gapLG),
            Row(
              children: [
                Expanded(
                  child: Text(
                    target == null
                        ? AppStrings.tapToCountNoTarget
                        : AppStrings.targetLabel(target!),
                    style: AppText.caption.copyWith(color: secondary),
                  ),
                ),
                TextButton(
                  onPressed: onChangeDhikr,
                  child: const Text(AppStrings.changeDhikr),
                ),
              ],
            ),
            const SizedBox(height: AppUi.gapSM),
            Row(
              children: [
                Expanded(
                  child: Text(
                    target == null
                        ? AppStrings.targetHintMessage
                        : AppStrings.progressLabel(count, target!),
                    style: AppText.caption.copyWith(color: secondary),
                  ),
                ),
                TextButton(
                  onPressed: onSetTarget,
                  child: const Text(AppStrings.setTarget),
                ),
                const SizedBox(width: AppUi.gapXSPlus),
                TextButton(
                  onPressed: onReset,
                  child: const Text(AppStrings.reset),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
