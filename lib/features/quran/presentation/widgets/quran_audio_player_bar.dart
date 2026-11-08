import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_ui.dart';
import '../../data/services/quran_audio_service.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import 'hifdh_repeat_options_sheet.dart';
import 'surah_card.dart';

/// Floating/sticky audio playback bar displayed at the bottom of the
/// Holy Quran Audio Downloads screen, providing full-surah scrubbing,
/// time progress, play/pause, seek +/- 10s, next/prev surah, repeat mode,
/// sleep timer, and playback speed controls.
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
        audioService.isLoadingNotifier,
        audioService.selectedReciterNotifier,
        audioService.isFullSurahModeNotifier,
        audioService.speedNotifier,
        audioService.repeatModeNotifier,
        audioService.sleepTimerMinutesNotifier,
        audioService.sleepTimerRemainingSecondsNotifier,
        audioService.stopAtEndOfSurahNotifier,
      ]),
      builder: (context, _) {
        final surah = audioService.activeSurahNotifier.value;
        if (surah == null) return const SizedBox.shrink();

        final isPlaying = audioService.isPlayingNotifier.value;
        final isLoading = audioService.isLoadingNotifier.value;
        final isFullSurah = audioService.isFullSurahModeNotifier.value;
        final surahName = quran.getSurahNameArabic(surah);
        final reciter = audioService.selectedReciter;
        final currentAyah = audioService.activeAyahNotifier.value ?? 1;
        final totalAyahs = quran.getVerseCount(surah);

        final repeatMode = audioService.repeatModeNotifier.value;
        final isRepeatActive = repeatMode != AudioRepeatMode.none;
        final IconData repeatIcon = switch (repeatMode) {
          AudioRepeatMode.repeatOnce => Icons.repeat_one_rounded,
          AudioRepeatMode.infinite => Icons.repeat_rounded,
          AudioRepeatMode.none => Icons.repeat_rounded,
        };
        final String repeatTooltip = switch (repeatMode) {
          AudioRepeatMode.repeatOnce => 'تكرار السورة: مرة واحدة',
          AudioRepeatMode.infinite => 'تكرار السورة: مستمر',
          AudioRepeatMode.none => 'تكرار: معطل',
        };

        final sleepMinutes = audioService.sleepTimerMinutesNotifier.value;
        final remainingSeconds = audioService.sleepTimerRemainingSecondsNotifier.value;
        final stopAtEnd = audioService.stopAtEndOfSurahNotifier.value;
        final isTimerActive = sleepMinutes != null || stopAtEnd;
        String? countdownLabel;
        if (remainingSeconds != null && remainingSeconds > 0) {
          final rMin = remainingSeconds ~/ 60;
          final rSec = remainingSeconds % 60;
          countdownLabel = '${rMin.toString().padLeft(2, '0')}:${rSec.toString().padLeft(2, '0')}';
        }
        final String timerTooltip = isTimerActive
            ? (stopAtEnd
                ? 'مؤقت النوم: نهاية السورة'
                : 'مؤقت النوم: ${countdownLabel ?? "$sleepMinutes دقيقة"}')
            : 'مؤقت النوم';

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
                  // ── Top Title Row: Surah info + Sleep Timer + Close Button ─
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
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                'سورة $surahName',
                                style: textTheme.titleSmall.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                isFullSurah || reciter.isSurahBased
                                    ? 'تلاوة كاملة • ${reciter.name}'
                                    : 'الآية $currentAyah من $totalAyahs • ${reciter.name}',
                                style: textTheme.caption.copyWith(
                                  color: palette.textMuted,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Sleep Timer Popup Button
                      PopupMenuButton<int>(
                        tooltip: timerTooltip,
                        initialValue: stopAtEnd ? -1 : (sleepMinutes ?? 0),
                        onSelected: (val) {
                          HapticFeedback.selectionClick();
                          if (val == 0) {
                            audioService.setSleepTimer(null);
                            AppSnackbar.info(context, 'تم إيقاف مؤقت النوم');
                          } else if (val == -1) {
                            audioService.setSleepTimer(null, atEndOfSurah: true);
                            AppSnackbar.success(context, 'سيتم إيقاف التلاوة عند نهاية السورة');
                          } else {
                            audioService.setSleepTimer(val);
                            AppSnackbar.success(context, 'تم ضبط مؤقت النوم على $val دقيقة');
                          }
                        },
                        itemBuilder: (ctx) {
                          final currentVal = stopAtEnd ? -1 : (sleepMinutes ?? 0);
                          PopupMenuItem<int> buildItem(int val, String label) {
                            final isSelected = currentVal == val;
                            return PopupMenuItem<int>(
                              value: val,
                              child: Row(
                                children: [
                                  if (isSelected)
                                    Icon(
                                      Icons.check_rounded,
                                      size: AppIcon.xs,
                                      color: palette.primary,
                                    )
                                  else
                                    const SizedBox(width: AppIcon.xs),
                                  const SizedBox(width: AppSpace.xs),
                                  Text(
                                    label,
                                    style: isSelected
                                        ? textTheme.captionBold.copyWith(color: palette.primary)
                                        : textTheme.caption.copyWith(color: palette.text),
                                  ),
                                ],
                              ),
                            );
                          }

                          return [
                            buildItem(0, 'إيقاف المؤقت (معطل)'),
                            buildItem(5, '5 دقائق'),
                            buildItem(10, '10 دقائق'),
                            buildItem(15, '15 دقيقة'),
                            buildItem(30, '30 دقيقة'),
                            buildItem(45, '45 دقيقة'),
                            buildItem(60, '60 دقيقة'),
                            buildItem(-1, 'نهاية السورة الحالية'),
                          ];
                        },
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.xs,
                            vertical: AppSpace.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: isTimerActive ? palette.primarySoft : palette.surfaceMuted,
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(
                              color: isTimerActive ? palette.primary : palette.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isTimerActive ? Icons.bedtime_rounded : Icons.bedtime_outlined,
                                size: AppIcon.xs,
                                color: isTimerActive ? palette.primary : palette.textMuted,
                              ),
                              if (isTimerActive) ...[
                                const SizedBox(width: AppSpace.xxs),
                                Text(
                                  stopAtEnd ? 'نهاية السورة' : (countdownLabel ?? '$sleepMinutes د'),
                                  style: textTheme.captionBold.copyWith(
                                    color: palette.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
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

                  const SizedBox(height: AppSpace.xs),

                  // ── Auxiliary Options Row: Repeat Mode & Speed ────────────
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.xs,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Repeat Mode & Advanced Hifdh Loop Controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Repeat Mode Button
                            IconButton(
                              tooltip: repeatTooltip,
                              icon: Container(
                                padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                                decoration: BoxDecoration(
                                  color: isRepeatActive
                                      ? palette.primarySoft
                                      : palette.surfaceMuted,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isRepeatActive
                                        ? palette.primary
                                        : palette.border,
                                  ),
                                ),
                                child: Icon(
                                  repeatIcon,
                                  color: isRepeatActive
                                      ? palette.primary
                                      : palette.textMuted,
                                ),
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                audioService.cycleRepeatMode();
                              },
                            ),

                            // Advanced Hifdh Repetition & Range Loop
                            ValueListenableBuilder<HifdhRangeConfig?>(
                              valueListenable: audioService.hifdhRangeNotifier,
                              builder: (context, hifdhRange, _) {
                                final isRangeActive = hifdhRange != null;
                                return IconButton(
                                  tooltip: 'تكرار الحفظ وتحديد النطاق',
                                  icon: Container(
                                    padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                                    decoration: BoxDecoration(
                                      color: isRangeActive
                                          ? palette.goldSoft
                                          : palette.surfaceMuted,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isRangeActive
                                            ? palette.gold
                                            : palette.border,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.tune_rounded,
                                      color: isRangeActive
                                          ? palette.gold
                                          : palette.textMuted,
                                    ),
                                  ),
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    HifdhRepeatOptionsSheet.show(
                                      context,
                                      audioService: audioService,
                                      surahNumber: surah,
                                      currentAyah: currentAyah,
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),

                        // Speed Selector Pill
                        PopupMenuButton<double>(
                          tooltip: 'سرعة القراءة',
                          initialValue: audioService.speedNotifier.value,
                          onSelected: (s) {
                            HapticFeedback.selectionClick();
                            audioService.setPlaybackSpeed(s);
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                                value: 0.75, child: Text('0.75x')),
                            const PopupMenuItem(
                                value: 1.0, child: Text('1.0x (عادي)')),
                            const PopupMenuItem(
                                value: 1.25, child: Text('1.25x')),
                            const PopupMenuItem(
                                value: 1.5, child: Text('1.5x')),
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
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpace.xs),

                  // ── Transport Controls Row (RTL Flow: <+10> || <-10>) ─────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Previous Surah Button (Right in RTL)
                      IconButton(
                        tooltip: 'السورة السابقة',
                        icon: Icon(
                          Icons.skip_next_rounded,
                          color: surah > 1 ? palette.text : palette.textMuted,
                        ),
                        onPressed: surah > 1
                            ? () {
                                HapticFeedback.lightImpact();
                                audioService.previousSurah();
                              }
                            : null,
                      ),

                      // Rewind 10 Seconds (Right of Play: points right against RTL timeline)
                      IconButton(
                        tooltip: 'تراجع 10 ثوانٍ',
                        icon: Icon(
                          Icons.forward_10_rounded,
                          color: palette.text,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          audioService.seekRelativeSeconds(-10);
                        },
                      ),

                      // Play / Pause Primary Button (Center)
                      IconButton(
                        tooltip: isLoading
                            ? 'جارٍ تحميل التلاوة'
                            : isPlaying
                                ? 'إيقاف مؤقت'
                                : 'تشغيل',
                        onPressed: isLoading ? null : () {
                          HapticFeedback.lightImpact();
                          if (isPlaying) {
                            audioService.pause();
                          } else {
                            audioService.resume();
                          }
                        },
                        icon: Container(
                          padding:
                              const EdgeInsetsDirectional.all(AppSpace.xs),
                          decoration: BoxDecoration(
                            color: palette.primary,
                            shape: BoxShape.circle,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: AppIcon.sm,
                                  height: AppIcon.sm,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: palette.onPrimary,
                                  ),
                                )
                              : Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: palette.onPrimary,
                                ),
                        ),
                      ),

                      // Forward 10 Seconds (Left of Play: points left with RTL timeline)
                      IconButton(
                        tooltip: 'تقديم 10 ثوانٍ',
                        icon: Icon(
                          Icons.replay_10_rounded,
                          color: palette.text,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          audioService.seekRelativeSeconds(10);
                        },
                      ),

                      // Next Surah Button (Far Left in RTL)
                      IconButton(
                        tooltip: 'السورة التالية',
                        icon: Icon(
                          Icons.skip_previous_rounded,
                          color:
                              surah < 114 ? palette.text : palette.textMuted,
                        ),
                        onPressed: surah < 114
                            ? () {
                                HapticFeedback.lightImpact();
                                audioService.nextSurah();
                              }
                            : null,
                      ),
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
