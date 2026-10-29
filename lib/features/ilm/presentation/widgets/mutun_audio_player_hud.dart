import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/services/mutun_audio_service.dart';
import 'book_audio_sheets.dart';

/// Scholarly Multi-Reciter & Multi-Chapter Audio Player HUD for Ilm Mutun
/// and Shamela Heritage Books (`خزانة التراث الإسلامي`).
class MutunAudioPlayerHud extends StatefulWidget {
  final MutunAudioService audioService;
  final VoidCallback? onOpenQuickJump;
  final String? bookId;
  final VoidCallback? onClose;

  const MutunAudioPlayerHud({
    super.key,
    required this.audioService,
    this.onOpenQuickJump,
    this.bookId,
    this.onClose,
  });

  @override
  State<MutunAudioPlayerHud> createState() => _MutunAudioPlayerHudState();
}

class _MutunAudioPlayerHudState extends State<MutunAudioPlayerHud> {
  @override
  void initState() {
    super.initState();
    widget.audioService.playbackErrorNotifier.addListener(_onPlaybackError);
    if (widget.bookId != null) {
      widget.audioService.syncReciterForBook(widget.bookId!);
    }
  }

  @override
  void didUpdateWidget(covariant MutunAudioPlayerHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioService != widget.audioService) {
      oldWidget.audioService.playbackErrorNotifier
          .removeListener(_onPlaybackError);
      widget.audioService.playbackErrorNotifier.addListener(_onPlaybackError);
    }
    if (oldWidget.bookId != widget.bookId && widget.bookId != null) {
      widget.audioService.syncReciterForBook(widget.bookId!);
    }
  }

  @override
  void dispose() {
    widget.audioService.playbackErrorNotifier.removeListener(_onPlaybackError);
    super.dispose();
  }

  void _onPlaybackError() {
    final err = widget.audioService.playbackErrorNotifier.value;
    if (err != null && mounted) {
      AppSnackbar.error(context, err);
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$m:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final tokens = MutunThemeColors.getTokens(isDark: palette.isDark);

    return Container(
      decoration: BoxDecoration(
        color: tokens.audioBarBg,
        border: Border(
          top: BorderSide(color: tokens.audioBarBorder, width: 1.0),
        ),
        boxShadow: palette.shadow,
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      child: SafeArea(
        top: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ValueListenableBuilder<MutunReciter>(
            valueListenable: widget.audioService.selectedReciterNotifier,
            builder: (context, _, _) {
              final reciters = widget.audioService
                  .getAvailableRecitersForBook(widget.bookId);
              final effectiveReciter =
                  widget.audioService.effectiveReciterForBook(widget.bookId);
              final source = widget.audioService.getSourceForBook(
                widget.bookId,
                reciterId: effectiveReciter.id,
              );
              final chapters = source?.chapters ?? const <BookAudioChapter>[];
              final hasMultiChapters =
                  widget.bookId != null && chapters.length > 1;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Row 1: Reciter Picker + Speed / Repeat / Fihris / Close ──
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: 'اختيار القارئ: ${effectiveReciter.name}',
                          child: InkWell(
                            onTap: () => BookReciterPickerSheet.show(
                              context,
                              audioService: widget.audioService,
                              bookId: widget.bookId,
                            ),
                            borderRadius: AppRadius.pillRadius,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: AppSize.tap,
                              ),
                              child: Container(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpace.sm,
                                  vertical: AppSpace.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: tokens.cardBg,
                                  borderRadius: AppRadius.pillRadius,
                                  border: Border.all(color: tokens.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.record_voice_over_rounded,
                                      size: AppIcon.sm,
                                      color: tokens.rosetteGold,
                                    ),
                                    const SizedBox(width: AppSpace.xs),
                                    Expanded(
                                      child: Text(
                                        effectiveReciter.name,
                                        style: textTheme.captionBold.copyWith(
                                          color: palette.text,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (reciters.length > 1) ...[
                                      const SizedBox(width: AppSpace.xxs),
                                      Container(
                                        padding: const EdgeInsetsDirectional
                                            .symmetric(
                                          horizontal: AppSpace.xs,
                                          vertical: AppSpace.xxs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: palette.goldSoft,
                                          borderRadius: AppRadius.pillRadius,
                                        ),
                                        child: Text(
                                          '+${reciters.length - 1}',
                                          style: textTheme.captionBold.copyWith(
                                            color: palette.onPrimarySoft,
                                          ),
                                        ),
                                      ),
                                    ],
                                    Icon(
                                      Icons.arrow_drop_down_rounded,
                                      size: AppIcon.sm,
                                      color: palette.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),

                      // Speed Pill (48dp tap target)
                      ValueListenableBuilder<double>(
                        valueListenable: widget.audioService.speedNotifier,
                        builder: (context, speed, _) {
                          final label =
                              'x${speed.toStringAsFixed(speed % 1 == 0 ? 0 : 2)}';
                          return Semantics(
                            button: true,
                            label: 'سرعة التلاوة $label',
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                widget.audioService.cycleSpeed();
                              },
                              borderRadius: AppRadius.pillRadius,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: AppSize.tap,
                                  minHeight: AppSize.tap,
                                ),
                                child: Center(
                                  child: Container(
                                    padding:
                                        const EdgeInsetsDirectional.symmetric(
                                      horizontal: AppSpace.sm,
                                      vertical: AppSpace.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tokens.cardBg,
                                      borderRadius: AppRadius.pillRadius,
                                      border: Border.all(
                                        color: tokens.cardBorder,
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: textTheme.captionBold.copyWith(
                                        color: palette.text,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      if (widget.onOpenQuickJump != null)
                        IconButton(
                          icon: Icon(
                            Icons.format_list_numbered_rounded,
                            color: palette.textMuted,
                            size: AppIcon.sm,
                          ),
                          tooltip: 'فهرس الكتاب',
                          onPressed: widget.onOpenQuickJump,
                        ),

                      if (widget.onClose != null)
                        IconButton(
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: palette.textMuted,
                            size: AppIcon.md,
                          ),
                          tooltip: 'إخفاء شريط الصوت',
                          onPressed: widget.onClose,
                        ),
                    ],
                  ),

                  // ── Row 2 (Optional): Multi-Chapter Navigation Strip ──────
                  if (hasMultiChapters) ...[
                    const SizedBox(height: AppSpace.xxs),
                    ValueListenableBuilder<int>(
                      valueListenable:
                          widget.audioService.activeChapterIndexNotifier,
                      builder: (context, activeIdx, _) {
                        final safeIdx = activeIdx.clamp(0, chapters.length - 1);
                        final chapter = chapters[safeIdx];
                        final canPrev = safeIdx > 0;
                        final canNext = safeIdx + 1 < chapters.length;

                        return Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.chevron_right_rounded,
                                size: AppIcon.md,
                                color: canPrev
                                    ? palette.text
                                    : palette.textSubtle,
                              ),
                              tooltip: 'المقطع السابق',
                              onPressed: canPrev
                                  ? () {
                                      HapticFeedback.selectionClick();
                                      widget.audioService.previousChapter(
                                        bookId: widget.bookId,
                                      );
                                    }
                                  : null,
                            ),
                            Expanded(
                              child: Semantics(
                                button: true,
                                label:
                                    'فهرس المقاطع الصوتية: ${chapter.title}',
                                child: InkWell(
                                  borderRadius: AppRadius.mdRadius,
                                  onTap: () => BookAudioChaptersSheet.show(
                                    context,
                                    audioService: widget.audioService,
                                    bookId: widget.bookId!,
                                  ),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: AppSize.tap,
                                    ),
                                    child: Container(
                                      padding:
                                          const EdgeInsetsDirectional.symmetric(
                                        horizontal: AppSpace.md,
                                        vertical: AppSpace.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tokens.cardBg,
                                        borderRadius: AppRadius.mdRadius,
                                        border: Border.all(
                                          color: tokens.cardBorder,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.queue_music_rounded,
                                            size: AppIcon.sm,
                                            color: tokens.rosetteGold,
                                          ),
                                          const SizedBox(width: AppSpace.xs),
                                          Expanded(
                                            child: Text(
                                              '${safeIdx + 1}/${chapters.length} · ${chapter.title}',
                                              style: textTheme.captionBold
                                                  .copyWith(
                                                color: palette.text,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(
                                            Icons.unfold_more_rounded,
                                            size: AppIcon.sm,
                                            color: palette.textMuted,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.chevron_left_rounded,
                                size: AppIcon.md,
                                color: canNext
                                    ? palette.text
                                    : palette.textSubtle,
                              ),
                              tooltip: 'المقطع التالي',
                              onPressed: canNext
                                  ? () {
                                      HapticFeedback.selectionClick();
                                      widget.audioService.nextChapter(
                                        bookId: widget.bookId,
                                      );
                                    }
                                  : null,
                            ),
                          ],
                        );
                      },
                    ),
                  ],

                  // ── Row 3: Seek Scrubber ──────────────────────────────────
                  ValueListenableBuilder<Duration>(
                    valueListenable: widget.audioService.positionNotifier,
                    builder: (context, position, _) {
                      return ValueListenableBuilder<Duration>(
                        valueListenable: widget.audioService.durationNotifier,
                        builder: (context, duration, _) {
                          final maxMs = duration.inMilliseconds > 0
                              ? duration.inMilliseconds.toDouble()
                              : 1.0;
                          final currentMs = position.inMilliseconds
                              .toDouble()
                              .clamp(0.0, maxMs);

                          return Row(
                            children: [
                              Text(
                                _formatDuration(position),
                                style: textTheme.captionBold.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: tokens.rosetteGold,
                                    inactiveTrackColor: tokens.cardBorder,
                                    thumbColor: tokens.rosetteGold,
                                    overlayColor: tokens.activeParagraphBg,
                                    trackHeight: 2.5,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 5.0,
                                    ),
                                  ),
                                  child: Slider(
                                    value: currentMs,
                                    min: 0.0,
                                    max: maxMs,
                                    onChanged: (val) {
                                      widget.audioService.seek(
                                        AppMotion.fromMilliseconds(val.round()),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: textTheme.caption.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  // ── Row 4: Centered Transport Controls ────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.stop_rounded,
                          color: palette.textMuted,
                          size: AppIcon.md,
                        ),
                        tooltip: 'إيقاف',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          widget.audioService.stop();
                        },
                      ),
                      const SizedBox(width: AppSpace.xs),
                      IconButton(
                        icon: Icon(
                          Icons.forward_5_rounded,
                          color: palette.textMuted,
                          size: AppIcon.md,
                        ),
                        tooltip: 'رجوع 5 ثوانٍ',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          widget.audioService.seekBackward5s();
                        },
                      ),
                      const SizedBox(width: AppSpace.sm),
                      ValueListenableBuilder<bool>(
                        valueListenable: widget.audioService.isPlayingNotifier,
                        builder: (context, isPlaying, _) {
                          return ValueListenableBuilder<bool>(
                            valueListenable:
                                widget.audioService.isLoadingNotifier,
                            builder: (context, isLoading, _) {
                              return Semantics(
                                button: true,
                                label: isPlaying ? 'إيقاف مؤقت' : 'تشغيل الصوت',
                                child: Material(
                                  color: tokens.rosetteGold,
                                  shape: const CircleBorder(),
                                  elevation: 1,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      widget.audioService.togglePlayPause(
                                        bookId: widget.bookId,
                                      );
                                    },
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth: AppSize.tap,
                                        minHeight: AppSize.tap,
                                      ),
                                      child: Center(
                                        child: isLoading && !isPlaying
                                            ? SizedBox(
                                                width: AppIcon.md,
                                                height: AppIcon.md,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: palette.surface,
                                                ),
                                              )
                                            : Icon(
                                                isPlaying
                                                    ? Icons.pause_rounded
                                                    : Icons.play_arrow_rounded,
                                                color: palette.surface,
                                                size: AppIcon.lg,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(width: AppSpace.sm),
                      IconButton(
                        icon: Icon(
                          Icons.replay_5_rounded,
                          color: palette.textMuted,
                          size: AppIcon.md,
                        ),
                        tooltip: 'تقديم 5 ثوانٍ',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          widget.audioService.seekForward5s();
                        },
                      ),
                      const SizedBox(width: AppSpace.xs),
                      ValueListenableBuilder<MutunRepeatMode>(
                        valueListenable: widget.audioService.repeatModeNotifier,
                        builder: (context, mode, _) {
                          final icon = mode == MutunRepeatMode.singleParagraph
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded;
                          final color = mode == MutunRepeatMode.none
                              ? palette.textMuted
                              : tokens.rosetteGold;
                          return IconButton(
                            icon: Icon(icon, color: color, size: AppIcon.sm),
                            tooltip: 'تكرار المقطع أو الكتاب',
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              widget.audioService.toggleRepeatMode();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
