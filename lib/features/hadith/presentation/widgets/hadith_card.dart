import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/services/hadith_favorites_service.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/models/hadith_models.dart';

class HadithCard extends StatefulWidget {
  final GradedHadith hadith;
  final bool initiallyExpanded;

  const HadithCard({
    super.key,
    required this.hadith,
    this.initiallyExpanded = false,
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
    final fav = await _favService.isSaved(widget.hadith.toLegacyHadith());
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    final next = await _favService.toggleSaved(widget.hadith.toLegacyHadith());
    if (mounted) setState(() => _isFavorite = next);
  }

  void _copyHadith() {
    Clipboard.setData(ClipboardData(text: widget.hadith.toShareText()));
    AppSnackbar.success(context, 'تم نسخ الحديث الشريف بنجاح');
  }

  void _shareHadith() {
    Share.share(widget.hadith.toShareText());
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Category & Grade Badges
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
                  borderRadius: AppRadius.smRadius,
                ),
                child: Text(
                  '#${widget.hadith.number}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: palette.onPrimarySoft,
                    fontFamily: AppTextStyles.cairo,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
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
                  vertical: AppSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: widget.hadith.isSahih
                      ? palette.goldSoft
                      : palette.primarySoft,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Text(
                  widget.hadith.grade,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: widget.hadith.isSahih
                        ? palette.gold
                        : palette.primary,
                    fontFamily: AppTextStyles.cairo,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpace.md),

          // Title (authentic shortest saying, full text with no dots)
          Text(
            widget.hadith.cleanTitle,
            style: AppTextStyles.titleMedium.copyWith(
              color: palette.text,
              fontFamily: AppTextStyles.cairo,
            ),
          ),

          const SizedBox(height: AppSpace.sm),

          // Matn in classical Amiri typography
          Text(
            widget.hadith.matn,
            style: AppTextStyles.bodyLarge.copyWith(
              color: palette.text,
              fontFamily: AppTextStyles.amiri,
              height: 1.8,
            ),
          ),

          const SizedBox(height: AppSpace.md),

          // Source and Narrator citation
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.smRadius,
            ),
            child: Row(
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
                      color: palette.textMuted,
                      fontFamily: AppTextStyles.cairo,
                    ),
                  ),
                ),
              ],
            ),
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
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
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
                  Icons.share_outlined,
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
