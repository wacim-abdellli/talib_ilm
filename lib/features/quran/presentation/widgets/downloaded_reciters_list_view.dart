import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/services/quran_audio_downloader.dart';
import '../../data/services/quran_audio_service.dart';
import 'empty_downloaded_audio_state.dart';
import 'surah_card.dart';

/// Renders all downloaded Quran surahs grouped by reciter with direct playback,
/// per-surah deletion, and per-reciter management.
class DownloadedRecitersListView extends StatelessWidget {
  final Map<QuranReciter, List<DownloadedSurahItem>> downloadedByReciter;
  final VoidCallback onRefresh;
  final VoidCallback? onBrowseAll;
  final Function(DownloadedSurahItem) onPlaySurah;
  final Function(DownloadedSurahItem) onDeleteSurah;
  final Function(QuranReciter) onDeleteReciter;

  const DownloadedRecitersListView({
    super.key,
    required this.downloadedByReciter,
    required this.onRefresh,
    this.onBrowseAll,
    required this.onPlaySurah,
    required this.onDeleteSurah,
    required this.onDeleteReciter,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final audioService = QuranAudioService();

    if (downloadedByReciter.isEmpty) {
      return EmptyDownloadedAudioState(
        onBrowseAll: onBrowseAll ?? () {},
      );
    }

    final entries = downloadedByReciter.entries.toList();

    return ListView.builder(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.lg,
        AppSpace.xxl * 2,
      ),
      itemCount: entries.length,
      itemBuilder: (context, rIdx) {
        final reciter = entries[rIdx].key;
        final surahs = entries[rIdx].value;
        final totalBytes = surahs.fold<int>(0, (sum, s) => sum + s.bytes);

        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: AppSpace.lg),
          child: AppCard(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            color: palette.surface,
            borderRadius: AppRadius.xlRadius,
            border: Border.all(
              color: palette.border.withValues(alpha: 0.7),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Reciter Section Header ──────────────────────────────────
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
                        size: AppIcon.sm,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reciter.name,
                            style: textTheme.label.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${surahs.length} سور • ${QuranAudioDownloader.formatBytes(totalBytes)}',
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: palette.error,
                        size: AppIcon.sm,
                      ),
                      tooltip: 'حذف تلاوات ${reciter.name}',
                      onPressed: () => onDeleteReciter(reciter),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Divider(
                  height: 1,
                  color: palette.border.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSpace.xs),

                // ── Downloaded Surah Tiles ──────────────────────────────────
                ...surahs.map((item) {
                  return AnimatedBuilder(
                    animation: Listenable.merge([
                      audioService.activeSurahNotifier,
                      audioService.isPlayingNotifier,
                    ]),
                    builder: (context, _) {
                      final isCurrentSurah =
                          audioService.activeSurahNotifier.value == item.surah &&
                              audioService.selectedReciter == reciter;
                      final isAudioPlaying =
                          isCurrentSurah && audioService.isPlayingNotifier.value;

                      return Container(
                        margin: const EdgeInsetsDirectional.symmetric(
                          vertical: AppSpace.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: isAudioPlaying
                              ? palette.primarySoft.withValues(alpha: 0.15)
                              : palette.surfaceMuted.withValues(alpha: 0.4),
                          borderRadius: AppRadius.mdRadius,
                          border: Border.all(
                            color: isAudioPlaying
                                ? palette.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: AppRadius.mdRadius,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onPlaySurah(item);
                            },
                            borderRadius: AppRadius.mdRadius,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.sm,
                                vertical: AppSpace.xs,
                              ),
                              child: Row(
                                children: [
                                  SurahNumberMedallion(
                                    number: item.surah,
                                    size: AppIcon.md,
                                  ),
                                  const SizedBox(width: AppSpace.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'سورة ${item.surahName}',
                                          style: textTheme.label.copyWith(
                                            color: isAudioPlaying
                                                ? palette.primary
                                                : palette.text,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${item.verseCount} آية • ${QuranAudioDownloader.formatBytes(item.bytes)}',
                                          style: textTheme.caption.copyWith(
                                            color: palette.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Play/Pause Action
                                  IconButton(
                                    icon: Icon(
                                      isAudioPlaying
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_fill_rounded,
                                      color: palette.primary,
                                      size: AppIcon.md,
                                    ),
                                    tooltip: isAudioPlaying
                                        ? 'إيقاف مؤقت'
                                        : 'تشغيل السورة',
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      onPlaySurah(item);
                                    },
                                  ),
                                  // Delete Action
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: palette.textMuted,
                                      size: AppIcon.sm,
                                    ),
                                    tooltip: 'حذف من الجهاز',
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      onDeleteSurah(item);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
