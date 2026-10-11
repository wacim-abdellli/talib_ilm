import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/services/quran_audio_service.dart';
import 'mushaf_settings_sheet.dart';
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
        color: palette.surfaceRaised.withValues(alpha: 0.94),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: 2,
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
                      'الجزء $juzNum • الصفحة $currentPage',
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
            color: palette.surfaceRaised.withValues(alpha: 0.95),
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
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: palette.primarySoft.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.graphic_eq_rounded,
            color: palette.primary,
            size: AppIcon.sm,
          ),
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
              Text(
                audioService.selectedReciter.name,
                style: textTheme.caption.copyWith(
                  color: palette.textMuted,
                ),
                maxLines: 1,
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
          '٦٠٤',
          style: textTheme.caption.copyWith(
            color: palette.textMuted,
          ),
        ),
      ],
    );
  }
}
