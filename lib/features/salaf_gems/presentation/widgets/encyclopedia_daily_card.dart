import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/models/salaf_gem.dart';
import '../../data/repositories/salaf_gems_repository.dart';
import 'salaf_gem_share_sheet.dart';

class EncyclopediaDailyCard extends StatefulWidget {
  final ValueChanged<SalafGem>? onOpenGemSection;

  const EncyclopediaDailyCard({
    super.key,
    this.onOpenGemSection,
  });

  @override
  State<EncyclopediaDailyCard> createState() => _EncyclopediaDailyCardState();
}

class _EncyclopediaDailyCardState extends State<EncyclopediaDailyCard> {
  final SalafGemsRepository _repository = SalafGemsRepository.instance;
  SalafGem? _gem;
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDaily();
  }

  Future<void> _loadDaily() async {
    final daily = await _repository.getDailyGem();
    final fav = await _repository.isFavorite(daily.id);
    if (!mounted) return;
    setState(() {
      _gem = daily;
      _isFavorite = fav;
      _isLoading = false;
    });
  }

  Future<void> _refreshGem() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    final next = await _repository.getRandomGem(excludingId: _gem?.id);
    final fav = await _repository.isFavorite(next.id);
    if (!mounted) return;
    setState(() {
      _gem = next;
      _isFavorite = fav;
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final gem = _gem;
    if (gem == null) return;
    HapticFeedback.lightImpact();
    final fav = await _repository.toggleFavorite(gem.id);
    if (!mounted) return;
    setState(() => _isFavorite = fav);
    AppSnackbar.info(
      context,
      fav ? 'أضيفت إلى المفضلة' : 'أزيلت من المفضلة',
      hasNavBar: false,
    );
  }

  void _copyGem() {
    final gem = _gem;
    if (gem == null) return;
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: gem.shareableText));
    AppSnackbar.success(
      context,
      'تم نسخ الدرّة والمصدر إلى الحافظة',
      hasNavBar: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final gem = _gem;

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: palette.gold.withValues(alpha: 0.28),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm,
            ),
            color: palette.surfaceMuted,
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: palette.gold,
                  size: AppIcon.sm,
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    'قطوف من الكلم الطيب',
                    style: textTheme.titleSmall.copyWith(
                      color: palette.gold,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xs / 2,
                  ),
                  decoration: BoxDecoration(
                    color: palette.gold.withValues(alpha: 0.15),
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Text(
                    'درّة اليوم',
                    style: textTheme.captionBold.copyWith(
                      color: palette.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            child: _isLoading || gem == null
                ? SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: palette.gold,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '«${gem.cleanText}»',
                        style: textTheme.sacred.copyWith(
                          color: palette.text,
                          height: 1.85,
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '— ${gem.author}',
                                  style: textTheme.titleSmall.copyWith(
                                    color: palette.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (gem.topic.isNotEmpty) ...[
                                  const SizedBox(height: AppSpace.xs / 2),
                                  InkWell(
                                    onTap: () => widget.onOpenGemSection?.call(gem),
                                    child: Text(
                                      'القسم: ${gem.topic}',
                                      style: textTheme.caption.copyWith(
                                        color: palette.textMuted,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: palette.gold,
                              size: AppIcon.md,
                            ),
                            tooltip: 'تغيير الدرّة',
                            onPressed: _refreshGem,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),

          const Divider(height: 1),

          // Bottom Actions
          if (gem != null)
            Container(
              color: palette.surfaceMuted,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.xs,
                vertical: AppSpace.xs / 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _toggleFavorite,
                      icon: Icon(
                        _isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: _isFavorite ? palette.gold : palette.textMuted,
                        size: AppIcon.sm,
                      ),
                      label: Text(
                        'المفضلة',
                        style: textTheme.caption.copyWith(
                          color: _isFavorite ? palette.gold : palette.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: palette.border,
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => SalafGemShareSheet.show(context, gem),
                      icon: Icon(
                        Icons.share_rounded,
                        color: palette.textMuted,
                        size: AppIcon.sm,
                      ),
                      label: Text(
                        'مشاركة',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: palette.border,
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _copyGem,
                      icon: Icon(
                        Icons.content_copy_rounded,
                        color: palette.textMuted,
                        size: AppIcon.sm,
                      ),
                      label: Text(
                        'نسخ',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
