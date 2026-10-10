import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../core/models/favorite_item.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_tag.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../data/services/motivation_service.dart';

/// Displays daily motivational quote from Quran/Hadith
class DailyMotivationCard extends StatefulWidget {
  final DailyQuote quote;
  final VoidCallback? onReload;

  const DailyMotivationCard({super.key, required this.quote, this.onReload});

  @override
  State<DailyMotivationCard> createState() => _DailyMotivationCardState();
}

class _DailyMotivationCardState extends State<DailyMotivationCard> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;
  double _dragStartX = 0;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  @override
  void didUpdateWidget(DailyMotivationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quote != widget.quote) {
      _isFavorite = false;
      _checkFavorite();
    }
  }

  Future<void> _checkFavorite() async {
    final type = _getFavoriteType();
    final id = _getId();
    final isFav = await _favoritesService.isFavorite(type, id);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  String _getId() => widget.quote.text.hashCode.toString();

  FavoriteType _getFavoriteType() {
    switch (widget.quote.type) {
      case QuoteType.quran:
        return FavoriteType.quran;
      case QuoteType.hadith:
        return FavoriteType.hadith;
      case QuoteType.scholar:
        return FavoriteType.quote;
    }
  }

  Future<void> _toggleFavorite() async {
    final type = _getFavoriteType();
    final item = FavoriteItem(
      type: type,
      id: _getId(),
      title: widget.quote.text,
      subtitle: widget.quote.source,
    );

    HapticFeedback.mediumImpact();
    final isFav = await _favoritesService.toggle(item);
    if (mounted) {
      setState(() => _isFavorite = isFav);
      if (_isFavorite) {
        AppSnackbar.success(context, 'تم الحفظ في المفضلة');
      } else {
        AppSnackbar.info(context, 'تمت الإزالة من المفضلة');
      }
    }
  }

  void _copyQuote() {
    Clipboard.setData(
      ClipboardData(text: '${widget.quote.text}\n\n— ${widget.quote.source}'),
    );
    HapticFeedback.lightImpact();
    AppSnackbar.success(context, 'تم نسخ الاقتباس');
  }

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    String typeLabel;

    switch (widget.quote.type) {
      case QuoteType.quran:
        typeColor = context.palette.primary;
        typeLabel = 'آية قرآنية';
        break;
      case QuoteType.hadith:
        typeColor = context.palette.gold;
        typeLabel = 'حديث نبوي';
        break;
      case QuoteType.scholar:
        typeColor = context.palette.textMuted;
        typeLabel = 'حكمة';
        break;
    }

    return Container(
      margin: const EdgeInsetsDirectional.symmetric(
        horizontal: 0,
        vertical: AppSpace.xs,
      ),
      child: Listener(
        onPointerDown: (event) {
          _dragStartX = event.position.dx;
        },
        onPointerUp: (event) {
          if (widget.onReload == null) return;
          final deltaX = event.position.dx - _dragStartX;
          if (deltaX.abs() > 40) {
            HapticFeedback.lightImpact();
            widget.onReload!();
          }
        },
        child: AnimatedSwitcher(
          duration: AppMotion.base,
          transitionBuilder: (child, animation) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: AppMotion.easeIn),
            );
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: offsetAnimation,
                child: child,
              ),
            );
          },
          child: AppCard(
            key: ValueKey(widget.quote.text),
            color: context.palette.surfaceRaised,
            border: Border.all(
              color: typeColor.withValues(alpha: 0.28),
              width: 1.2,
            ),
            padding: EdgeInsets.zero,
            child: Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.lg),
              decoration: BoxDecoration(
                borderRadius: AppRadius.lgRadius,
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    typeColor.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header: Type Tag & Top Actions (Refresh, Copy, Bookmark)
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpace.xs,
                    runSpacing: AppSpace.xs,
                    children: [
                      AppTag(
                        label: typeLabel,
                        fg: typeColor,
                        bg: typeColor.withValues(alpha: 0.14),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onReload != null)
                            AppIconButton(
                              icon: Icons.refresh_rounded,
                              tooltip: 'اقتباس آخر',
                              iconSize: AppIcon.md,
                              color: context.palette.textMuted,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                widget.onReload!();
                              },
                            ),
                          AppIconButton(
                            icon: _isFavorite
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            tooltip: 'حفظ',
                            iconSize: AppIcon.md,
                            color: _isFavorite
                                ? context.palette.gold
                                : context.palette.textSubtle,
                            onPressed: _toggleFavorite,
                          ),
                          AppIconButton(
                            icon: Icons.copy_rounded,
                            tooltip: 'نسخ',
                            iconSize: AppIcon.md,
                            color: context.palette.textSubtle,
                            onPressed: _copyQuote,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpace.md),

                  // Sacred Text
                  SelectableText(
                    widget.quote.text,
                    style: context.text.sacred.copyWith(
                      color: context.palette.text,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.right,
                  ),

                  const SizedBox(height: AppSpace.md),

                  // Source Footer
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: typeColor,
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          widget.quote.source,
                          style: context.text.caption.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows milestone achievement celebration dialog
class MilestoneCelebrationDialog extends StatelessWidget {
  final MilestoneTrigger milestone;

  const MilestoneCelebrationDialog({super.key, required this.milestone});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.xxl),
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: palette.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: palette.goldSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.gold,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  milestone.icon,
                  style: context.text.display,
                ),
              ),
            ),

            const SizedBox(height: AppSpace.lg),

            // Title
            Text(
              milestone.title,
              style: context.text.title,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpace.sm),

            // Message
            Text(
              milestone.message,
              style: context.text.body.copyWith(
                color: palette.textMuted,
              ),
              textAlign: TextAlign.center,
            ),

            // Verse or Hadith
            if (milestone.verse != null || milestone.hadith != null) ...[
              const SizedBox(height: AppSpace.lg),
              Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: palette.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      milestone.verse ?? milestone.hadith ?? '',
                      style: context.text.sacred.copyWith(
                        color: palette.onPrimarySoft,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      milestone.verseRef ?? milestone.hadithRef ?? '',
                      style: context.text.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpace.xl),

            AppButton(
              label: 'الحمد لله',
              onPressed: () => Navigator.of(context).pop(),
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, MilestoneTrigger milestone) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => MilestoneCelebrationDialog(milestone: milestone),
    );
  }
}

