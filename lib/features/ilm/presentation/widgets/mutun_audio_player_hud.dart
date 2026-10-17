import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_ui.dart';
import '../../data/services/mutun_audio_service.dart';

/// Refined scholarly Audio Player HUD mirroring media_1792193062531.jpg and media_1792193064810.jpg.
class MutunAudioPlayerHud extends StatelessWidget {
  final MutunAudioService audioService;
  final VoidCallback onOpenQuickJump;
  final String? bookId;

  const MutunAudioPlayerHud({
    super.key,
    required this.audioService,
    required this.onOpenQuickJump,
    this.bookId,
  });

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
                  ...MutunAudioService.availableReciters.map((reciter) {
                    final isSelected =
                        audioService.selectedReciter.id == reciter.id;
                    return Material(
                      color: isSelected
                          ? tokens.activeParagraphBg
                          : Colors.transparent,
                      borderRadius: AppRadius.mdRadius,
                      child: InkWell(
                        borderRadius: AppRadius.mdRadius,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          audioService.setSelectedReciter(reciter);
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Reciter Selector Button ───────────────────────────
              ValueListenableBuilder<MutunReciter>(
                valueListenable: audioService.selectedReciterNotifier,
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
                            size: AppIcon.sm,
                            color: tokens.rosetteGold,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              reciter.name,
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
                            size: AppIcon.sm,
                            color: palette.textMuted,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // ── Playback Controls Group ───────────────────────────
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
                      audioService.stop();
                    },
                  ),

                  // Play / Pause main button
                  ValueListenableBuilder<bool>(
                    valueListenable: audioService.isPlayingNotifier,
                    builder: (context, isPlaying, _) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: audioService.isLoadingNotifier,
                        builder: (context, isLoading, _) {
                          return Material(
                            color: tokens.rosetteGold,
                            shape: const CircleBorder(),
                            elevation: 1,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                audioService.togglePlayPause(bookId: bookId);
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

                  // Repeat / Loop button
                  ValueListenableBuilder<MutunRepeatMode>(
                    valueListenable: audioService.repeatModeNotifier,
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
                        icon: Icon(icon, color: color, size: AppIcon.md),
                        tooltip: 'تكرار الفقرة أو المتن',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          audioService.toggleRepeatMode();
                        },
                      );
                    },
                  ),

                  // Speed button (x1.0, x1.25...)
                  ValueListenableBuilder<double>(
                    valueListenable: audioService.speedNotifier,
                    builder: (context, speed, _) {
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          audioService.cycleSpeed();
                        },
                        borderRadius: AppRadius.pillRadius,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.xs,
                            vertical: AppSpace.xs,
                          ),
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
                        ),
                      );
                    },
                  ),

                  // Quick jump icon
                  IconButton(
                    icon: Icon(
                      Icons.format_list_numbered_rounded,
                      color: palette.textMuted,
                      size: AppIcon.md,
                    ),
                    tooltip: 'فهرس المتن',
                    onPressed: onOpenQuickJump,
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
