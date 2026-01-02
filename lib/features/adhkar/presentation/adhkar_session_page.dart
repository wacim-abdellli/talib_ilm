import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/services/adhkar_session_service.dart';
import '../data/adhkar_models.dart';

class AdhkarSessionPage extends StatefulWidget {
  final AdhkarCategory category;

  const AdhkarSessionPage({super.key, required this.category});

  @override
  State<AdhkarSessionPage> createState() => _AdhkarSessionPageState();
}

class _AdhkarSessionPageState extends State<AdhkarSessionPage> {
  final AdhkarSessionService _sessionService = AdhkarSessionService();

  late final List<DhikrItem> _items;
  late final PageController _pageController;
  int _index = 0;
  int _count = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _items = _itemsFor(widget.category);
    _pageController = PageController();
    _loadState();
  }

  Future<void> _loadState() async {
    final state = await _sessionService.loadState(widget.category);
    if (!mounted) return;
    setState(() {
      _index = state.index.clamp(0, _items.length);
      _count = state.count.clamp(0, _currentRepeat());
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToIndex(_index);
    });
  }

  int _currentRepeat() {
    if (_index >= _items.length) return 1;
    return _items[_index].repeat;
  }

  Future<void> _saveState() async {
    await _sessionService.saveState(
      widget.category,
      AdhkarSessionState(index: _index, count: _count),
    );
  }

  void _handleTap() {
    if (_loading || _index >= _items.length) return;

    HapticFeedback.selectionClick();

    final repeat = _items[_index].repeat;
    final nextCount = _count + 1;

    if (nextCount >= repeat) {
      _index += 1;
      _count = 0;
      if (_index >= _items.length) {
        HapticFeedback.mediumImpact();
      } else {
        _animateToIndex(_index);
      }
    } else {
      _count = nextCount;
    }

    setState(() {});
    _saveState();
  }

  void _handleUndo() {
    if (_loading) return;
    if (_index == 0 && _count == 0) return;

    if (_count > 0) {
      _count -= 1;
    } else if (_index > 0) {
      _index -= 1;
      final repeat = _items[_index].repeat;
      _count = repeat > 0 ? repeat - 1 : 0;
      _animateToIndex(_index);
    }

    setState(() {});
    _saveState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.category.label, style: AppText.headingXL),
      ),
      body: _loading
          ? const SizedBox.shrink()
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleTap,
              onLongPress: _handleUndo,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: _index >= _items.length
                      ? _buildCompletion()
                      : _buildSession(),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildSession() {
    final secondary = Theme.of(context).colorScheme.onSurface.withValues(
          alpha: 0.6,
        );
    final currentItem = _index < _items.length ? _items[_index] : null;
    final repeat = currentItem?.repeat ?? 1;
    final progress = repeat <= 1 ? 1.0 : _count / repeat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.category.label,
          style: AppText.bodyMuted.copyWith(color: secondary),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _items.length,
            onPageChanged: _handlePageChange,
            reverse: Directionality.of(context) == TextDirection.rtl,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Center(
                child: Text(
                  item.text,
                  textAlign: TextAlign.center,
                  style: AppText.headingXL.copyWith(
                    height: 1.9,
                  ),
                ),
              );
            },
          ),
        ),
        if (currentItem?.reference != null &&
            currentItem!.reference!.isNotEmpty) ...[
          Text(
            currentItem.reference!,
            style: AppText.caption.copyWith(color: secondary),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الذكر ${_index + 1} من ${_items.length}',
              style: AppText.caption.copyWith(color: secondary),
            ),
            _ProgressRing(
              progress: progress,
              label: repeat > 1 ? '${_count + 1}/$repeat' : '1/1',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletion() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0.92, end: 1),
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 320),
            opacity: 1,
            child: Text('أحسنت', style: AppText.headingXL),
          ),
          const SizedBox(height: 8),
          Text(
            'بارك الله فيك',
            style: AppText.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            children: [
              FilledButton(
                onPressed: _resetSession,
                child: const Text('إعادة'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('رجوع'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _resetSession() async {
    setState(() {
      _index = 0;
      _count = 0;
    });
    _jumpToIndex(0);
    await _saveState();
  }

  void _handlePageChange(int index) {
    if (_loading || index == _index) return;
    setState(() {
      _index = index;
      _count = 0;
    });
    _saveState();
  }

  void _jumpToIndex(int index) {
    if (!_pageController.hasClients || _items.isEmpty) return;
    final target = index.clamp(0, _items.length - 1);
    _pageController.jumpToPage(target);
  }

  void _animateToIndex(int index) {
    if (!_pageController.hasClients || _items.isEmpty) return;
    final target = index.clamp(0, _items.length - 1);
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  List<DhikrItem> _itemsFor(AdhkarCategory category) {
    switch (category) {
      case AdhkarCategory.morning:
        return const [
          DhikrItem(text: 'أصبحنا وأصبح الملك لله والحمد لله', repeat: 1),
          DhikrItem(text: 'سبحان الله وبحمده', repeat: 100),
          DhikrItem(text: 'لا إله إلا الله وحده لا شريك له', repeat: 10),
          DhikrItem(text: 'رضيت بالله ربًا وبالإسلام دينًا', repeat: 3),
        ];
      case AdhkarCategory.evening:
        return const [
          DhikrItem(text: 'أمسينا وأمسى الملك لله والحمد لله', repeat: 1),
          DhikrItem(text: 'سبحان الله وبحمده', repeat: 100),
          DhikrItem(text: 'لا إله إلا الله وحده لا شريك له', repeat: 10),
          DhikrItem(text: 'حسبي الله لا إله إلا هو', repeat: 7),
        ];
      case AdhkarCategory.beforePrayer:
        return const [
          DhikrItem(text: 'اللهم اجعلني من التوابين واجعلني من المتطهرين'),
          DhikrItem(text: 'أشهد أن لا إله إلا الله وحده لا شريك له'),
          DhikrItem(text: 'اللهم افتح لي أبواب رحمتك'),
        ];
      case AdhkarCategory.afterPrayer:
        return const [
          DhikrItem(text: 'أستغفر الله', repeat: 3),
          DhikrItem(text: 'اللهم أنت السلام ومنك السلام'),
          DhikrItem(text: 'سبحان الله', repeat: 33),
          DhikrItem(text: 'الحمد لله', repeat: 33),
          DhikrItem(text: 'الله أكبر', repeat: 34),
        ];
      case AdhkarCategory.general:
        return const [
          DhikrItem(text: 'سبحان الله'),
          DhikrItem(text: 'الحمد لله'),
          DhikrItem(text: 'لا إله إلا الله'),
          DhikrItem(text: 'الله أكبر'),
        ];
    }
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  final String label;

  const _ProgressRing({required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurface.withValues(
          alpha: 0.6,
        );
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0, 1),
            strokeWidth: 4,
            backgroundColor: AppColors.textPrimary.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          Text(
            label,
            style: AppText.caption.copyWith(color: secondary),
          ),
        ],
      ),
    );
  }
}
