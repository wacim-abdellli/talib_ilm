import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../data/adhkar_models.dart';
import '../data/adhkar_service.dart';

class TasbeehIstighfarPage extends StatefulWidget {
  final int initialTabIndex;

  const TasbeehIstighfarPage({
    super.key,
    this.initialTabIndex = 0,
  });

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
                    ? const Icon(Icons.check, size: 18)
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
          title: const Text('تحديد الهدف', style: AppText.heading),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: 'مثال: 33'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 0),
              child: const Text('بدون هدف'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                Navigator.pop(context, value);
              },
              child: const Text('حفظ'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إكمال الهدف'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تسبيح واستغفار', style: AppText.headingXL),
        leading: const AppBackButton(),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'تسبيح'),
            Tab(text: 'استغفار'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _CounterCard(
                  label: _tasbeehItems.isEmpty
                      ? 'سبحان الله'
                      : _tasbeehItems[_tasbeehIndex].arabic,
                  count: _tasbeehCount,
                  accent: const Color(0xFF4CC9A6),
                  target: _tasbeehTarget,
                  onTap: _increment,
                  onReset: _reset,
                  onChangeDhikr: _changeDhikr,
                  onSetTarget: _setTarget,
                ),
                _CounterCard(
                  label: _istighfarItems.isEmpty
                      ? 'أستغفر الله'
                      : _istighfarItems[_istighfarIndex].arabic,
                  count: _istighfarCount,
                  accent: const Color(0xFF67B3E6),
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

class _CounterCard extends StatelessWidget {
  final String label;
  final int count;
  final int? target;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onReset;
  final VoidCallback onChangeDhikr;
  final VoidCallback onSetTarget;

  const _CounterCard({
    required this.label,
    required this.count,
    required this.target,
    required this.accent,
    required this.onTap,
    required this.onReset,
    required this.onChangeDhikr,
    required this.onSetTarget,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurface.withValues(
          alpha: 0.6,
        );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Column(
          children: [
            Text(label, style: AppText.athkarTitle.copyWith(color: secondary)),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.25),
                  ),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    target == null
                        ? 'اضغط للعد • بدون هدف'
                        : 'الهدف: $target',
                    style: AppText.caption.copyWith(color: secondary),
                  ),
                ),
                TextButton(
                  onPressed: onChangeDhikr,
                  child: const Text('تغيير الذكر'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    target == null
                        ? 'يمكنك تحديد هدف حسب رغبتك'
                        : 'التقدم: $count / $target',
                    style: AppText.caption.copyWith(color: secondary),
                  ),
                ),
                TextButton(
                  onPressed: onSetTarget,
                  child: const Text('تحديد الهدف'),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: onReset,
                  child: const Text('إعادة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
