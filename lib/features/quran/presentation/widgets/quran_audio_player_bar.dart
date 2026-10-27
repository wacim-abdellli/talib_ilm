import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_ui.dart';
import '../../data/services/quran_audio_service.dart';
import 'surah_card.dart';

/// Floating/sticky audio playback bar displayed at the bottom of the
/// Holy Quran Audio Downloads screen, providing full-surah scrubbing,
/// time progress, play/pause, seek +/- 10s, and playback speed controls.
class QuranAudioPlayerBar extends StatelessWidget {
  final QuranAudioService audioService;
  final VoidCallback onClose;

  const QuranAudioPlayerBar({
    super.key,
    required this.audioService,
    required this.onClose,
  });

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AnimatedBuilder(
      animation: Listenable.merge([
        audioService.activeSurahNotifier,
        audioService.activeAyahNotifier,
        audioService.isPlayingNotifier,
        audioService.isFullSurahModeNotifier,
        audioService.speedNotifier,
      ]),
      builder: (context, _) {
        final surah = audioService.activeSurahNotifier.value;
        if (surah == null) return const SizedBox.shrink();

        final isPlaying = audioService.isPlayingNotifier.value;
        final isFullSurah = audioService.isFullSurahModeNotifier.value;
        final surahName = quran.getSurahNameArabic(surah);
        final reciter = audioService.selectedReciter;
        final currentAyah = audioService.activeAyahNotifier.value ?? 1;
        final totalAyahs = quran.getVerseCount(surah);

        return Container(
          margin: const EdgeInsetsDirectional.all(AppSpace.sm),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AppRadius.xlRadius,
            border: Border.all(
              color: palette.border,
            ),
            boxShadow: palette.shadow,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: AppRadius.xlRadius,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpace.md,
                AppSpace.sm,
                AppSpace.md,
                AppSpace.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Top Title Row: Surah info + Close Button ──────────────
                  Row(
                    children: [
                      SurahNumberMedallion(
                        number: surah,
                        size: AppIcon.md,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'سورة $surahName',
                              style: textTheme.titleSmall.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isFullSurah || reciter.isSurahBased
                                  ? 'تلاوة كاملة • ${reciter.name}'
                                  : 'الآية $currentAyah من $totalAyahs • ${reciter.name}',
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Stop / Close Button (min 48dp tap target)
                      IconButton(
                        tooltip: 'إغلاق المشغل',
                        icon: Icon(
                          Icons.close_rounded,
                          color: palette.textMuted,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          audioService.stop();
                          onClose();
                        },
                      ),
                    ],
                  ),

                  // ── Time Scrubber & Position Stream ───────────────────────
                  StreamBuilder<Duration>(
                    stream: audioService.positionStream,
                    builder: (context, posSnapshot) {
                      final position = posSnapshot.data ?? Duration.zero;
                      return StreamBuilder<Duration?>(
                        stream: audioService.durationStream,
                        builder: (context, durSnapshot) {
                          final duration = durSnapshot.data ?? Duration.zero;
                          final maxMs = duration.inMilliseconds > 0
                              ? duration.inMilliseconds.toDouble()
                              : 1.0;
                          final curMs = position.inMilliseconds
                              .toDouble()
                              .clamp(0.0, maxMs);

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: palette.primary,
                                  inactiveTrackColor: palette.border,
                                  thumbColor: palette.primary,
                                  overlayColor: palette.primarySoft,
                                  trackHeight: 3.0,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6.0,
                                  ),
                                ),
                                child: Slider(
                                  value: curMs,
                                  max: maxMs,
                                  onChanged: (val) {
                                    audioService.seekMilliseconds(val.toInt());
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpace.xs,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: textTheme.caption.copyWith(
                                        color: palette.textMuted,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: textTheme.caption.copyWith(
                                        color: palette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  // ── Controls Row: Rewind 10s, Play/Pause, Forward 10s, Speed ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Speed Toggle Button
                      PopupMenuButton<double>(
                        tooltip: 'سرعة القراءة',
                        initialValue: audioService.speedNotifier.value,
                        onSelected: (s) {
                          HapticFeedback.selectionClick();
                          audioService.setPlaybackSpeed(s);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 0.75, child: Text('0.75x')),
                          const PopupMenuItem(value: 1.0, child: Text('1.0x (عادي)')),
                          const PopupMenuItem(value: 1.25, child: Text('1.25x')),
                          const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                        ],
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.sm,
                            vertical: AppSpace.xs,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceMuted,
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(color: palette.border),
                          ),
                          child: Text(
                            '${audioService.speedNotifier.value}x',
                            style: textTheme.caption.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Rewind 10 Seconds
                      IconButton(
                        tooltip: 'تراجع 10 ثوانٍ',
                        icon: Icon(
                          Icons.replay_10_rounded,
                          color: palette.text,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          audioService.seekRelativeSeconds(-10);
                        },
                      ),

                      const SizedBox(width: AppSpace.xs),

                      // Play / Pause Primary Button
                      IconButton(
                        tooltip: isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (isPlaying) {
                            audioService.pause();
                          } else {
                            audioService.resume();
                          }
                        },
                        icon: Container(
                          padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                          decoration: BoxDecoration(
                            color: palette.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: palette.onPrimary,
                          ),
                        ),
                      ),

                      const SizedBox(width: AppSpace.xs),

                      // Forward 10 Seconds
                      IconButton(
                        tooltip: 'تقديم 10 ثوانٍ',
                        icon: Icon(
                          Icons.forward_10_rounded,
                          color: palette.text,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          audioService.seekRelativeSeconds(10);
                        },
                      ),

                      const Spacer(),
                      const SizedBox(width: AppSpace.xl),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
