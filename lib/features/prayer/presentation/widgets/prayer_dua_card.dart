import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_snackbar.dart';

/// Prophetic Dua upon hearing the Adhan with its virtuous reward (Sahih Bukhari).
class PrayerDuaCard extends StatelessWidget {
  const PrayerDuaCard({super.key});

  static const String duaText =
      'اللَّهُمَّ رَبَّ هَذِهِ الدَّعْوَةِ التَّامَّةِ، وَالصَّلَاةِ الْقَائِمَةِ، آتِ مُحَمَّدًا الْوَسِيلَةَ وَالْفَضِيلَةَ، وَابْعَثْهُ مَقَامًا مَحْمُودًا الَّذِي وَعَدْتَهُ';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.border),
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_stories_rounded,
                    size: AppIcon.sm,
                    color: palette.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الدعاء عند سماع الأذان وبعده',
                      style: context.text.titleSmall.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'سنة مأثورة مستجابة',
                      style: context.text.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'نسخ الدعاء',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: AppRadius.pillRadius,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Clipboard.setData(const ClipboardData(text: duaText));
                      AppSnackbar.info(context, 'تم نسخ الدعاء المبارك');
                    },
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.md,
                        vertical: AppSpace.xs,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: AppIcon.sm,
                            color: palette.primary,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            'نسخ',
                            style: context.text.caption.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: palette.border),
            ),
            child: Text(
              duaText,
              style: context.text.body.copyWith(
                color: palette.text,
                height: 1.8,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            '«حَلَّتْ لَهُ شَفَاعَتِي يَوْمَ الْقِيَامَةِ» — صحيح البخاري',
            style: context.text.caption.copyWith(
              color: palette.gold,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
