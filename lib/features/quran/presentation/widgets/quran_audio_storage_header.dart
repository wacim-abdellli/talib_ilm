import 'package:flutter/material.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/services/quran_audio_downloader.dart';
import '../../data/services/quran_audio_service.dart';

class QuranAudioStorageHeader extends StatelessWidget {
  final QuranReciter currentReciter;
  final List<QuranReciter> reciters;
  final ValueChanged<QuranReciter?> onReciterChanged;
  final int totalStorageBytes;
  final int downloadedCount;
  final VoidCallback onConfirmDeleteAll;

  const QuranAudioStorageHeader({
    super.key,
    required this.currentReciter,
    required this.reciters,
    required this.onReciterChanged,
    required this.totalStorageBytes,
    required this.downloadedCount,
    required this.onConfirmDeleteAll,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpace.sm,
        start: AppSpace.lg,
        end: AppSpace.lg,
        bottom: AppSpace.xs,
      ),
      child: AppCard(
        padding: const EdgeInsetsDirectional.all(AppSpace.md),
        color: palette.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: palette.border.withValues(alpha: 0.7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: AppUi.iconBoxSize,
                  height: AppUi.iconBoxSize,
                  decoration: BoxDecoration(
                    color: palette.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.record_voice_over_rounded,
                    color: palette.primary,
                    size: AppIcon.md,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'القارئ الصوتي المختار',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<QuranReciter>(
                          value: currentReciter,
                          isDense: true,
                          isExpanded: true,
                          dropdownColor: palette.surface,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: palette.primary,
                            size: AppIcon.md,
                          ),
                          items: reciters.map((r) {
                            return DropdownMenuItem<QuranReciter>(
                              value: r,
                              child: Text(
                                r.name,
                                style: textTheme.label.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: onReciterChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Divider(
              height: 1,
              thickness: 1,
              color: palette.border.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpace.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.sd_storage_rounded,
                        size: AppIcon.sm,
                        color: palette.gold,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'المساحة المستهلكة: ',
                                style: textTheme.caption.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                              TextSpan(
                                text: QuranAudioDownloader.formatBytes(totalStorageBytes),
                                style: textTheme.label.copyWith(
                                  color: palette.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (downloadedCount > 0)
                                TextSpan(
                                  text: ' ($downloadedCount سورة)',
                                  style: textTheme.caption.copyWith(
                                    color: palette.textMuted,
                                  ),
                                ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (totalStorageBytes > 0)
                  InkWell(
                    onTap: onConfirmDeleteAll,
                    borderRadius: AppRadius.pillRadius,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.xs,
                        vertical: AppSpace.xxs,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_sweep_outlined,
                            size: AppIcon.sm,
                            color: palette.error,
                          ),
                          const SizedBox(width: AppSpace.xxs),
                          Text(
                            'تفريغ الكل',
                            style: textTheme.caption.copyWith(
                              color: palette.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
