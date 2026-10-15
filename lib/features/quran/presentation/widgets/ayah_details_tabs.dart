import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/quran_tafsir_service.dart';

class AyahTafsirTabView extends StatefulWidget {
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
  State<AyahTafsirTabView> createState() => _AyahTafsirTabViewState();
}

class _AyahTafsirTabViewState extends State<AyahTafsirTabView> {
  final ScrollController _scrollController = ScrollController();
  double _fontScale = 1.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _increaseFont() {
    if (_fontScale < 1.35) {
      HapticFeedback.selectionClick();
      setState(() => _fontScale = (_fontScale + 0.1).clamp(0.85, 1.35));
    }
  }

  void _decreaseFont() {
    if (_fontScale > 0.85) {
      HapticFeedback.selectionClick();
      setState(() => _fontScale = (_fontScale - 0.1).clamp(0.85, 1.35));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final scholarName = QuranTafsirService.getScholarName(widget.selectedScholar);
    final scholarAuthor = QuranTafsirService.getScholarAuthor(widget.selectedScholar);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Scholar Selector Chips & Font Zoom Stepper
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.xxs),
                child: Row(
                  children: TafsirScholar.values.map((scholar) {
                    final isSelected = widget.selectedScholar == scholar;
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
                      child: ChoiceChip(
                        label: Text(
                          QuranTafsirService.getScholarName(scholar),
                          style: textTheme.caption.copyWith(
                            color: isSelected ? palette.onPrimary : palette.text,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: palette.primary,
                        backgroundColor: palette.surfaceMuted,
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
                            widget.onScholarChanged(scholar);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            // Quick Font Size Stepper
            Container(
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.pillRadius,
                border: Border.all(color: palette.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: _decreaseFont,
                    borderRadius: AppRadius.pillRadius,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.xs,
                        vertical: AppSpace.xxs,
                      ),
                      child: Text(
                        'A-',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 12, color: palette.border),
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xxs),
                    child: Text(
                      '${(_fontScale * 100).round()}%',
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                  Container(width: 1, height: 12, color: palette.border),
                  InkWell(
                    onTap: _increaseFont,
                    borderRadius: AppRadius.pillRadius,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.xs,
                        vertical: AppSpace.xxs,
                      ),
                      child: Text(
                        'A+',
                        style: textTheme.caption.copyWith(
                          color: palette.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpace.xs),

        // 2. Focused Tafsir Commentary Area with Fully Unlocked Scrolling
        Expanded(
          child: widget.loadingTafsir
              ? Container(
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: palette.border),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeleton(width: 140, height: 18),
                      SizedBox(height: AppSpace.md),
                      AppSkeleton(width: double.infinity, height: 16),
                      SizedBox(height: AppSpace.xs),
                      AppSkeleton(width: double.infinity, height: 16),
                      SizedBox(height: AppSpace.xs),
                      AppSkeleton(width: double.infinity, height: 16),
                      SizedBox(height: AppSpace.xs),
                      AppSkeleton(width: 220, height: 16),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(
                      color: palette.border.withValues(alpha: 0.8),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.mdRadius,
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsetsDirectional.all(AppSpace.md),
                        child: SelectionArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Scholar Banner
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                                    decoration: BoxDecoration(
                                      color: palette.gold.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.auto_stories_rounded,
                                      size: AppIcon.sm,
                                      color: palette.gold,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.xs),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          scholarName,
                                          style: textTheme.titleSmall.copyWith(
                                            color: palette.gold,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          scholarAuthor,
                                          style: textTheme.caption.copyWith(
                                            color: palette.textMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppIconButton(
                                    icon: Icons.copy_rounded,
                                    tooltip: 'نسخ التفسير',
                                    color: palette.textMuted,
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      Clipboard.setData(ClipboardData(text: widget.tafsirText));
                                      AppSnackbar.success(context, 'تم نسخ التفسير');
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Divider(
                                height: 1,
                                color: palette.border.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: AppSpace.sm),

                              // Sacred Commentary Content with Paragraph Breakdown
                              if (widget.tafsirText.trim().isEmpty) ...[
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: AppIcon.md,
                                          color: palette.textMuted,
                                        ),
                                        const SizedBox(height: AppSpace.xs),
                                        Text(
                                          'لا يتوفر نص للتفسير لهذه الآية حالياً',
                                          style: textTheme.caption.copyWith(
                                            color: palette.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Directionality(
                                  textDirection: widget.selectedScholar == TafsirScholar.englishIbnKathir
                                      ? TextDirection.ltr
                                      : TextDirection.rtl,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: widget.tafsirText
                                        .split('\n')
                                        .where((p) => p.trim().isNotEmpty)
                                        .map((paragraph) {
                                      return Padding(
                                        padding: const EdgeInsetsDirectional.only(
                                          bottom: AppSpace.sm,
                                        ),
                                        child: Text(
                                          paragraph.trim(),
                                          style: textTheme.body.copyWith(
                                            color: palette.text,
                                            height: 1.9 * _fontScale,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpace.md),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class AyahWordsTabView extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;

  const AyahWordsTabView({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
  });

  @override
  State<AyahWordsTabView> createState() => _AyahWordsTabViewState();
}

class _AyahWordsTabViewState extends State<AyahWordsTabView> {
  late Future<List<WordMeaning>> _wordsFuture;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  @override
  void didUpdateWidget(covariant AyahWordsTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahNumber != widget.surahNumber ||
        oldWidget.ayahNumber != widget.ayahNumber) {
      _loadWords();
    }
  }

  void _loadWords() {
    _wordsFuture = QuranTafsirService.fetchWordMeanings(
      widget.surahNumber,
      widget.ayahNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return FutureBuilder<List<WordMeaning>>(
      future: _wordsFuture,
      initialData: QuranTafsirService.getCachedWordMeanings(
        widget.surahNumber,
        widget.ayahNumber,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            (snapshot.data == null || snapshot.data!.isEmpty)) {
          return ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
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
                child: const Row(
                  children: [
                    AppSkeleton(width: 80, height: 22),
                    Spacer(),
                    AppSkeleton(width: 130, height: 18),
                  ],
                ),
              );
            },
          );
        }

        final words = snapshot.data ?? const [];

        if (words.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpace.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: AppIcon.lg,
                    color: palette.textMuted,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    'المصحف يعمل كاملاً دون إنترنت',
                    style: textTheme.bodySmall.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'معاني الكلمات المفردة تتطلب اتصالاً لحفظها تلقائياً على جهازك للاستخدام لاحقاً بدون إنترنت.',
                    style: textTheme.caption.copyWith(color: palette.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.md),
                  AppButton.outline(
                    label: 'إعادة المحاولة',
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _loadWords();
                      });
                    },
                  ),
                ],
              ),
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
