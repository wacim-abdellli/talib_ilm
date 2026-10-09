import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final hour = now.hour;
    final String recId;
    final String recTitle;
    final String recSubtitle;
    final IconData recIcon;
    final Color recColor;

    if (hour >= 4 && hour < 12) {
      recId = 'morning';
      recTitle = 'أذكار الصباح';
      recSubtitle = 'ابدأ يومك بنور الذكر وبركة الاستفتاح';
      recIcon = Icons.wb_sunny_rounded;
      recColor = context.goldColor;
    } else if (hour >= 12 && hour < 20) {
      recId = 'evening';
      recTitle = 'أذكار المساء';
      recSubtitle = 'حصّن يومك ومساءك بذكر الرحمن';
      recIcon = Icons.nights_stay_rounded;
      recColor = context.primaryColor;
    } else {
      recId = 'sleeping';
      recTitle = 'أذكار النوم';
      recSubtitle = 'اختم يومك بالسكينة والاستغفار';
      recIcon = Icons.bedtime_rounded;
      recColor = AppColors.categoryLanguage;
    }

    final cat = catalog.byId(recId) ?? catalog.byId('sleeping');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onOpenCategory(context, cat);
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      recColor.withValues(alpha: 0.22),
                      context.surfaceContainer,
                    ]
                  : [
                      recColor.withValues(alpha: 0.12),
                      Colors.white,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: recColor.withValues(alpha: isDark ? 0.35 : 0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: recColor.withValues(alpha: 0.16),
                  border: Border.all(
                    color: recColor.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Icon(recIcon, color: recColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: recColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'أذكار الوقت الحالي',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: recColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      recTitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      recSubtitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: recColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: recColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ابدأ الآن',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: recColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 11,
                      color: recColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