/// Small encouragement banner (for gentle reminders)
class EncouragementBanner extends StatelessWidget {
  final Encouragement encouragement;
  final VoidCallback? onDismiss;

  const EncouragementBanner({
    super.key,
    required this.encouragement,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Color backgroundColor;
    Color textColor;

    switch (encouragement.tone) {
      case EncouragementTone.gentle:
        backgroundColor = palette.goldSoft;
        textColor = palette.gold;
        break;
      case EncouragementTone.warm:
        backgroundColor = palette.primarySoft;
        textColor = palette.onPrimarySoft;
        break;
      case EncouragementTone.encouraging:
        backgroundColor = palette.primarySoft;
        textColor = palette.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(
            encouragement.icon,
            style: context.text.titleSmall,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              encouragement.message,
              style: context.text.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onDismiss != null)
            AppIconButton(
              icon: Icons.close,
              tooltip: 'إغلاق',
              iconSize: AppIcon.sm,
              color: textColor,
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}

/// Progress insight card (non-competitive analytics)
class ProgressInsightCard extends StatelessWidget {
  final String insight;
  final String detail;
  final IconData icon;
  final Color color;

  const ProgressInsightCard({
    super.key,
    required this.insight,
    required this.detail,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          IconBadge(icon: icon),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  insight,
                  style: context.text.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  detail,
                  style: context.text.caption.copyWith(
                    color: context.palette.textMuted,
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

/// Contextual progress message (shown in book view)
class ContextualProgressMessage extends StatelessWidget {
  final String message;

  const ContextualProgressMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AppTag(
      label: message,
    );
  }
}
