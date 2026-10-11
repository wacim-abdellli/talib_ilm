import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/icon_badge.dart';

class CategoryCardData {
  final String id;
  final String title;
  final int total;
  final IconData icon;
  final Color? tint;
  final bool showProgress;
  final VoidCallback onTap;

  const CategoryCardData({
    required this.id,
    required this.title,
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

class CategoryTile extends StatelessWidget {
  final CategoryCardData data;
  final Future<CategoryProgress> Function()? progressLoader;

  const CategoryTile({
    super.key,
    required this.data,
    this.progressLoader,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final catColors = palette.adhkarCategory(data.id);

    return AppCard(
      onTap: () {
        HapticFeedback.lightImpact();
        data.onTap();
      },
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconBadge(
                icon: _getCategoryIcon(data.id),
                bg: catColors.bg,
                fg: catColors.fg,
              ),
              const SizedBox(width: AppSpace.xs),
              Flexible(
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: catColors.bg,
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: Text(
                    _subtitleLabel(data.id, data.total),
                    style: context.text.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: catColors.fg,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            data.title,
            style: context.text.titleSmall.copyWith(
              color: palette.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpace.xs),
          Row(
            children: [
              Flexible(
                child: Text(
                  'عرض الأذكار',
                  style: context.text.caption.copyWith(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: AppIcon.sm,
                color: catColors.fg,
              ),
            ],
          ),
        ],
      ),
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
      case 'waking':
        return Icons.wb_twilight_rounded;
      case 'distress':
        return Icons.shield_rounded;
      case 'mosque_adhan':
        return Icons.notifications_active_rounded;
      case 'home':
        return Icons.cottage_rounded;
      case 'wudu_food':
        return Icons.water_drop_rounded;
      case 'travel':
        return Icons.explore_rounded;
      case 'duas':
        return Icons.menu_book_rounded;
      case 'tasbeeh':
        return Icons.fingerprint_rounded;
      case 'istighfar':
        return Icons.restart_alt_rounded;
      case 'sleeping':
        return Icons.bedtime_rounded;
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
