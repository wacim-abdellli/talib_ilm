import 'package:flutter/material.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_progress.dart';
import '../../../../shared/widgets/icon_badge.dart';

class CategoryCardData {
  final String id;
  final String title;
  final String? subtitle;
  final int total;
  final IconData icon;
  final Color? tint;
  final bool showProgress;
  final VoidCallback onTap;

  const CategoryCardData({
    required this.id,
    required this.title,
    this.subtitle,
    required this.total,
    required this.icon,
    this.tint,
    required this.onTap,
    this.showProgress = false,
  });
}

class CategoryProgress {
  final int completed;
  final int total;

  const CategoryProgress(this.completed, this.total);
}

class CategoryTile extends StatefulWidget {
  final CategoryCardData data;
  final Future<CategoryProgress> Function()? progressLoader;

  const CategoryTile({
    super.key,
    required this.data,
    this.progressLoader,
  });

  @override
  State<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<CategoryTile> {
  Future<CategoryProgress>? _progressFuture;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void didUpdateWidget(covariant CategoryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.id != widget.data.id ||
        oldWidget.progressLoader != widget.progressLoader) {
      _loadProgress();
    }
  }

  void _loadProgress() {
    if (widget.progressLoader != null) {
      _progressFuture = widget.progressLoader!();
    } else {
      _progressFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final catColors = palette.adhkarCategory(widget.data.id);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return AppCard(
      onTap: widget.data.onTap,
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Background subtle category watermark for visual depth
          PositionedDirectional(
            bottom: -AppSpace.sm,
            end: -AppSpace.sm,
            child: IgnorePointer(
              child: Transform.scale(
                scale: 2.2,
                child: Icon(
                  _getCategoryIcon(widget.data.id),
                  size: AppIcon.hero,
                  color: catColors.fg.withValues(alpha: 0.04),
                ),
              ),
            ),
          ),
          // Main card layout
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon badge and count badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconBadge(
                    icon: _getCategoryIcon(widget.data.id),
                    bg: catColors.bg,
                    fg: catColors.fg,
                    size: AppIcon.hero,
                    iconSize: AppIcon.sm,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: catColors.bg,
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Text(
                        _subtitleLabel(widget.data.id, widget.data.total),
                        style: context.text.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: catColors.fg,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              // Body: Title + Subtitle benefit (eliminates empty vertical void)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.data.title,
                        style: context.text.titleSmall.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.data.subtitle != null &&
                        widget.data.subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xxs),
                      Flexible(
                        child: Text(
                          widget.data.subtitle!.trim(),
                          style: context.text.caption.copyWith(
                            color: palette.textMuted,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              // Footer: Live progress tracker or action row
              _buildBottomSection(context, catColors, palette, isRtl),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(
    BuildContext context,
    CategoryColors catColors,
    AppPalette palette,
    bool isRtl,
  ) {
    if (_progressFuture != null) {
      return FutureBuilder<CategoryProgress>(
        future: _progressFuture,
        builder: (context, snapshot) {
          final progress = snapshot.data;
          if (progress != null && progress.completed > 0) {
            final fraction =
                (progress.completed / progress.total).clamp(0.0, 1.0);
            final percent = (fraction * 100).toInt();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${progress.completed} من ${progress.total}',
                      style: context.text.caption.copyWith(
                        color: catColors.fg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: context.text.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xxs),
                AppProgress(
                  progress: fraction,
                  color: fraction >= 1.0 ? palette.gold : catColors.fg,
                ),
              ],
            );
          }
          return _buildDefaultAction(context, catColors, palette, isRtl);
        },
      );
    }
    return _buildDefaultAction(context, catColors, palette, isRtl);
  }

  Widget _buildDefaultAction(
    BuildContext context,
    CategoryColors catColors,
    AppPalette palette,
    bool isRtl,
  ) {
    return Row(
      children: [
        Flexible(
          child: Text(
            'عرض الأذكار',
            style: context.text.caption.copyWith(
              color: palette.textMuted,
            ),
            maxLines: 1,
          ),
        ),
        const SizedBox(width: AppSpace.xs),
        Transform.flip(
          flipX: isRtl,
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            size: AppIcon.xs,
            color: catColors.fg,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String id) {
    switch (id) {
      case 'morning':
        return Icons.wb_sunny_rounded;
      case 'evening':
        return Icons.nights_stay_rounded;
      case 'after_prayer':
        return Icons.mosque_rounded;
      case 'prayer_sunan':
        return Icons.access_time_filled_rounded;
      case 'waking':
        return Icons.wb_twilight_rounded;
      case 'sleeping':
        return Icons.bedtime_rounded;
      case 'distress':
        return Icons.shield_rounded;
      case 'mosque_adhan':
        return Icons.notifications_active_rounded;
      case 'home':
        return Icons.cottage_rounded;
      case 'wudu_food':
      case 'wudu_taharah':
        return Icons.clean_hands_rounded;
      case 'food_drink':
        return Icons.restaurant_rounded;
      case 'travel':
        return Icons.explore_rounded;
      case 'sickness_funerals':
        return Icons.healing_rounded;
      case 'nature_weather':
        return Icons.cloud_queue_rounded;
      case 'social_manners':
        return Icons.diversity_3_rounded;
      case 'fasting_hajj':
        return Icons.brightness_medium_rounded;
      case 'duas':
        return Icons.menu_book_rounded;
      case 'tasbeeh':
        return Icons.fingerprint_rounded;
      case 'istighfar':
        return Icons.restart_alt_rounded;
      default:
        return Icons.auto_stories_rounded;
    }
  }

  String _subtitleLabel(String id, int total) {
    if (id == 'tasbeeh') return 'تسبيح';
    if (id == 'istighfar') return 'استغفار';
    if (id == 'duas') return '$total دعاء';
    return '$total ذكراً';
  }
}
