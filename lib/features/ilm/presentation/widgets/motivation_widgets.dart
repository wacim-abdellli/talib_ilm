import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/models/favorite_item.dart';
import '../../../../core/services/favorites_service.dart';
import '../../data/services/motivation_service.dart';

import '../../../../app/theme/theme_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';

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

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    // Muted accent colors for quote types
    Color accentColor;
    String typeLabel;
    IconData typeIcon;

    switch (widget.quote.type) {
      case QuoteType.quran:
        accentColor = const Color(0xFF85A885); // Muted sage
        typeLabel = 'قرآن كريم';
        typeIcon = Icons.menu_book;
        break;
      case QuoteType.hadith:
        accentColor = const Color(0xFF7A9CB5); // Muted blue
        typeLabel = 'حديث نبوي';
        typeIcon = Icons.format_quote;
        break;
      case QuoteType.scholar:
        accentColor = const Color(0xFF6A9A9A); // Muted teal
        typeLabel = 'قول مأثور';
        typeIcon = Icons.lightbulb_outline;
        break;
    }

    return Container(
      padding: EdgeInsets.all(responsive.wp(4.5)),
      decoration: BoxDecoration(
        color: context.surfaceSecondaryColor, // Tinted ivory / Dark Elevated
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.borderColor, // Subtle border
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Action Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Action icons on left (LTR perspective)
              Row(
                children: [
                  IconButton(
                    onPressed: _toggleFavorite,
                    icon: Icon(
                      _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      size: 20,
                      color: _isFavorite
                          ? accentColor
                          : accentColor.withValues(alpha: 0.6),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              '${widget.quote.text}\n\n${widget.quote.source}',
                        ),
                      );
                      AppSnackbar.success(context, 'تم النسخ');
                    },
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 20,
                      color: accentColor.withValues(alpha: 0.6),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (widget.onReload != null) ...[
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: widget.onReload,
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 22,
                        color: accentColor,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
              // Title on right
              Row(
                children: [
                  Icon(typeIcon, size: responsive.sp(14), color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: responsive.sp(12),
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: responsive.hp(1.5)),

          // Quote text (selectable + larger)
          SelectableText(
            widget.quote.text,
            style: TextStyle(
              fontSize: responsive.sp(17),
              height: 1.8,
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),

          SizedBox(height: responsive.hp(1)),

          // Source (lighter)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '— ${widget.quote.source}',
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondaryColor, // TextSecondary
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
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
    final responsive = Responsive(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: responsive.wp(85)),
        padding: EdgeInsets.all(responsive.wp(6)),
        decoration: BoxDecoration(
          color: context.surfaceElevatedColor,
          gradient: context.isDark
              ? null
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFDF7), Color(0xFFFFF9E6)],
                ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: context.goldColor.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: context.goldColor.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: responsive.wp(20),
              height: responsive.wp(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.goldColor.withValues(alpha: 0.2),
                    context.goldColor.withValues(alpha: 0.15),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.goldColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  milestone.icon,
                  style: TextStyle(fontSize: responsive.sp(40)),
                ),
              ),
            ),

            SizedBox(height: responsive.hp(2)),

            // Title
            Text(
              milestone.title,
              style: TextStyle(
                fontSize: responsive.sp(20),
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: responsive.hp(1)),

            // Message
            Text(
              milestone.message,
              style: TextStyle(
                fontSize: responsive.sp(14),
                height: 1.6,
                color: context.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),

            // Verse or Hadith
            if (milestone.verse != null || milestone.hadith != null) ...[
              SizedBox(height: responsive.hp(2)),
              Container(
                padding: EdgeInsets.all(responsive.wp(4)),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      milestone.verse ?? milestone.hadith ?? '',
                      style: TextStyle(
                        fontSize: responsive.sp(13),
                        height: 1.7,
                        color: context.primaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: responsive.hp(0.8)),
                    Text(
                      milestone.verseRef ?? milestone.hadithRef ?? '',
                      style: TextStyle(
                        fontSize: responsive.sp(11),
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: responsive.hp(2.5)),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: responsive.hp(1.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'الحمد لله',
                  style: TextStyle(
                    fontSize: responsive.sp(15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
    final responsive = Responsive(context);

    Color backgroundColor;
    Color textColor;

    switch (encouragement.tone) {
      case EncouragementTone.gentle:
        backgroundColor = context.isDark
            ? context.goldColor.withValues(alpha: 0.15)
            : const Color(0xFFFFF9E6);
        textColor = context.isDark
            ? context.goldColor
            : const Color(0xFF8B6914);
        break;
      case EncouragementTone.warm:
        backgroundColor = context.isDark
            ? context.successColor.withValues(alpha: 0.15)
            : const Color(0xFFF0FDF4);
        textColor = context.isDark
            ? context.successColor
            : const Color(0xFF166534);
        break;
      case EncouragementTone.encouraging:
        backgroundColor = context.isDark
            ? context.primaryColor.withValues(alpha: 0.15)
            : const Color(0xFFEFF6FF);
        textColor = context.isDark
            ? context.primaryColor
            : const Color(0xFF1E40AF);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.wp(4),
        vertical: responsive.hp(1.2),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(
            encouragement.icon,
            style: TextStyle(fontSize: responsive.sp(18)),
          ),
          SizedBox(width: responsive.wp(3)),
          Expanded(
            child: Text(
              encouragement.message,
              style: TextStyle(
                fontSize: responsive.sp(13),
                color: textColor,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(
                Icons.close,
                size: responsive.sp(16),
                color: textColor.withValues(alpha: 0.6),
              ),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
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
    final responsive = Responsive(context);

    return Container(
      padding: EdgeInsets.all(responsive.wp(4)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(responsive.wp(2.5)),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: responsive.sp(20), color: color),
          ),
          SizedBox(width: responsive.wp(3)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight,
                  style: TextStyle(
                    fontSize: responsive.sp(14),
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: responsive.sp(12),
                    color: context.textSecondaryColor,
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
    final responsive = Responsive(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.wp(3),
        vertical: responsive.hp(0.8),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor.withValues(alpha: 0.15),
            context.primaryColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: responsive.sp(14),
            color: context.primaryColor,
          ),
          SizedBox(width: 6),
          Text(
            message,
            style: TextStyle(
              fontSize: responsive.sp(12),
              color: context.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
