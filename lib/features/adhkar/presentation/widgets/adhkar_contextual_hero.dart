import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../data/adhkar_models.dart';

class AdhkarContextualHero extends StatelessWidget {
  final AthkarCatalog catalog;
  final void Function(BuildContext context, AthkarCategoryData? category) onOpenCategory;

  const AdhkarContextualHero({
    super.key,
    required this.catalog,
    required this.onOpenCategory,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final now = DateTime.now();
    final hour = now.hour;
    final String recId;
    final String recTitle;
    final String recSubtitle;
    final IconData recIcon;

    if (hour >= 4 && hour < 12) {
      recId = 'morning';
      recTitle = 'أذكار الصباح';
      recSubtitle = 'ابدأ يومك بنور الذكر وبركة الاستفتاح';
      recIcon = Icons.wb_sunny_rounded;
    } else if (hour >= 12 && hour < 20) {
      recId = 'evening';
      recTitle = 'أذكار المساء';
      recSubtitle = 'حصّن يومك ومساءك بذكر الرحمن';
      recIcon = Icons.nights_stay_rounded;
    } else {
      recId = 'sleeping';
      recTitle = 'أذكار النوم';
      recSubtitle = 'اختم يومك بالسكينة والاستغفار';
      recIcon = Icons.bedtime_rounded;
    }

    final cat = catalog.byId(recId) ?? catalog.byId('sleeping');

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.lg,
        AppSpace.xs,
      ),
      child: SizedBox(
        width: double.infinity,
        child: AppCard(
          onTap: () {
            HapticFeedback.lightImpact();
            onOpenCategory(context, cat);
          },
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          child: Row(
            children: [
              IconBadge(
                icon: recIcon,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: palette.primarySoft,
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Text(
                        'أذكار الوقت الحالي',
                        style: context.text.caption.copyWith(
                          color: palette.onPrimarySoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      recTitle,
                      style: context.text.titleSmall.copyWith(
                        color: palette.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      recSubtitle,
                      style: context.text.caption.copyWith(
                        color: palette.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: AppIcon.md,
                color: palette.primary,
              ),
          ],
        ),
      ),
    ),
  );
}
}
