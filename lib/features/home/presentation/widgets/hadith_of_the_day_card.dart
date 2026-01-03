import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../core/models/favorite_item.dart';
import '../../domain/models/hadith.dart';

class HadithOfTheDayCard extends StatefulWidget {
  final Hadith initialHadith;
  final Future<Hadith> Function(Hadith current)? onReload;

  const HadithOfTheDayCard({
    super.key,
    required this.initialHadith,
    this.onReload,
  });

  @override
  State<HadithOfTheDayCard> createState() => _HadithOfTheDayCardState();
}

class _HadithOfTheDayCardState extends State<HadithOfTheDayCard>
    with TickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService();

  late Hadith _hadith;
  bool _isSaved = false;
  bool _reloading = false;

  @override
  void initState() {
    super.initState();
    _hadith = widget.initialHadith;
    _loadSavedState();
  }

  @override
  void didUpdateWidget(covariant HadithOfTheDayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHadith.text != widget.initialHadith.text ||
        oldWidget.initialHadith.source != widget.initialHadith.source) {
      setState(() {
        _hadith = widget.initialHadith;
      });
      _loadSavedState();
    }
  }

  Future<void> _loadSavedState() async {
    final saved = await _favoritesService.isFavorite(
      FavoriteType.hadith,
      _idFor(_hadith),
    );
    if (!mounted) return;
    setState(() => _isSaved = saved);
  }

  Future<void> _toggleSave() async {
    final saved = await _favoritesService.toggle(
      FavoriteItem(
        type: FavoriteType.hadith,
        id: _idFor(_hadith),
        title: _hadith.text,
        subtitle: _hadith.source,
      ),
    );
    if (!mounted) return;
    setState(() => _isSaved = saved);
  }

  String _idFor(Hadith hadith) {
    return '${hadith.text}||${hadith.source}';
  }

  Future<void> _reload() async {
    final handler = widget.onReload;
    if (handler == null || _reloading) return;
    setState(() => _reloading = true);
    final next = await handler(_hadith);
    if (!mounted) return;
    setState(() {
      _hadith = next;
      _reloading = false;
    });
    _loadSavedState();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const primary = AppColors.textPrimary;
    const secondary = AppColors.textSecondary;
    final cardHeight =
        (MediaQuery.of(context).size.height * 0.2).clamp(80.0, 130.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppUi.cardShadow,
      ),
      child: SizedBox(
        height: cardHeight,
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth:520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'حديث اليوم',
                      style: AppText.caption.copyWith(color: secondary),
                    ),
                    Row(
                      children: [
                      PressableScale(
                        enabled: !_reloading,
                        child: IconButton(
                          onPressed: _reloading ? null : _reload,
                          icon: AnimatedRotation(
                            turns: _reloading ? 1 : 0,
                            duration: const Duration(milliseconds: 600),
                            child: const Icon(Icons.refresh),
                          ),
                          color: secondary,
                          tooltip: 'تحديث',
                        ),
                      ),
                      PressableScale(
                        child: IconButton(
                          onPressed: _toggleSave,
                          icon: Icon(
                            _isSaved ? Icons.favorite : Icons.favorite_border,
                          ),
                          color: _isSaved ? colors.primary : secondary,
                          tooltip: 'حفظ',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
                const SizedBox(height: 8),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: SingleChildScrollView(
                      key: ValueKey(_hadith.text),
                      physics: const ClampingScrollPhysics(),
                      child: Text(
                        _hadith.text,
                        textAlign: TextAlign.center,
                        style: AppText.body.copyWith(
                          color: primary,
                          height: 1.9,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_hadith.source.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '— ${_hadith.source}',
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(color: secondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
