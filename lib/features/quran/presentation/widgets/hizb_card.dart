import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/models/hizb_catalog.dart';
import 'surah_card.dart';

/// Authentic Hizb Card displaying the Hizb index and its 4 Rub el Hizb quarters.
class HizbCard extends StatelessWidget {
  final HizbItem hizb;
  final ValueChanged<int> onOpenPage;

  const HizbCard({
    super.key,
    required this.hizb,
    required this.onOpenPage,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
      child: AppCard(
        onTap: () {
          HapticFeedback.lightImpact();
          onOpenPage(hizb.startPage);
        },
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ornate Hizb Medallion
                SurahNumberMedallion(number: hizb.hizbNumber),
                const SizedBox(width: AppSpace.lg),

                // Hizb Header information
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            hizb.nameArabic,
                            style: textTheme.titleSmall.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
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
                              'صفحة ${hizb.startPage}',
                              style: textTheme.caption.copyWith(
                                color: palette.onGold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'الجزء ${hizb.juzNumber}',
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xs),

                      // Opening snippet
                      Text(
                        '«${hizb.firstVerseSnippet}»',
                        style: textTheme.sacred.copyWith(
                          color: palette.gold,
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpace.xs),

                      Text(
                        'سورة ${hizb.surahNameArabic} • آية ${hizb.startAyah}',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpace.sm),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: palette.gold,
                ),
              ],
            ),

            // ── 4 Quarters Chips (أرباع الحزب) ───────────────────────────
            const SizedBox(height: AppSpace.sm),
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.xs),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: hizb.quarters.map((quarter) {
                  String shortQuarterLabel;
                  if (quarter.quarterInHizb == 1) {
                    shortQuarterLabel = 'البداية (ص ${quarter.page})';
                  } else if (quarter.quarterInHizb == 2) {
                    shortQuarterLabel = 'الربع (ص ${quarter.page})';
                  } else if (quarter.quarterInHizb == 3) {
                    shortQuarterLabel = 'النصف (ص ${quarter.page})';
                  } else {
                    shortQuarterLabel = '٣/٤ (ص ${quarter.page})';
                  }

                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onOpenPage(quarter.page);
                      },
                      borderRadius: AppRadius.smRadius,
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          vertical: AppSpace.xs,
                          horizontal: 2,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          shortQuarterLabel,
                          style: textTheme.caption.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
