import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/quran_tafsir_service.dart';

class AyahTafsirTabView extends StatelessWidget {
  final TafsirScholar selectedScholar;
  final String tafsirText;
  final bool loadingTafsir;
  final ValueChanged<TafsirScholar> onScholarChanged;

  const AyahTafsirTabView({
    super.key,
    required this.selectedScholar,
    required this.tafsirText,
    required this.loadingTafsir,
    required this.onScholarChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: TafsirScholar.values.map((scholar) {
              final isSelected = selectedScholar == scholar;
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
                child: ChoiceChip(
                  label: Text(
                    QuranTafsirService.getScholarName(scholar),
                    style: textTheme.caption.copyWith(
                      color: isSelected ? palette.onPrimary : palette.text,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: palette.primary,
                  backgroundColor: palette.surfaceMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.pillRadius,
                    side: BorderSide(
                      color: isSelected ? palette.primary : palette.border,
                    ),
                  ),
                  onSelected: (val) {
                    if (val) {
                      HapticFeedback.selectionClick();
                      onScholarChanged(scholar);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Expanded(
          child: loadingTafsir
              ? const Column(
                  children: [
                    AppSkeleton(width: double.infinity, height: 20),
                    SizedBox(height: AppSpace.sm),
                    AppSkeleton(width: double.infinity, height: 20),
                    SizedBox(height: AppSpace.sm),
                    AppSkeleton(width: 200, height: 20),
                  ],
                )
              : Container(
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: palette.border),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      tafsirText,
                      style: textTheme.body.copyWith(
                        color: palette.text,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class AyahWordsTabView extends StatelessWidget {
  final int surahNumber;
  final int ayahNumber;

  const AyahWordsTabView({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return FutureBuilder<List<WordMeaning>>(
      future: QuranTafsirService.fetchWordMeanings(surahNumber, ayahNumber),
      initialData: QuranTafsirService.getWordMeanings(surahNumber, ayahNumber),
      builder: (context, snapshot) {
        final words = snapshot.data ?? const [];

        return Container(
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: palette.border),
          ),
          child: ListView.separated(
            padding: const EdgeInsetsDirectional.all(AppSpace.sm),
            itemCount: words.length,
            separatorBuilder: (_, index) => Divider(
              height: 1,
              color: palette.border.withValues(alpha: 0.5),
            ),
            itemBuilder: (context, index) {
              final item = words[index];
              final hasTranslit = item.transliteration != null &&
                  item.transliteration!.isNotEmpty;

              return Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: AppSpace.xs,
                  horizontal: AppSpace.sm,
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.word,
                          style: textTheme.sacred.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hasTranslit)
                          Text(
                            item.transliteration!,
                            style: textTheme.caption.copyWith(
                              color: palette.gold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        item.meaning,
                        textAlign: TextAlign.end,
                        style: textTheme.caption.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(height: AppSpace.sm),

              Center(
                child: FloatingActionButton(
                  heroTag: 'ayah_audio_tab_fab_extracted',
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  elevation: 0,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    if (isThisPlaying) {
                      audioService.pause();
                    } else {
                      audioService.playVerse(surahNumber, ayahNumber);
                    }
                  },
                  child: Icon(
                    isThisPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: AppIcon.lg,
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
                icon: Icon(Icons.playlist_play_rounded, size: AppIcon.sm, color: palette.primary),
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
          Expanded(
            child: TextField(
              controller: noteController,
              maxLines: 5,
              style: textTheme.body.copyWith(color: palette.text),
              decoration: InputDecoration(
                hintText: 'أضف تدبرك أو خواطرك حول هذه الآية الكريمة...',
                hintStyle: textTheme.bodySmall.copyWith(color: palette.textMuted),
                border: InputBorder.none,
              ),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'حفظ التدبر',
                icon: Icons.check_rounded,
                onPressed: onSaveNote,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
