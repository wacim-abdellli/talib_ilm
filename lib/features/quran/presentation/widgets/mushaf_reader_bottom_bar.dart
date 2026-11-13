import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/utils/arabic_digits.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/services/quran_audio_service.dart';
import 'hifdh_repeat_options_sheet.dart';
import 'tajweed_guide_sheet.dart';

class MushafReaderBottomBar extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final ValueChanged<int> onPageChanged;
  final QuranAudioService audioService;
  final MushafThemeMode themeMode;
  final bool allowAudioControls;
  final bool showTajweedLegend;

  const MushafReaderBottomBar({
    super.key,
    required this.currentPage,
    required this.onPageChanged,
    required this.audioService,
    this.themeMode = MushafThemeMode.white,
    this.pageCount = 604,
    this.allowAudioControls = true,
    this.showTajweedLegend = true,
  }) : assert(pageCount > 0);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final barBg = MushafColors.overlayBgFor(themeMode, palette);
    final barBorder = MushafColors.overlayBorderFor(themeMode, palette);
    final textColor = MushafColors.overlayTextFor(themeMode, palette);
    final textMutedColor = MushafColors.overlayTextMutedFor(themeMode, palette);
    final pillBg = MushafColors.overlayPillFor(themeMode, palette);

    return AnimatedBuilder(
      animation: Listenable.merge([
        audioService.isPlayingNotifier,
        audioService.isLoadingNotifier,
        audioService.activeAyahNotifier,
        audioService.activeSurahNotifier,
        audioService.selectedReciterNotifier,
        audioService.isFullSurahModeNotifier,
      ]),
      builder: (context, _) {
        final isPlaying = audioService.isPlayingNotifier.value;
        final activeAyah = audioService.activeAyahNotifier.value;
        final activeSurah = audioService.activeSurahNotifier.value;
        final hasActiveAudio =
            allowAudioControls && activeAyah != null && activeSurah != null;

        return Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: barBg,
            border: Border(top: BorderSide(color: barBorder)),
            boxShadow: palette.shadow,
          ),
          child: hasActiveAudio
              ? _buildMiniAudioPlayer(
                  palette: palette,
                  textTheme: textTheme,
                  isPlaying: isPlaying,
                  surah: activeSurah,
                  ayah: activeAyah,
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  pillBg: pillBg,
                  barBorder: barBorder,
                )
              : _buildPageScrubber(
                  context: context,
                  palette: palette,
                  textTheme: textTheme,
                  textColor: textColor,
                  textMutedColor: textMutedColor,
                  barBorder: barBorder,
                  pillBg: pillBg,
                  pageCount: pageCount,
                  showTajweedLegend: showTajweedLegend,
                ),
        );
      },
    );
  }

  Widget _buildMiniAudioPlayer({
    required AppPalette palette,
    required AppTextTheme textTheme,
    required bool isPlaying,
    required int surah,
    required int ayah,
    required Color textColor,
    required Color textMutedColor,
    required Color pillBg,
    required Color barBorder,
  }) {
    final playingSurahName = quran.getSurahNameArabic(surah);
    final isLoading = audioService.isLoadingNotifier.value;
    final isFullSurah = audioService.isFullSurahModeNotifier.value;
    final speedControl = ValueListenableBuilder<double>(
      valueListenable: audioService.speedNotifier,
      builder: (context, speed, _) {
        const speeds = [0.75, 1.0, 1.25, 1.5];
        final nextSpeed =
            speeds[(speeds.indexWhere((item) => (item - speed).abs() < 0.01) +
                    1) %
                speeds.length];
        return Semantics(
          button: true,
          label: 'سرعة التلاوة $speed×',
          child: Tooltip(
            message: 'السرعة $speed×، اضغط للتغيير',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoading
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        audioService.setPlaybackSpeed(nextSpeed);
                      },
                borderRadius: AppRadius.pillRadius,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: AppSize.tap,
                    minHeight: AppSize.tap,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(color: barBorder),
                  ),
                  child: Text(
                    '${speed == 1.0 ? "1" : speed}×',
                    style: textTheme.label.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    final repeatControl = ValueListenableBuilder<AudioRepeatMode>(
      valueListenable: audioService.repeatModeNotifier,
      builder: (context, repeatMode, _) {
        final icon = switch (repeatMode) {
          AudioRepeatMode.none => Icons.repeat_rounded,
          AudioRepeatMode.repeatOnce => Icons.repeat_one_rounded,
          AudioRepeatMode.infinite => Icons.all_inclusive_rounded,
        };
        final description = switch (repeatMode) {
          AudioRepeatMode.none => 'التكرار معطل',
          AudioRepeatMode.repeatOnce =>
            isFullSurah ? 'تكرار السورة مرة واحدة' : 'تكرار الآية مرة واحدة',
          AudioRepeatMode.infinite =>
            isFullSurah ? 'تكرار السورة باستمرار' : 'تكرار الآية باستمرار',
        };
        return AppIconButton(
          icon: icon,
          tooltip: description,
          color: repeatMode == AudioRepeatMode.none
              ? textMutedColor
              : palette.gold,
          onPressed: isLoading
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  if (isFullSurah) {
                    audioService.cycleRepeatMode();
                  } else {
                    HifdhRepeatOptionsSheet.show(
                      context,
                      audioService: audioService,
                      surahNumber: surah,
                      currentAyah: ayah,
                    );
                  }
                },
        );
      },
    );
    final previousControl = AppIconButton(
      icon: Icons.skip_next_rounded,
      tooltip: isFullSurah ? 'السورة السابقة' : 'الآية السابقة',
      color: textColor,
      onPressed: isLoading
          ? null
          : isFullSurah || audioService.activeReciter.isSurahBased
          ? audioService.previousSurah
          : audioService.previousAyah,
    );
    final nextControl = AppIconButton(
      icon: Icons.skip_previous_rounded,
      tooltip: isFullSurah ? 'السورة التالية' : 'الآية التالية',
      color: textColor,
      onPressed: isLoading
          ? null
          : isFullSurah || audioService.activeReciter.isSurahBased
          ? audioService.nextSurah
          : audioService.nextAyah,
    );
    final playControl = Semantics(
      button: true,
      label: isLoading
          ? 'جارٍ تحميل التلاوة'
          : isPlaying
          ? 'إيقاف التلاوة مؤقتًا'
          : 'استئناف التلاوة',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  if (isPlaying) {
                    audioService.pause();
                  } else {
                    audioService.resume();
                  }
                },
          borderRadius: AppRadius.pillRadius,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: AppSize.tap,
              minHeight: AppSize.tap,
            ),
            decoration: BoxDecoration(
              color: palette.primary,
              shape: BoxShape.circle,
              boxShadow: palette.shadow,
            ),
            alignment: Alignment.center,
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
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: palette.onPrimary,
                    size: AppIcon.md,
                  ),
          ),
        ),
      ),
    );
    final closeControl = AppIconButton(
      icon: Icons.close_rounded,
      tooltip: 'إغلاق المشغل',
      color: textMutedColor,
      onPressed: isLoading
          ? null
          : () {
              HapticFeedback.lightImpact();
              audioService.stop();
            },
    );
    final audioIndicator = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: palette.primarySoft.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        isPlaying ? Icons.graphic_eq_rounded : Icons.headphones_rounded,
        color: palette.primary,
        size: AppIcon.sm,
      ),
    );
    final details = Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            final targetPage = quran.getPageNumber(surah, ayah);
            onPageChanged(targetPage);
          },
          borderRadius: AppRadius.smRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isFullSurah
                    ? 'سورة ${getVocalizedSurahName(surah, fallback: playingSurahName)} كاملة'
                    : '${getVocalizedSurahName(surah, fallback: playingSurahName)} • الآية $ayah',
                style: textTheme.bodySmall.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                audioService.activeReciter.name,
                style: textTheme.caption.copyWith(color: textMutedColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 500 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.2;
        if (stacked) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  audioIndicator,
                  const SizedBox(width: AppSpace.sm),
                  details,
                  closeControl,
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  speedControl,
                  repeatControl,
                  previousControl,
                  playControl,
                  nextControl,
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            audioIndicator,
            const SizedBox(width: AppSpace.xs),
            details,
            speedControl,
            repeatControl,
            previousControl,
            playControl,
            nextControl,
            closeControl,
          ],
        );
      },
    );
  }

  Widget _buildPageScrubber({
    required BuildContext context,
    required AppPalette palette,
    required AppTextTheme textTheme,
    required Color textColor,
    required Color textMutedColor,
    required Color barBorder,
    required Color pillBg,
    required int pageCount,
    required bool showTajweedLegend,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 1. Authentic Medina Mushaf Tajweed Color Legend Strip ───────
        if (showTajweedLegend) ...[
          _buildTajweedLegend(
            context: context,
            palette: palette,
            textTheme: textTheme,
            barBorder: barBorder,
            pillBg: pillBg,
            textColor: textColor,
            textMutedColor: textMutedColor,
          ),
          const SizedBox(height: AppSpace.xxs),
        ],
        // ── 2. Mushaf Page Navigation Range Scrubber ─────────────────────
        Row(
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
                max: pageCount.toDouble(),
                activeColor: palette.gold,
                inactiveColor: barBorder,
                onChanged: (val) {
                  onPageChanged(val.round());
                },
              ),
            ),
            Text(
              '$pageCount',
              style: textTheme.caption.copyWith(color: textMutedColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTajweedLegend({
    required BuildContext context,
    required AppPalette palette,
    required AppTextTheme textTheme,
    required Color barBorder,
    required Color pillBg,
    required Color textColor,
    required Color textMutedColor,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        TajweedGuideSheet.show(context);
      },
      borderRadius: AppRadius.pillRadius,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.xxs,
        ),
        decoration: BoxDecoration(
          color: pillBg,
          borderRadius: AppRadius.pillRadius,
          border: Border.all(color: barBorder, width: 0.8),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpace.sm,
          runSpacing: AppSpace.xxs,
          children: [
            _buildTajweedItem(
              color: TajweedPalette.madd,
              label: 'مدود (4-6)',
              textTheme: textTheme,
              textColor: textColor,
            ),
            _buildTajweedItem(
              color: TajweedPalette.maddShort,
              label: 'حركتان',
              textTheme: textTheme,
              textColor: textColor,
            ),
            _buildTajweedItem(
              color: TajweedPalette.ikhfaa,
              label: 'غنة وإخفاء',
              textTheme: textTheme,
              textColor: textColor,
            ),
            _buildTajweedItem(
              color: TajweedPalette.qalqalah,
              label: 'قلقلة',
              textTheme: textTheme,
              textColor: textColor,
            ),
            _buildTajweedItem(
              color: TajweedPalette.silent,
              label: 'لا يُلفظ',
              textTheme: textTheme,
              textColor: textColor,
            ),
            Icon(
              Icons.info_outline_rounded,
              size: AppIcon.xs,
              color: textMutedColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTajweedItem({
    required Color color,
    required String label,
    required AppTextTheme textTheme,
    required Color textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpace.xxs),
        Text(label, style: textTheme.captionBold.copyWith(color: textColor)),
      ],
    );
  }
}
