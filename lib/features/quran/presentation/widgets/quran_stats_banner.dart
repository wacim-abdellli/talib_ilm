import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/services/bookmark_service.dart';

class QuranLastReadBanner extends StatelessWidget {
  final LastRead lastRead;
  final VoidCallback onTap;

  const QuranLastReadBanner({
    super.key,
    required this.lastRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final surahName = quran.getSurahNameArabic(lastRead.surah);

    return AppCard(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      border: Border.all(
        color: palette.gold.withValues(alpha: 0.35),
        width: 1.2,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.goldSoft,
              border: Border.all(
                color: palette.gold.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: palette.gold,
              size: AppIcon.md,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.xs,
                      ),
                      decoration: BoxDecoration(
                        color: palette.goldSoft,
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Text(
                        'آخر قراءة',
                        style: textTheme.caption.copyWith(
                          color: palette.onPrimarySoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      'صفحة ${lastRead.page} • آية ${lastRead.ayah}',
                      style: textTheme.caption.copyWith(
                        color: palette.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'سورة $surahName',
                  style: textTheme.sacred.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.xs,
            ),
            decoration: BoxDecoration(
              color: palette.goldSoft,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(
                color: palette.gold.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تابع القراءة',
                  style: textTheme.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.gold,
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Icon(
                  Icons.chevron_left_rounded,
                  size: AppIcon.md,
                  color: palette.gold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuranStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const QuranStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.xs),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(icon, color: iconColor, size: AppIcon.sm),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            value,
            style: textTheme.titleSmall.copyWith(
              color: palette.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: textTheme.caption.copyWith(
              color: palette.textMuted,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              subtitle!,
              style: textTheme.caption.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
