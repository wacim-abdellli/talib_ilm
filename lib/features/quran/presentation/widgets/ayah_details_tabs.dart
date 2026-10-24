import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/services/quran_audio_service.dart';

export 'ayah_tafsir_tab_view.dart';
export 'ayah_words_tab_view.dart';

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

    return ValueListenableBuilder<bool>(
      valueListenable: audioService.isPlayingNotifier,
      builder: (context, isPlaying, _) {
        final activeSurah = audioService.activeSurahNotifier.value;
        final activeAyah = audioService.activeAyahNotifier.value;
        final isThisPlaying = isPlaying &&
            activeSurah == surahNumber &&
            activeAyah == ayahNumber;

        return Container(
          padding: const EdgeInsetsDirectional.all(AppSpace.md),
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: palette.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceRaised,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.record_voice_over_rounded,
                      size: AppIcon.sm,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    DropdownButton<QuranReciter>(
                      value: audioService.selectedReciter,
                      dropdownColor: palette.surfaceRaised,
                      underline: const SizedBox.shrink(),
                      items: QuranAudioService.reciters.map((r) {
                        return DropdownMenuItem<QuranReciter>(
                          value: r,
                          child: Text(
                            r.name,
                            style: textTheme.bodySmall.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          audioService.setSelectedReciter(val);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.sm),

              // Playback Speed Selector
              ValueListenableBuilder<double>(
                valueListenable: audioService.speedNotifier,
                builder: (context, currentSpeed, _) {
                  const speeds = [0.75, 1.0, 1.25, 1.5];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: speeds.map((speed) {
                      final isSelected = (currentSpeed - speed).abs() < 0.01;
                      return Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.xxs,
                        ),
                        child: ChoiceChip(
                          label: Text(
                            '${speed == 1.0 ? "1" : speed}×',
                            style: textTheme.caption.copyWith(
                              color: isSelected ? palette.onPrimary : palette.text,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: palette.primary,
                          backgroundColor: palette.surfaceRaised,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.pillRadius,
                            side: BorderSide(
                              color: isSelected ? palette.primary : palette.border,
                            ),
                          ),
                          onSelected: (val) {
                            if (val) {
                              HapticFeedback.selectionClick();
                              audioService.setPlaybackSpeed(speed);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: AppSpace.md),

              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (isThisPlaying) {
                      audioService.pause();
                    } else {
                      audioService.playVerse(surahNumber, ayahNumber);
                    }
                  },
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: palette.primary,
                      shape: BoxShape.circle,
                      boxShadow: palette.shadow,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isThisPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: AppIcon.lg,
                      color: palette.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xs),

              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  audioService.playContinuous(
                    surah: surahNumber,
                    startAyah: ayahNumber,
                  );
                },
                icon: Icon(
                  Icons.playlist_play_rounded,
                  size: AppIcon.sm,
                  color: palette.primary,
                ),
                label: Text(
                  'تلاوة مستمرة من هذه الآية',
                  style: textTheme.caption.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
