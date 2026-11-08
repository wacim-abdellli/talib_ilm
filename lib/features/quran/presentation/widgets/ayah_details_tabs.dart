import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/quran_reader_preferences.dart';

export 'ayah_tafsir_tab_view.dart';
export 'ayah_words_tab_view.dart';
export 'ayah_similar_tab_view.dart';
export 'ayah_waqf_tab_view.dart';

class AyahAudioTabView extends StatelessWidget {
  final int surahNumber;
  final int ayahNumber;
  final QuranAudioService audioService;

  const AyahAudioTabView({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.audioService,
  });

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
        audioService.speedNotifier,
        audioService.repeatModeNotifier,
        audioService.errorNotifier,
        audioService.isFullSurahModeNotifier,
      ]),
      builder: (context, _) {
        final activeSurah = audioService.activeSurahNotifier.value;
        final activeAyah = audioService.activeAyahNotifier.value;
        final hasActivePlayback = activeSurah != null && activeAyah != null;
        final isPlaying = audioService.isPlayingNotifier.value;
        final isLoading = audioService.isLoadingNotifier.value;
        final selectedReciter = audioService.selectedReciter;
        // This is the ayah player, so keep its selector limited to reciters
        // with per-ayah audio. Surah-only files always start at ayah 1.
        final verseReciters = QuranAudioService.reciters
            .where((item) => !item.isSurahBased)
            .toList(growable: false);
        final reciter = selectedReciter.isSurahBased
            ? verseReciters.first
            : selectedReciter;
        final repeatMode = audioService.repeatModeNotifier.value;
        final error = audioService.errorNotifier.value;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
          child: Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.graphic_eq_rounded,
                      size: AppIcon.md,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مشغل التلاوة',
                            style: textTheme.titleSmall.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'سورة ${quran.getSurahNameArabic(surahNumber)} • الآية $ayahNumber',
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Container(
                  constraints: const BoxConstraints(minHeight: AppSize.tap),
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceRaised,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.record_voice_over_rounded,
                        size: AppIcon.md,
                        color: palette.primary,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: DropdownButton<QuranReciter>(
                          value: reciter,
                          isExpanded: true,
                          dropdownColor: palette.surfaceRaised,
                          underline: const SizedBox.shrink(),
                          iconEnabledColor: palette.primary,
                          items: verseReciters.map((item) {
                            return DropdownMenuItem<QuranReciter>(
                              value: item,
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmallBold.copyWith(
                                  color: palette.text,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: isLoading
                              ? null
                              : (value) async {
                                  if (value == null) return;
                                  HapticFeedback.selectionClick();
                                  await audioService.switchReciter(value);
                                  await QuranReaderPreferences.saveReciter(
                                    audioService.selectedReciter,
                                  );
                                },
                        ),
                      ),
                    ],
                  ),
                ),
                if (reciter.isSurahBased) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'هذا القارئ يوفر تسجيل السورة كاملة ويبدأ من أولها.',
                    style: textTheme.caption.copyWith(color: palette.textMuted),
                  ),
                ],
                if (hasActivePlayback) ...[
                  const SizedBox(height: AppSpace.sm),
                  _NowPlayingCard(
                    surah: activeSurah,
                    ayah: activeAyah,
                    reciterName: reciter.name,
                    isPlaying: isPlaying,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  _QuranAudioProgress(audioService: audioService),
                ],
                if (error != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  Container(
                    padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                    decoration: BoxDecoration(
                      color: palette.errorSoft,
                      borderRadius: AppRadius.smRadius,
                    ),
                    child: Text(
                      error.message,
                      style: textTheme.bodySmall.copyWith(color: palette.error),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.sm),
                Text(
                  'سرعة التلاوة',
                  style: textTheme.label.copyWith(color: palette.textMuted),
                ),
                const SizedBox(height: AppSpace.xs),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  children: [0.75, 1.0, 1.25, 1.5].map((speed) {
                    final selected =
                        (audioService.speedNotifier.value - speed).abs() < 0.01;
                    return ChoiceChip(
                      label: Text(
                        '${speed == 1.0 ? "1" : speed}×',
                        style: textTheme.label.copyWith(
                          color: selected ? palette.onPrimary : palette.text,
                        ),
                      ),
                      selected: selected,
                      selectedColor: palette.primary,
                      backgroundColor: palette.surfaceRaised,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.pillRadius,
                        side: BorderSide(
                          color: selected ? palette.primary : palette.border,
                        ),
                      ),
                      onSelected: isLoading
                          ? null
                          : (value) {
                              if (!value) return;
                              HapticFeedback.selectionClick();
                              audioService.setPlaybackSpeed(speed);
                            },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpace.sm),
                _buildTransportControls(
                  context: context,
                  hasActivePlayback: hasActivePlayback,
                  isPlaying: isPlaying,
                  isLoading: isLoading,
                  isFullSurah: audioService.isFullSurahModeNotifier.value,
                  reciter: reciter,
                  repeatMode: repeatMode,
                ),
                const SizedBox(height: AppSpace.sm),
                AppButton.tonal(
                  label: reciter.isSurahBased
                      ? 'تشغيل السورة كاملة'
                      : 'متابعة التلاوة من هذه الآية',
                  icon: Icons.playlist_play_rounded,
                  onPressed: isLoading
                      ? null
                      : () async {
                          HapticFeedback.selectionClick();
                          await audioService.playContinuous(
                            surah: surahNumber,
                            startAyah: ayahNumber,
                            reciter: reciter,
                          );
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransportControls({
    required BuildContext context,
    required bool hasActivePlayback,
    required bool isPlaying,
    required bool isLoading,
    required bool isFullSurah,
    required QuranReciter reciter,
    required AudioRepeatMode repeatMode,
  }) {
    final palette = context.palette;
    final previousTooltip = isFullSurah || reciter.isSurahBased
        ? 'السورة السابقة'
        : 'الآية السابقة';
    final nextTooltip = isFullSurah || reciter.isSurahBased
        ? 'السورة التالية'
        : 'الآية التالية';
    final repeatIcon = switch (repeatMode) {
      AudioRepeatMode.none => Icons.repeat_rounded,
      AudioRepeatMode.repeatOnce => Icons.repeat_one_rounded,
      AudioRepeatMode.infinite => Icons.all_inclusive_rounded,
    };
    final repeatLabel = switch (repeatMode) {
      AudioRepeatMode.none => 'التكرار معطل',
      AudioRepeatMode.repeatOnce =>
        isFullSurah || reciter.isSurahBased
            ? 'تكرار السورة مرة واحدة'
            : 'تكرار الآية مرة واحدة',
      AudioRepeatMode.infinite =>
        isFullSurah || reciter.isSurahBased
            ? 'تكرار السورة باستمرار'
            : 'تكرار مستمر',
    };

    return Row(
      children: [
        AppIconButton(
          icon: isFullSurah || reciter.isSurahBased
              ? Icons.skip_next_rounded
              : Icons.skip_next_rounded,
          tooltip: previousTooltip,
          onPressed: !hasActivePlayback || isLoading
              ? null
              : () async {
                  if (isFullSurah || reciter.isSurahBased) {
                    await audioService.previousSurah();
                  } else {
                    await audioService.previousAyah();
                  }
                },
        ),
        Expanded(
          child: AppButton(
            label: isLoading
                ? 'جارٍ تحميل التلاوة'
                : hasActivePlayback
                ? (isPlaying ? 'إيقاف مؤقت' : 'استئناف التلاوة')
                : reciter.isSurahBased
                ? 'تشغيل السورة'
                : 'تشغيل الآية',
            icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            isLoading: isLoading,
            onPressed: isLoading
                ? null
                : () async {
                    HapticFeedback.mediumImpact();
                    if (hasActivePlayback) {
                      if (isPlaying) {
                        await audioService.pause();
                      } else {
                        await audioService.resume();
                      }
                    } else if (reciter.isSurahBased) {
                      await audioService.playFullSurah(
                        surah: surahNumber,
                        reciter: reciter,
                      );
                    } else {
                      await audioService.playVerse(
                        surahNumber,
                        ayahNumber,
                        reciter: reciter,
                        singleVerse: true,
                      );
                    }
                  },
          ),
        ),
        AppIconButton(
          icon: Icons.skip_previous_rounded,
          tooltip: nextTooltip,
          onPressed: !hasActivePlayback || isLoading
              ? null
              : () async {
                  if (isFullSurah || reciter.isSurahBased) {
                    await audioService.nextSurah();
                  } else {
                    await audioService.nextAyah();
                  }
                },
        ),
        AppIconButton(
          icon: repeatIcon,
          tooltip: repeatLabel,
          color: repeatMode == AudioRepeatMode.none
              ? palette.textMuted
              : palette.primary,
          onPressed: isLoading ? null : audioService.cycleRepeatMode,
        ),
      ],
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  final int surah;
  final int ayah;
  final String reciterName;
  final bool isPlaying;
  final bool isLoading;

  const _NowPlayingCard({
    required this.surah,
    required this.ayah,
    required this.reciterName,
    required this.isPlaying,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpace.sm),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(
            isLoading
                ? Icons.hourglass_top_rounded
                : isPlaying
                ? Icons.graphic_eq_rounded
                : Icons.pause_circle_outline_rounded,
            size: AppIcon.md,
            color: palette.primary,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isLoading
                      ? 'جارٍ تجهيز التلاوة'
                      : isPlaying
                      ? 'يُتلى الآن'
                      : 'متوقف مؤقتًا'} • سورة ${quran.getSurahNameArabic(surah)} • الآية $ayah',
                  style: textTheme.bodySmallBold.copyWith(color: palette.text),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  reciterName,
                  style: textTheme.caption.copyWith(color: palette.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuranAudioProgress extends StatelessWidget {
  final QuranAudioService audioService;

  const _QuranAudioProgress({required this.audioService});

  static String _format(Duration value) =>
      '${value.inMinutes.toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    return StreamBuilder<Duration?>(
      stream: audioService.durationStream,
      initialData: audioService.duration,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        final maxMs = duration.inMilliseconds.toDouble();
        return StreamBuilder<Duration>(
          stream: audioService.positionStream,
          initialData: audioService.position,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final value = maxMs <= 0
                ? 0.0
                : position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();
            return Column(
              children: [
                Slider(
                  value: value,
                  max: maxMs > 0 ? maxMs : 1,
                  activeColor: palette.primary,
                  onChanged: maxMs <= 0
                      ? null
                      : (milliseconds) =>
                            audioService.seekMilliseconds(milliseconds.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _format(position),
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    Text(
                      _format(duration),
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class AyahNotesTabView extends StatelessWidget {
  final TextEditingController noteController;
  final VoidCallback onSaveNote;
  final ValueChanged<String> onChanged;

  const AyahNotesTabView({
    super.key,
    required this.noteController,
    required this.onSaveNote,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: AppIcon.sm,
                color: palette.gold,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                'تدبر شخصي وخواطر إيمانية',
                style: textTheme.caption.copyWith(
                  color: palette.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Expanded(
            child: Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: palette.surfaceRaised,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: palette.border.withValues(alpha: 0.6),
                ),
              ),
              child: TextField(
                controller: noteController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: textTheme.body.copyWith(
                  color: palette.text,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب تدبرك أو ما ألهمتك به هذه الآية الكريمة...',
                  hintStyle: textTheme.bodySmall.copyWith(
                    color: palette.textMuted,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsetsDirectional.zero,
                ),
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppButton(
              label: 'حفظ التدبر',
              icon: Icons.check_rounded,
              onPressed: onSaveNote,
            ),
          ),
        ],
      ),
    );
  }
}
