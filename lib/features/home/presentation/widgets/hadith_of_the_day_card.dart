import 'package:flutter/material.dart';
import '../../../../app/constants/app_strings.dart';
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
  final ScrollController _sheetController = ScrollController();

  @override
  void initState() {
    super.initState();
    _hadith = widget.initialHadith;
    _loadSavedState();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
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

  void _openFullHadith() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppUi.radiusLG),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppUi.gapXL,
            AppUi.gapMD,
            AppUi.gapXL,
            AppUi.gapXXL,
          ),
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height * AppUi.sheetHeightFactor,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: AppUi.handleWidth,
                  height: AppUi.handleHeight,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(AppUi.radiusPill),
                  ),
                ),
                const SizedBox(height: AppUi.gapLG),
                Text(AppStrings.homeHadithTitle, style: AppText.heading),
                const SizedBox(height: AppUi.gapMD),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _sheetController,
                    child: SelectableText(
                      _hadith.text,
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                if (_hadith.source.isNotEmpty) ...[
                  const SizedBox(height: AppUi.gapMD),
                  Text(
                    AppStrings.sourcePrefix(_hadith.source),
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppUi.gapMD),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(AppStrings.actionClose),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
    final cardHeight = (MediaQuery.of(context).size.height *
            AppUi.hadithCardHeightFactor)
        .clamp(AppUi.hadithCardMinHeight, AppUi.hadithCardMaxHeight)
        .toDouble();
    final isLong = _hadith.text.length > 160;

    return Container(
      padding: AppUi.cardPadding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppUi.radiusMD),
        boxShadow: AppUi.cardShadow,
      ),
      child: SizedBox(
        height: cardHeight,
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppUi.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.homeHadithTitle,
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
                              duration: AppUi.animationSlowest,
                              child: const Icon(Icons.refresh),
                            ),
                            color: secondary,
                            tooltip: AppStrings.actionUpdate,
                          ),
                        ),
                        PressableScale(
                          child: IconButton(
                            onPressed: _toggleSave,
                            icon: Icon(
                              _isSaved
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                            ),
                            color: _isSaved ? colors.primary : secondary,
                            tooltip: AppStrings.actionSave,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppUi.gapSM),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppUi.animationNormal,
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: GestureDetector(
                      key: ValueKey(_hadith.text),
                      onTap: isLong ? _openFullHadith : null,
                      child: Text(
                        _hadith.text,
                        textAlign: TextAlign.center,
                        maxLines: isLong ? 4 : null,
                        overflow:
                            isLong ? TextOverflow.ellipsis : TextOverflow.visible,
                        style: AppText.body.copyWith(color: primary),
                      ),
                    ),
                  ),
                ),
                if (_hadith.source.isNotEmpty) ...[
                  const SizedBox(height: AppUi.gapSM),
                  Text(
                    AppStrings.sourcePrefix(_hadith.source),
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
