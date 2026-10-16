import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../data/models/hizb_catalog.dart';
import 'surah_card.dart';

/// Minimalist Hizb Tile displaying the Hizb index and its 4 Rub el Hizb quarters.
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

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: palette.border.withValues(alpha: 0.45),
              width: 0.6,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onOpenPage(hizb.startPage);
              },
              borderRadius: AppRadius.smRadius,
              child: Row(
                children: [
                  // Clean medallion
                  SurahNumberMedallion(number: hizb.hizbNumber),
                  const SizedBox(width: AppSpace.md),

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
                                vertical: AppSpace.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: palette.goldSoft,
                                borderRadius: AppRadius.pillRadius,
                                border: Border.all(
                                  color: palette.gold.withValues(alpha: 0.25),
                                  width: 0.7,
                                ),
                              ),
                              child: Text(
                                'ص ${hizb.startPage}',
                                style: textTheme.caption.copyWith(
                                  color: palette.gold,
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
                        const SizedBox(height: AppSpace.xxs + 1),
                        Text(
                          '«${hizb.firstVerseSnippet}»',
                          style: context.text.sacred.copyWith(
                            color: palette.gold,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpace.xxs),
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

                  const SizedBox(width: AppSpace.xs),
                  Icon(
                    Icons.chevron_left_rounded,
                    size: AppIcon.md,
                    color: palette.textMuted,
                  ),
                ],
              ),
            ),

            // 4 Quarters Chips (أرباع الحزب)
            const SizedBox(height: AppSpace.sm),
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.xxs),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.pillRadius,
                border: Border.all(color: palette.border.withValues(alpha: 0.6)),
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
                      borderRadius: AppRadius.pillRadius,
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          vertical: AppSpace.xxs,
                          horizontal: AppSpace.xxs,
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
