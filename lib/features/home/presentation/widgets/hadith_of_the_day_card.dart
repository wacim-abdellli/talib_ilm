import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../core/services/hadith_favorites_service.dart';
import '../../domain/models/hadith.dart';

class HadithOfTheDayCard extends StatefulWidget {
  final Hadith initialHadith;

  const HadithOfTheDayCard({
    super.key,
    required this.initialHadith,
  });

  @override
  State<HadithOfTheDayCard> createState() => _HadithOfTheDayCardState();
}

class _HadithOfTheDayCardState extends State<HadithOfTheDayCard> {
  final HadithFavoritesService _favoritesService = HadithFavoritesService();

  late Hadith _hadith;
  bool _isSaved = false;

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
      setState(() => _hadith = widget.initialHadith);
      _loadSavedState();
    }
  }

  Future<void> _loadSavedState() async {
    final saved = await _favoritesService.isSaved(_hadith);
    if (!mounted) return;
    setState(() => _isSaved = saved);
  }

  Future<void> _toggleSave() async {
    final saved = await _favoritesService.toggleSaved(_hadith);
    if (!mounted) return;
    setState(() => _isSaved = saved);
  }

  Future<void> _share() async {
    final text = '${_hadith.text}\n— ${_hadith.source}';
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primary = colors.onSurface;
    final secondary = colors.onSurface.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
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
                  IconButton(
                    onPressed: _toggleSave,
                    icon: Icon(
                      _isSaved ? Icons.favorite : Icons.favorite_border,
                    ),
                    color: _isSaved ? colors.primary : secondary,
                    tooltip: 'حفظ',
                  ),
                  IconButton(
                    onPressed: _share,
                    icon: const Icon(Icons.share),
                    color: secondary,
                    tooltip: 'مشاركة',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Column(
              key: ValueKey(_hadith.text),
              children: [
                Text(
                  _hadith.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(
                    color: primary,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '— ${_hadith.source}',
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(color: secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
