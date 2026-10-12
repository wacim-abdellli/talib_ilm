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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: AppIcon.sm,
                              color: palette.gold,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Text(
                              QuranTafsirService.getScholarName(selectedScholar),
                              style: textTheme.caption.copyWith(
                                color: palette.gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Divider(height: 1, color: palette.border.withValues(alpha: 0.5)),
                        const SizedBox(height: AppSpace.xs),
                        SelectableText(
                          tafsirText,
                          style: textTheme.body.copyWith(
                            color: palette.text,
                            height: 1.75,
                          ),
                        ),
                      ],
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

        if (words.isEmpty) {
          return Center(
            child: Text(
              'لا تتوفر معاني الكلمات حالياً',
              style: textTheme.caption.copyWith(color: palette.textMuted),
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: words.length,
          itemBuilder: (context, index) {
            final item = words[index];
            final hasTranslit = item.transliteration != null &&
                item.transliteration!.isNotEmpty;

            return Container(
              margin: const EdgeInsetsDirectional.only(bottom: AppSpace.xs),
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpace.sm,
                horizontal: AppSpace.md,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(
                  color: palette.border.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.word,
                          style: textTheme.sacred.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        if (hasTranslit) ...[
                          const SizedBox(height: AppSpace.xxs),
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.xs,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: palette.goldSoft,
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: Text(
                              item.transliteration!,
                              style: textTheme.caption.copyWith(
                                color: palette.gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    flex: 6,
                    child: Text(
                      item.meaning,
                      textAlign: TextAlign.end,
                      style: textTheme.bodySmall.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
