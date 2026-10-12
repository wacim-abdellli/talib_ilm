import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/utils/arabic_digits.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/services/quran_audio_service.dart';
import 'quick_jump_sheet.dart';

class MushafReaderTopBar extends StatelessWidget {
  final int currentSurah;
  final int currentPage;
  final int currentAyah;
  final QuranReadingMode readingMode;
  final ValueChanged<int> onJumpToPage;
  final ValueChanged<QuranReadingMode> onModeChanged;
  final VoidCallback onOpenSettings;

  const MushafReaderTopBar({
    super.key,
    required this.currentSurah,
    required this.currentPage,
    required this.currentAyah,
    required this.readingMode,
    required this.onJumpToPage,
    required this.onModeChanged,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final surahName = quran.getSurahNameArabic(currentSurah);
    final juzNum = quran.getJuzNumber(currentSurah, currentAyah);

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        border: Border(bottom: BorderSide(color: palette.border)),
        boxShadow: palette.shadow,
      ),
      child: Row(
        children: [
          // Back button
          AppIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'رجوع',
            color: palette.text,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: AppSpace.xs),

          // Surah & Page Title
          Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                QuickJumpSheet.show(context, onJumpToPage: onJumpToPage);
              },
              borderRadius: AppRadius.smRadius,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: AppSpace.xxs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'سورة $surahName',
                          style: textTheme.titleSmall.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: palette.gold,
                          size: AppIcon.sm,
                        ),
                      ],
                    ),
                    Text(
                      '${getArabicJuzName(juzNum)} • الصفحة $currentPage',
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Reading Mode Segmented Switch
          Container(
            padding: AppSpace.insetXs,
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(color: palette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeTabButton(
                  title: 'مصحف',
                  isSelected: readingMode == QuranReadingMode.mushafPage,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onModeChanged(QuranReadingMode.mushafPage);
                  },
                  palette: palette,
                  textTheme: textTheme,
                ),
                _buildModeTabButton(
                  title: 'قائمة',
                  isSelected: readingMode == QuranReadingMode.ayahList,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onModeChanged(QuranReadingMode.ayahList);
                  },
                  palette: palette,
                  textTheme: textTheme,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpace.xs),

          // Quick Jump Button
          AppIconButton(
            icon: Icons.explore_rounded,
            tooltip: 'انتقال سريع',
            color: palette.gold,
            onPressed: () {
              HapticFeedback.lightImpact();
              QuickJumpSheet.show(context, onJumpToPage: onJumpToPage);
            },
          ),

          // Settings Button
          AppIconButton(
            icon: Icons.tune_rounded,
            tooltip: 'الإعدادات',
            color: palette.text,
            onPressed: onOpenSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required AppPalette palette,
    required AppTextTheme textTheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pillRadius,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? palette.primary : Colors.transparent,
          borderRadius: AppRadius.pillRadius,
        ),
        child: Text(
          title,
          style: textTheme.caption.copyWith(
            color: isSelected ? palette.onPrimary : palette.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class MushafReaderBottomBar extends StatelessWidget {
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final QuranAudioService audioService;

  const MushafReaderBottomBar({
    super.key,
    required this.currentPage,
    required this.onPageChanged,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return ValueListenableBuilder<bool>(
      valueListenable: audioService.isPlayingNotifier,
      builder: (context, isPlaying, _) {
        final activeAyah = audioService.activeAyahNotifier.value;
        final activeSurah = audioService.activeSurahNotifier.value;
        final hasActiveAudio = activeAyah != null && activeSurah != null;

        return Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            border: Border(top: BorderSide(color: palette.border)),
            boxShadow: palette.shadow,
          ),
          child: hasActiveAudio
              ? _buildMiniAudioPlayer(palette, textTheme, isPlaying, activeSurah, activeAyah)
              : _buildPageScrubber(palette, textTheme),
        );
      },
    );
  }

  Widget _buildMiniAudioPlayer(
    AppPalette palette,
    AppTextTheme textTheme,
    bool isPlaying,
    int surah,
    int ayah,
  ) {
    final playingSurahName = quran.getSurahNameArabic(surah);

    return Row(
      children: [
        ValueListenableBuilder<AudioRepeatMode>(
          valueListenable: audioService.repeatModeNotifier,
          builder: (context, repeatMode, _) {
            final IconData icon = switch (repeatMode) {
              AudioRepeatMode.none => Icons.repeat_rounded,
              AudioRepeatMode.singleAyah => Icons.repeat_one_rounded,
              AudioRepeatMode.surah => Icons.all_inclusive_rounded,
            };
            final bool active = repeatMode != AudioRepeatMode.none;
            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                final next = switch (repeatMode) {
                  AudioRepeatMode.none => AudioRepeatMode.singleAyah,
                  AudioRepeatMode.singleAyah => AudioRepeatMode.surah,
                  AudioRepeatMode.surah => AudioRepeatMode.none,
                };
                audioService.setRepeatMode(next);
              },
              borderRadius: AppRadius.pillRadius,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: active ? palette.primarySoft : palette.surfaceMuted,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? palette.primary : palette.border,
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  icon,
                  color: active ? palette.primary : palette.textMuted,
                  size: AppIcon.sm,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'سورة $playingSurahName - آية $ayah',
                style: textTheme.bodySmall.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      audioService.selectedReciter.name,
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  ValueListenableBuilder<double>(
                    valueListenable: audioService.speedNotifier,
                    builder: (context, speed, _) {
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          const speeds = [0.75, 1.0, 1.25, 1.5];
                          final idx = (speeds.indexOf(speed) + 1) % speeds.length;
                          audioService.setPlaybackSpeed(speeds[idx]);
                        },
                        borderRadius: AppRadius.pillRadius,
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.xs,
                            vertical: AppSpace.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceMuted,
                            borderRadius: AppRadius.pillRadius,
                            border: Border.all(color: palette.border, width: 0.8),
                          ),
                          child: Text(
                            '${speed == 1.0 ? "1" : speed}×',
                            style: textTheme.caption.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        AppIconButton(
          icon: Icons.skip_previous_rounded,
          tooltip: 'الآية السابقة',
          color: palette.text,
          onPressed: audioService.previousAyah,
        ),
        FloatingActionButton.small(
          heroTag: 'mini_player_play_pause_overlay',
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          elevation: 0,
          onPressed: () {
            if (isPlaying) {
              audioService.pause();
            } else {
              audioService.resume();
            }
          },
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: AppIcon.sm,
          ),
        ),
        AppIconButton(
          icon: Icons.skip_next_rounded,
          tooltip: 'الآية التالية',
          color: palette.text,
          onPressed: audioService.nextAyah,
        ),
        AppIconButton(
          icon: Icons.close_rounded,
          tooltip: 'إيقاف',
          color: palette.textMuted,
          onPressed: audioService.stop,
        ),
      ],
    );
  }

  Widget _buildPageScrubber(AppPalette palette, AppTextTheme textTheme) {
    return Row(
      children: [
        Text(
          'صفحة $currentPage',
          style: textTheme.caption.copyWith(
            color: palette.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Slider.adaptive(
            value: currentPage.toDouble(),
            min: 1.0,
            max: 604.0,
            activeColor: palette.gold,
            inactiveColor: palette.border,
            onChanged: (val) {
              onPageChanged(val.round());
            },
          ),
        ),
        Text(
          '604',
          style: textTheme.caption.copyWith(
            color: palette.textMuted,
          ),
        ),
      ],
    );
  }
}
