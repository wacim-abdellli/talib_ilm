import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/models/favorite_item.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../core/services/hadith_favorites_service.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/models/hadith_models.dart';

class HadithCard extends StatefulWidget {
  final GradedHadith hadith;
  final bool initiallyExpanded;
  final double fontScale;

  const HadithCard({
    super.key,
    required this.hadith,
    this.initiallyExpanded = false,
    this.fontScale = 1.0,
  });

  @override
  State<HadithCard> createState() => _HadithCardState();
}

class _HadithCardState extends State<HadithCard> {
  final HadithFavoritesService _favService = HadithFavoritesService();
  late bool _isExpanded;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _checkFavorite();
  }

  @override
  void didUpdateWidget(covariant HadithCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hadith.id != widget.hadith.id) {
      _checkFavorite();
    }
  }

  Future<void> _checkFavorite() async {
    final legacySaved = await _favService.isSaved(widget.hadith.toLegacyHadith());
    final hadithId = widget.hadith.id.isNotEmpty
        ? widget.hadith.id
        : widget.hadith.matn.hashCode.toString();
    final generalSaved = await FavoritesService().isFavorite(
      FavoriteType.hadith,
      hadithId,
    );
    final fav = legacySaved || generalSaved;
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.lightImpact();
    final next = await _favService.toggleSaved(widget.hadith.toLegacyHadith());
    final hadithId = widget.hadith.id.isNotEmpty
        ? widget.hadith.id
        : widget.hadith.matn.hashCode.toString();
    final favItem = FavoriteItem(
      type: FavoriteType.hadith,
      id: hadithId,
      title: widget.hadith.title.isNotEmpty ? widget.hadith.title : widget.hadith.matn,
      subtitle: widget.hadith.source.isNotEmpty
          ? '${widget.hadith.source} • ${widget.hadith.category}'
          : widget.hadith.category,
    );
    if (next) {
      await FavoritesService().add(favItem);
    } else {
      await FavoritesService().remove(FavoriteType.hadith, favItem.id);
    }
    if (mounted) setState(() => _isFavorite = next);
  }

  void _copyHadith() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: widget.hadith.toShareText()));
    AppSnackbar.success(context, 'تم نسخ الحديث الشريف بنجاح');
  }

  void _shareHadith() {
    HapticFeedback.lightImpact();
    Share.share(widget.hadith.toShareText());
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Category, Number & Authenticity Grade Badges
          Row(
            children: [
              // Hadith number badge
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: palette.primary,
                  ),
                ),
                child: Text(
                  '#${widget.hadith.number}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: palette.primary,
                    fontFamily: AppTextStyles.cairo,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              // Category tag
              Expanded(
                child: Text(
                  widget.hadith.category,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: palette.textMuted,
                    fontFamily: AppTextStyles.cairo,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Grade badge (صحيح / حسن)
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xxs,
                ),
                decoration: BoxDecoration(
                  color: widget.hadith.isSahih
                      ? palette.goldSoft
                      : palette.primarySoft,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: widget.hadith.isSahih ? palette.gold : palette.primary,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: AppIcon.sm,
                      color: widget.hadith.isSahih ? palette.gold : palette.primary,
                    ),
                    const SizedBox(width: AppSpace.xxs),
                    Text(
                      widget.hadith.grade,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: widget.hadith.isSahih
                            ? palette.gold
                            : palette.primary,
                        fontFamily: AppTextStyles.cairo,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpace.md),

          // Title (authentic shortest saying)
          Text(
            widget.hadith.cleanTitle,
            style: AppTextStyles.titleMedium.copyWith(
              color: palette.text,
              fontFamily: AppTextStyles.cairo,
            ),
          ),

          const SizedBox(height: AppSpace.sm),

          // Matn in classical typography within framed container
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Text(
              '«${widget.hadith.matn}»',
              style: AppTextStyles.bodyLarge.copyWith(
                color: palette.text,
                fontFamily: AppTextStyles.amiri,
                height: 1.85,
              ),
              textScaler: TextScaler.linear(widget.fontScale),
              textAlign: TextAlign.justify,
            ),
          ),

          const SizedBox(height: AppSpace.sm),

          // Source and Narrator citation
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: palette.textSubtle,
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  widget.hadith.source,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: palette.textSubtle,
                    fontFamily: AppTextStyles.cairo,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Expandable explanation / benefits section
          if (widget.hadith.benefits.isNotEmpty) ...[
            if (_isExpanded) ...[
              const SizedBox(height: AppSpace.md),
              Container(
                padding: const EdgeInsetsDirectional.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: palette.primary,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          'الفوائد والدروس المستفادة',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: palette.primary,
                            fontFamily: AppTextStyles.cairo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      widget.hadith.benefits,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: palette.text,
                        fontFamily: AppTextStyles.cairo,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: AppSpace.sm),

          // Bottom Action Bar: Toggle Explanation, Favorite, Share
          Row(
            children: [
              if (widget.hadith.benefits.isNotEmpty)
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isExpanded = !_isExpanded);
                  },
                  borderRadius: AppRadius.smRadius,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: AppSize.tap),
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.sm,
                    ),
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: palette.primary,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          _isExpanded ? 'إخفاء الفوائد' : 'عرض الفوائد',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: palette.primary,
                            fontFamily: AppTextStyles.cairo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              // Copy button
              IconButton(
                onPressed: _copyHadith,
                icon: Icon(
                  Icons.copy_rounded,
                  color: palette.textMuted,
                ),
                tooltip: 'نسخ الحديث',
              ),
              // Share button
              IconButton(
                onPressed: _shareHadith,
                icon: Icon(
                  Icons.share_rounded,
                  color: palette.textMuted,
                ),
                tooltip: 'مشاركة الحديث',
              ),
              // Favorite button
              IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: _isFavorite ? palette.gold : palette.textMuted,
                ),
                tooltip: _isFavorite ? 'محفوظ في المفضلة' : 'حفظ في المفضلة',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
