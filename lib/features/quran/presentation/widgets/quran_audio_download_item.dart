import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/services/quran_audio_downloader.dart';
import '../../data/services/quran_audio_service.dart';

/// Item card for a Holy Quran surah in the Audio Downloads screen.
/// Displays download progress, file size, delete action, and offline audio playback.
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
    final audioService = QuranAudioService();

    final estMb = QuranAudioDownloader.estimateSurahSizeMb(
      surah,
      reciter: reciter,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([
        audioService.activeSurahNotifier,
        audioService.isPlayingNotifier,
      ]),
      builder: (context, _) {
        final isCurrentSurah = audioService.activeSurahNotifier.value == surah;
        final isAudioPlaying = isCurrentSurah && audioService.isPlayingNotifier.value;

        return AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          color: palette.surface,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(
            color: isAudioPlaying
                ? palette.primary
                : isDownloaded
                    ? palette.gold.withValues(alpha: 0.35)
                    : palette.border,
            width: isAudioPlaying ? 1.5 : 1.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // Surah Number or Playing Indicator
                  Container(
                    width: AppUi.iconBoxSize,
                    height: AppUi.iconBoxSize,
                    decoration: BoxDecoration(
                      color: isAudioPlaying
                          ? palette.primary
                          : palette.surfaceMuted,
                      borderRadius: AppRadius.smRadius,
                    ),
                    alignment: Alignment.center,
                    child: isAudioPlaying
                        ? Icon(
                            Icons.graphic_eq_rounded,
                            size: AppIcon.sm,
                            color: palette.onPrimary,
                          )
                        : Text(
                            '$surah',
                            style: textTheme.label.copyWith(
                              color: palette.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(width: AppSpace.sm),

                  // Surah Name & Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'سورة $surahName',
                              style: textTheme.titleSmall.copyWith(
                                color: isAudioPlaying
                                    ? palette.primary
                                    : palette.text,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isAudioPlaying) ...[
                              const SizedBox(width: AppSpace.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.xs,
                                  vertical: AppSpace.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.primarySoft,
                                  borderRadius: AppRadius.pillRadius,
                                ),
                                child: Text(
                                  'قيد التشغيل',
                                  style: textTheme.caption.copyWith(
                                    color: palette.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        Text(
                          isDownloaded
                              ? '$verseCount آيات · محملة بجودة عالية'
                              : '$verseCount آيات · تقديري: ~$estMb م.ب',
                          style: textTheme.bodySmall.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Trailing Action Buttons
                  _buildTrailingActions(
                    context: context,
                    palette: palette,
                    textTheme: textTheme,
                    audioService: audioService,
                    isAudioPlaying: isAudioPlaying,
                  ),
                ],
              ),

              // Active Download Progress Bar
              if (progress != null &&
                  (progress!.isDownloading || progress!.isPaused)) ...[
                const SizedBox(height: AppSpace.xs),
                ClipRRect(
                  borderRadius: AppRadius.pillRadius,
                  child: LinearProgressIndicator(
                    value: progress!.progressFraction,
                    backgroundColor: palette.surfaceMuted,
                    color: progress!.isPaused
                        ? palette.gold
                        : palette.primary,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: AppSpace.xxs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      progress!.isPaused
                          ? 'متوقف مؤقتاً'
                          : 'جارٍ التنزيل: ${progress!.downloadedAyahs}/${progress!.totalAyahs} آية',
                      style: textTheme.bodySmall.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    Text(
                      '${(progress!.progressFraction * 100).toInt()}%',
                      style: textTheme.bodySmall.copyWith(
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
                const SizedBox(height: AppSpace.xxs),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: AppIcon.xs,
                      color: palette.error,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        progress!.errorMessage!,
                        style: textTheme.bodySmall.copyWith(
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
      },
    );
  }

  Widget _buildTrailingActions({
    required BuildContext context,
    required AppPalette palette,
    required AppTextTheme textTheme,
    required QuranAudioService audioService,
    required bool isAudioPlaying,
  }) {
    // 1. Surah is currently downloading
    if (progress != null && progress!.isDownloading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.pause_rounded, color: palette.gold),
            tooltip: 'إيقاف مؤقت',
            onPressed: onPauseDownload,
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: palette.error),
            tooltip: 'إلغاء التنزيل',
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
            icon: Icon(Icons.play_arrow_rounded, color: palette.primary),
            tooltip: 'استئناف التنزيل',
            onPressed: onStartDownload,
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: palette.error),
            tooltip: 'إلغاء التنزيل',
            onPressed: onCancelDownload,
          ),
        ],
      );
    }

    // 3. Surah is fully downloaded (OFFLINE PLAYBACK READY)
    if (isDownloaded || progress?.isCompleted == true) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play / Pause Button for instant offline playback
          IconButton(
            icon: Icon(
              isAudioPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              size: AppIcon.lg,
              color: isAudioPlaying ? palette.gold : palette.primary,
            ),
            tooltip: isAudioPlaying ? 'إيقاف مؤقت' : 'تشغيل السورة (بدون إنترنت)',
            onPressed: () {
              HapticFeedback.lightImpact();
              if (isAudioPlaying) {
                audioService.pause();
              } else {
                audioService.playContinuous(
                  surah: surah,
                  startAyah: 1,
                  reciter: reciter,
                );
              }
            },
          ),

          // Downloaded Size Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.sm,
              vertical: AppSpace.xxs,
            ),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(color: palette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: AppIcon.xs,
                  color: palette.primary,
                ),
                const SizedBox(width: AppSpace.xxs),
                Text(
                  QuranAudioDownloader.formatBytes(downloadedBytes),
                  style: textTheme.bodySmall.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Delete Button
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              size: AppIcon.sm,
              color: palette.error,
            ),
            tooltip: 'حذف التلاوة من الجهاز',
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
            icon: Icon(Icons.refresh_rounded, color: palette.primary),
            tooltip: 'إعادة المحاولة',
            onPressed: onStartDownload,
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: palette.textMuted),
            tooltip: 'إلغاء التنزيل',
            onPressed: onCancelDownload,
          ),
        ],
      );
    }

    // 5. Surah is not downloaded yet
    return IconButton(
      icon: Icon(
        Icons.download_rounded,
        size: AppIcon.md,
        color: palette.primary,
      ),
      tooltip: 'تنزيل سورة $surahName للاستماع بدون إنترنت',
      onPressed: onStartDownload,
    );
  }
}
