import 'package:flutter/material.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/services/quran_audio_downloader.dart';
import '../../data/services/quran_audio_service.dart' show QuranReciter;
import 'surah_card.dart';

/// Item card for a Holy Quran surah in the Audio Downloads screen.
/// Displays authentic Surah medallion, download progress, file size,
/// delete action, and offline audio playback with generous horizontal breathing room.
class QuranAudioDownloadItem extends StatelessWidget {
  final int surah;
  final String surahName;
  final int verseCount;
  final bool isDownloaded;
  final int downloadedBytes;
  final QuranReciter reciter;
  final SurahDownloadProgress? progress;
  final VoidCallback onStartDownload;
  final VoidCallback onPauseDownload;
  final VoidCallback onCancelDownload;
  final VoidCallback onDelete;

  const QuranAudioDownloadItem({
    super.key,
    required this.surah,
    required this.surahName,
    required this.verseCount,
    required this.isDownloaded,
    required this.downloadedBytes,
    required this.reciter,
    required this.progress,
    required this.onStartDownload,
    required this.onPauseDownload,
    required this.onCancelDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final estMb = QuranAudioDownloader.estimateSurahSizeMb(
      surah,
      reciter: reciter,
    );
    final estFormatted = estMb < 0.1 ? '< 0.1' : estMb.toStringAsFixed(1);
    final isReadyOffline = isDownloaded || progress?.isCompleted == true;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      color: palette.surface,
      borderRadius: AppRadius.lgRadius,
      border: Border.all(
        color: isReadyOffline
            ? palette.gold.withValues(alpha: 0.35)
            : palette.border,
        width: 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Authentic Islamic medallion showing Surah number
              SurahNumberMedallion(
                number: surah,
                size: AppIcon.hero,
              ),

              const SizedBox(width: AppSpace.md),

              // Surah Name & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'سورة $surahName',
                            style: textTheme.titleSmall.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                        const SizedBox(height: AppSpace.xs),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Wrap(
                              spacing: AppSpace.xs,
                              runSpacing: AppSpace.xxs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '$verseCount آيات',
                                  style: textTheme.caption.copyWith(
                                    color: palette.textMuted,
                                  ),
                                ),
                                Text(
                                  '•',
                                  style: textTheme.caption.copyWith(
                                    color: palette.textMuted.withValues(alpha: 0.4),
                                  ),
                                ),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isReadyOffline
                                            ? Icons.offline_pin_rounded
                                            : Icons.cloud_download_outlined,
                                        size: AppIcon.sm,
                                        color: isReadyOffline
                                            ? palette.success
                                            : palette.textMuted,
                                      ),
                                      const SizedBox(width: AppSpace.xxs),
                                      Flexible(
                                        child: Text(
                                          isReadyOffline
                                              ? QuranAudioDownloader.formatBytes(downloadedBytes)
                                              : 'تقديري: ~$estFormatted م.ب',
                                          style: textTheme.caption.copyWith(
                                            color: isReadyOffline
                                                ? palette.success
                                                : palette.textMuted,
                                            fontWeight: isReadyOffline
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpace.xs),

                  // Trailing Action Buttons
                  _buildTrailingActions(
                    context: context,
                    palette: palette,
                    textTheme: textTheme,
                    isReadyOffline: isReadyOffline,
                  ),
                ],
              ),

              // Active Download Progress Bar
              if (progress != null &&
                  (progress!.isDownloading || progress!.isPaused)) ...[
                const SizedBox(height: AppSpace.sm),
                ClipRRect(
                  borderRadius: AppRadius.pillRadius,
                  child: LinearProgressIndicator(
                    value: progress!.progressFraction,
                    backgroundColor: palette.progressTrack,
                    color: progress!.isPaused
                        ? palette.gold
                        : palette.primary,
                    minHeight: AppSpace.xs,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        progress!.isPaused
                            ? 'متوقف مؤقتاً'
                            : 'جارٍ التنزيل: ${progress!.downloadedAyahs}/${progress!.totalAyahs} آية',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      '${(progress!.progressFraction * 100).toInt()}%',
                      style: textTheme.caption.copyWith(
                        color: palette.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],

              // Error Notice
              if (progress?.status == SurahDownloadStatus.failed &&
                  progress?.errorMessage != null) ...[
                const SizedBox(height: AppSpace.xs),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: AppIcon.sm,
                      color: palette.error,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        progress!.errorMessage!,
                        style: textTheme.caption.copyWith(
                          color: palette.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
  }

  Widget _buildTrailingActions({
    required BuildContext context,
    required AppPalette palette,
    required AppTextTheme textTheme,
    required bool isReadyOffline,
  }) {
    // 1. Surah is currently downloading
    if (progress != null && progress!.isDownloading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'إيقاف مؤقت للتنزيل',
            constraints: const BoxConstraints.tightFor(
              width: AppSize.tap,
              height: AppSize.tap,
            ),
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.pause_circle_filled_rounded,
              size: AppIcon.lg,
              color: palette.gold,
            ),
            onPressed: onPauseDownload,
          ),
          IconButton(
            tooltip: 'إلغاء التنزيل',
            constraints: const BoxConstraints.tightFor(
              width: AppSize.tap,
              height: AppSize.tap,
            ),
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.close_rounded,
              size: AppIcon.md,
              color: palette.error,
            ),
            onPressed: onCancelDownload,
          ),
        ],
      );
    }

    // 2. Surah download is paused
    if (progress != null && progress!.isPaused) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'استئناف التنزيل',
            constraints: const BoxConstraints.tightFor(
              width: AppSize.tap,
              height: AppSize.tap,
            ),
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.play_circle_fill_rounded,
              size: AppIcon.lg,
              color: palette.primary,
            ),
            onPressed: onStartDownload,
          ),
          IconButton(
            tooltip: 'إلغاء التنزيل',
            constraints: const BoxConstraints.tightFor(
              width: AppSize.tap,
              height: AppSize.tap,
            ),
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.close_rounded,
              size: AppIcon.md,
              color: palette.error,
            ),
            onPressed: onCancelDownload,
          ),
        ],
      );
    }

    // 3. Surah is fully downloaded
    if (isReadyOffline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Downloaded indicator icon
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.xs),
            decoration: BoxDecoration(
              color: palette.goldSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: AppIcon.md,
              color: palette.gold,
            ),
          ),
          const SizedBox(width: AppSpace.xs),

          // Delete Button
          IconButton(
            tooltip: 'حذف التلاوة من الجهاز',
            constraints: const BoxConstraints.tightFor(
              width: AppSize.tap,
              height: AppSize.tap,
            ),
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: AppIcon.md,
              color: palette.textMuted,
            ),
            onPressed: onDelete,
          ),
        ],
      );
    }

    // 4. Surah download failed - allow Retry or Cancel
    if (progress != null && progress!.status == SurahDownloadStatus.failed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'إعادة المحاولة',
            constraints: const BoxConstraints.tightFor(
              width: AppSize.tap,
              height: AppSize.tap,
            ),
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.refresh_rounded,
              size: AppIcon.md,
              color: palette.primary,
            ),
            onPressed: onStartDownload,
          ),
          IconButton(
            tooltip: 'إلغاء التنزيل',
            constraints: const BoxConstraints.tightFor(
              width: AppSize.tap,
              height: AppSize.tap,
            ),
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.close_rounded,
              size: AppIcon.md,
              color: palette.textMuted,
            ),
            onPressed: onCancelDownload,
          ),
        ],
      );
    }

    // 5. Surah is not downloaded yet
    return IconButton(
      tooltip: 'تنزيل سورة $surahName للاستماع بدون إنترنت',
      constraints: const BoxConstraints.tightFor(
        width: AppSize.tap,
        height: AppSize.tap,
      ),
      padding: EdgeInsets.zero,
      onPressed: onStartDownload,
      icon: Container(
        padding: const EdgeInsetsDirectional.all(AppSpace.xs),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          shape: BoxShape.circle,
          border: Border.all(color: palette.border),
        ),
        child: Icon(
          Icons.download_rounded,
          size: AppIcon.md,
          color: palette.primary,
        ),
      ),
    );
  }
}
