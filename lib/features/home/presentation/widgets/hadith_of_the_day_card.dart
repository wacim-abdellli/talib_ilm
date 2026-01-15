import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talib_ilm/shared/widgets/app_popup.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../app/theme/app_text_styles.dart';
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

  void _copyHadith(Hadith hadith) {
    final content = hadith.source.isNotEmpty
        ? '${hadith.text}\n\n${hadith.source}'
        : hadith.text;

    Clipboard.setData(ClipboardData(text: content));

    AppPopup.show(
      context: context,
      title: 'تم النسخ',
      message: 'تم نسخ الحديث إلى الحافظة',
      icon: Icons.copy_rounded,
    );
  }

  String _idFor(Hadith hadith) {
    return '${hadith.text}||${hadith.source}';
  }

  void _openFullHadith() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFFFFFF),
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
                Text(
                  AppStrings.homeHadithTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppUi.gapMD),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _sheetController,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: SelectableText(
                        _hadith.text,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.9,
                          fontFamily: 'Amiri',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_hadith.source.isNotEmpty) ...[
                  const SizedBox(height: AppUi.gapMD),
                  Text(
                    _hadith.source,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
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
    final cardHeight = (MediaQuery.of(context).size.height *
            AppUi.hadithCardHeightFactor)
        .clamp(AppUi.hadithCardMinHeight, AppUi.hadithCardMaxHeight)
        .toDouble();
    final radius = BorderRadius.circular(AppUi.radiusMD);
    final shadowColor = const Color(0xFF8B7355).withValues(alpha: 0.06);

    return PressableScale(
      pressedScale: AppUi.pressScale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _openFullHadith,
            onLongPress: widget.onReload == null ? null : _reload,
            borderRadius: radius,
            splashColor: AppColors.primary.withValues(alpha: 0.08),
            highlightColor: AppColors.primary.withValues(alpha: 0.04),
            child: Ink(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: radius,
              ),
              child: SizedBox(
                height: cardHeight,
                child: Padding(
                  padding: const EdgeInsets.all(AppUi.gapXL),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: AppUi.maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              const Text(
                                '﴿',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppUi.gapXS),
                              const Text(
                                AppStrings.homeHadithTitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              if (widget.onReload != null)
                                _ActionIconButton(
                                  icon: Icons.refresh_rounded,
                                  onTap: _reload,
                                  tooltip: AppStrings.actionUpdate,
                                ),
                              const SizedBox(width: AppUi.gapXS),
                              _ActionIconButton(
                                icon: Icons.content_copy_outlined,
                                onTap: () => _copyHadith(_hadith),
                                tooltip: AppStrings.actionCopy,
                              ),
                              const SizedBox(width: AppUi.gapXS),
                              _ActionIconButton(
                                icon: _isSaved
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                onTap: _toggleSave,
                                tooltip: AppStrings.actionSave,
                                color: _isSaved
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
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
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  child: SingleChildScrollView(
                                    key: ValueKey(_hadith.text),
                                    physics: const ClampingScrollPhysics(),
                                    child: Text(
                                      _hadith.text,
                                      textAlign: TextAlign.right,
                                      textDirection: TextDirection.rtl,
                                      style: AppTextStyles.hadithArabic,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                          const SizedBox(height: AppUi.gapMD),
                          FractionallySizedBox(
                            widthFactor: 0.6,
                            child: Container(
                              height: 1,
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(height: AppUi.gapMD),
                          if (_hadith.source.isNotEmpty)
                            Text(
                              _hadith.source,
                              textAlign: TextAlign.right,
                              style: AppTextStyles.hadithNarrator,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color color;

  const _ActionIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 20,
        color: color,
      ),
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
      splashRadius: 18,
    );
  }
}
