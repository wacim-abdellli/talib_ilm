import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/services/mutun_audio_service.dart';

/// Refined scholarly Audio Player HUD mirroring media_1792193062531.jpg and media_1792193064810.jpg.
class MutunAudioPlayerHud extends StatefulWidget {
  final MutunAudioService audioService;
  final VoidCallback onOpenQuickJump;
  final String? bookId;
  final VoidCallback? onClose;

  const MutunAudioPlayerHud({
    super.key,
    required this.audioService,
    required this.onOpenQuickJump,
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
  }

  @override
  void didUpdateWidget(covariant MutunAudioPlayerHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioService != widget.audioService) {
      oldWidget.audioService.playbackErrorNotifier.removeListener(_onPlaybackError);
      widget.audioService.playbackErrorNotifier.addListener(_onPlaybackError);
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

  String _getEffectiveReciterName(MutunReciter selected) {
    if (widget.bookId != null) {
      final available = widget.audioService.getAvailableRecitersForBook(widget.bookId);
      if (available.isNotEmpty && !available.any((r) => r.id == selected.id)) {
        return available.first.name;
      }
    }
    return selected.name;
  }

  void _showReciterPicker(BuildContext context) {
    HapticFeedback.lightImpact();
    final palette = context.palette;
    final textTheme = context.text;
    final tokens = MutunThemeColors.getTokens(isDark: palette.isDark);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
            border: Border.all(color: palette.border),
          ),
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          child: SafeArea(
            top: false,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.textMuted.withValues(alpha: 0.3),
                        borderRadius: AppRadius.pillRadius,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Text(
                    'اختيار القارئ',
                    style: textTheme.titleSmall.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  ...widget.audioService.getAvailableRecitersForBook(widget.bookId).map((reciter) {
                    final isSelected =
                        widget.audioService.selectedReciter.id == reciter.id;
                    return Material(
                      color: isSelected
                          ? tokens.activeParagraphBg
                          : Colors.transparent,
                      borderRadius: AppRadius.mdRadius,
                      child: InkWell(
                        borderRadius: AppRadius.mdRadius,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.audioService.setSelectedReciter(reciter);
                          Navigator.of(sheetContext).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.md,
                            vertical: AppSpace.md,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isSelected
                                    ? tokens.rosetteGold
                                    : palette.textMuted,
                                size: AppIcon.md,
                              ),
                              const SizedBox(width: AppSpace.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reciter.name,
                                      style: textTheme.body.copyWith(
                                        color: palette.text,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpace.xxs),
                                    Text(
                                      reciter.description,
                                      style: textTheme.caption.copyWith(
                                        color: palette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Row 1: Seek Bar with Timestamps & Close ───────────────
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
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                              fontWeight: FontWeight.bold,
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
                                    Duration(
                                      days: 0,
                                      milliseconds: val.round(),
                                    ),
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
                          if (widget.onClose != null) ...[
                            const SizedBox(width: AppSpace.xs),
                            IconButton(
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: palette.textMuted,
                                size: AppIcon.sm,
                              ),
                              tooltip: 'إخفاء شريط الصوت',
                              onPressed: widget.onClose,
                            ),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),

              // ── Row 2: Controls & Reciter ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── Reciter Selector Button ──
                  ValueListenableBuilder<MutunReciter>(
                    valueListenable: widget.audioService.selectedReciterNotifier,
                    builder: (context, reciter, _) {
                      return InkWell(
                        onTap: () => _showReciterPicker(context),
                        borderRadius: AppRadius.pillRadius,
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.record_voice_over_rounded,
                                size: AppIcon.xs,
                                color: tokens.rosetteGold,
                              ),
                              const SizedBox(width: AppSpace.xxs),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 85),
                                child: Text(
                                  _getEffectiveReciterName(reciter),
                                  style: textTheme.caption.copyWith(
                                    color: palette.text,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: AppIcon.xs,
                                color: palette.textMuted,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // ── Center Controls: Stop, -5s, Play/Pause, +5s ──
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stop button
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

                      // Rewind 5s
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

                      // Play / Pause main button
                      ValueListenableBuilder<bool>(
                        valueListenable: widget.audioService.isPlayingNotifier,
                        builder: (context, isPlaying, _) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: widget.audioService.isLoadingNotifier,
                            builder: (context, isLoading, _) {
                              return Material(
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
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.all(
                                      AppSpace.sm,
                                    ),
                                    child: isLoading && !isPlaying
                                        ? SizedBox(
                                            width: AppIcon.md,
                                            height: AppIcon.md,
                                            child: CircularProgressIndicator(
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
                              );
                            },
                          );
                        },
                      ),

                      // Forward 5s
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
                    ],
                  ),

                  // ── Trailing: Repeat, Speed, Fihris ──
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Repeat button
                      ValueListenableBuilder<MutunRepeatMode>(
                        valueListenable: widget.audioService.repeatModeNotifier,
                        builder: (context, mode, _) {
                          IconData icon;
                          Color color = palette.textMuted;
                          switch (mode) {
                            case MutunRepeatMode.none:
                              icon = Icons.repeat_rounded;
                              break;
                            case MutunRepeatMode.singleParagraph:
                              icon = Icons.repeat_one_rounded;
                              color = tokens.rosetteGold;
                              break;
                            case MutunRepeatMode.entireMatn:
                              icon = Icons.repeat_rounded;
                              color = tokens.rosetteGold;
                              break;
                          }
                          return IconButton(
                            icon: Icon(icon, color: color, size: AppIcon.sm),
                            tooltip: 'تكرار الفقرة أو المتن',
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              widget.audioService.toggleRepeatMode();
                            },
                          );
                        },
                      ),

                      // Speed button (x1.0, x1.25...)
                      ValueListenableBuilder<double>(
                        valueListenable: widget.audioService.speedNotifier,
                        builder: (context, speed, _) {
                          return InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.audioService.cycleSpeed();
                            },
                            borderRadius: AppRadius.pillRadius,
                            child: Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.xs,
                                vertical: AppSpace.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.cardBg,
                                borderRadius: AppRadius.pillRadius,
                                border: Border.all(color: tokens.cardBorder),
                              ),
                              child: Text(
                                'x${speed.toStringAsFixed(speed % 1 == 0 ? 0 : 2)}',
                                style: textTheme.caption.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Quick jump icon
                      IconButton(
                        icon: Icon(
                          Icons.format_list_numbered_rounded,
                          color: palette.textMuted,
                          size: AppIcon.sm,
                        ),
                        tooltip: 'فهرس المتن',
                        onPressed: widget.onOpenQuickJump,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
