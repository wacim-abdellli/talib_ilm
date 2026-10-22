import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../features/ilm/data/models/lesson_model.dart';

/// Full YouTube-grade interactive video overlay controller.
/// Strictly LTR layout (standard universal media player design).
class VideoPlayerOverlay extends StatefulWidget {
  final YoutubePlayerController controller;
  final String title;
  final Duration position;
  final Duration duration;
  final int? startSeconds;
  final int? endSeconds;
  final List<LessonChapter>? chapters;
  final bool isFullScreen;
  final double playbackSpeed;
  final VoidCallback onToggleFullScreen;
  final VoidCallback onBack;
  final VoidCallback onOpenSpeedSheet;
  final VoidCallback onOpenChaptersSheet;
  final ValueChanged<int> onSeekRelative;
  final ValueChanged<Duration> onSeekTo;
  final VoidCallback? onUserPlay;
  final VoidCallback? onUserPause;

  const VideoPlayerOverlay({
    super.key,
    required this.controller,
    required this.title,
    required this.position,
    required this.duration,
    this.startSeconds,
    this.endSeconds,
    this.chapters,
    required this.isFullScreen,
    required this.playbackSpeed,
    required this.onToggleFullScreen,
    required this.onBack,
    required this.onOpenSpeedSheet,
    required this.onOpenChaptersSheet,
    required this.onSeekRelative,
    required this.onSeekTo,
    this.onUserPlay,
    this.onUserPause,
  });

  @override
  State<VideoPlayerOverlay> createState() => _VideoPlayerOverlayState();
}

class _VideoPlayerOverlayState extends State<VideoPlayerOverlay> {
  bool _isVisible = true;
  Timer? _hideTimer;
  double? _dragFraction;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isNowPlaying = widget.controller.value.isPlaying;
    final wasPlaying = oldWidget.controller.value.isPlaying;

    if (isNowPlaying && !wasPlaying) {
      _startHideTimer();
    } else if (!isNowPlaying && wasPlaying) {
      setState(() => _isVisible = true);
      _cancelHideTimer();
    }
  }

  @override
  void dispose() {
    _cancelHideTimer();
    super.dispose();
  }

  void _startHideTimer() {
    _cancelHideTimer();
    if (!widget.controller.value.isPlaying) return;
    _hideTimer = Timer(AppMotion.controlsHide, () {
      if (mounted && widget.controller.value.isPlaying) {
        setState(() => _isVisible = false);
      }
    });
  }

  void _cancelHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void _toggleVisibility() {
    setState(() => _isVisible = !_isVisible);
    if (_isVisible) {
      _startHideTimer();
    } else {
      _cancelHideTimer();
    }
  }

  void _onUserInteracted() {
    if (!_isVisible) {
      setState(() => _isVisible = true);
    }
    _startHideTimer();
  }

  static String _formatTime(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final remM = m % 60;
      return '${h.toString().padLeft(2, '0')}:${remM.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String? _getCurrentChapterTitle() {
    if (widget.chapters == null || widget.chapters!.isEmpty) return null;
    final posSec = widget.controller.value.position.inSeconds;
    for (int i = 0; i < widget.chapters!.length; i++) {
      final ch = widget.chapters![i];
      final isLast = i == widget.chapters!.length - 1;
      final nextStart = isLast ? 999999 : widget.chapters![i + 1].startSeconds;
      if (posSec >= ch.startSeconds && posSec < nextStart) {
        return ch.title;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.controller.value.isPlaying;
    final isBuffering = widget.controller.value.playerState == PlayerState.buffering;

    final totalMs = widget.duration.inMilliseconds;
    final currentMs = _dragFraction != null
        ? (_dragFraction! * totalMs).round()
        : widget.position.inMilliseconds;

    final progressFraction = totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;
    final posStr = _formatTime(AppMotion.fromMilliseconds(currentMs));
    final durStr = _formatTime(widget.duration);
    final activeChapter = _getCurrentChapterTitle();

    // Force universal Left-to-Right media layout (matches real YouTube worldwide)
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full Video Tap Shutter ──
          Semantics(
            label: _isVisible ? 'إخفاء عناصر التحكم' : 'إظهار عناصر التحكم',
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: _toggleVisibility,
              child: const SizedBox.expand(),
            ),
          ),

          // ── YouTube Controls Overlay ──
          IgnorePointer(
            ignoring: !_isVisible,
            child: AnimatedOpacity(
              opacity: _isVisible ? 1.0 : 0.0,
              duration: AppMotion.fast,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppPalette.videoControlBg,
                      Colors.transparent,
                      Colors.transparent,
                      AppPalette.videoControlBg,
                    ],
                    stops: [0.0, 0.25, 0.70, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // ── Top Bar: Back (Left) | Title (Center) | Chapters & Speed (Right) ──
                    PositionedDirectional(
                      top: 0,
                      start: 0,
                      end: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Container(
                          height: widget.isFullScreen ? 48 : 52,
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.sm,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: widget.isFullScreen ? 'تصغير الشاشة' : 'رجوع',
                                icon: Icon(
                                  widget.isFullScreen
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.arrow_back_rounded,
                                  color: AppPalette.videoControlFg,
                                  size: AppIcon.md,
                                ),
                                onPressed: () {
                                  _onUserInteracted();
                                  widget.onBack();
                                },
                              ),
                              Expanded(
                                child: Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    widget.title,
                                    style: context.text.titleSmall.copyWith(
                                      color: AppPalette.videoControlFg,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpace.sm),
                              if (widget.chapters != null && widget.chapters!.isNotEmpty) ...[
                                Semantics(
                                  button: true,
                                  label: 'محاور المقطع',
                                  child: InkWell(
                                    borderRadius: AppRadius.pillRadius,
                                    onTap: () {
                                      _onUserInteracted();
                                      widget.onOpenChaptersSheet();
                                    },
                                    child: Container(
                                      padding: const EdgeInsetsDirectional.symmetric(
                                        horizontal: AppSpace.sm,
                                        vertical: AppSpace.xxs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppPalette.videoControlBg,
                                        borderRadius: AppRadius.pillRadius,
                                        border: Border.all(
                                          color: AppPalette.videoScrubberTrack,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.format_list_bulleted_rounded,
                                            color: AppPalette.videoScrubberActive,
                                            size: AppIcon.xs,
                                          ),
                                          const SizedBox(width: AppSpace.xxs),
                                          Text(
                                            'المحاور',
                                            style: context.text.caption.copyWith(
                                              color: AppPalette.videoControlFg,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpace.xs),
                              ],
                              Semantics(
                                button: true,
                                label: 'سرعة التشغيل',
                                child: InkWell(
                                  borderRadius: AppRadius.pillRadius,
                                  onTap: () {
                                    _onUserInteracted();
                                    widget.onOpenSpeedSheet();
                                  },
                                  child: Container(
                                    padding: const EdgeInsetsDirectional.symmetric(
                                      horizontal: AppSpace.sm,
                                      vertical: AppSpace.xxs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppPalette.videoControlBg,
                                      borderRadius: AppRadius.pillRadius,
                                      border: Border.all(
                                        color: AppPalette.videoScrubberTrack,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '${widget.playbackSpeed}x',
                                      style: context.text.caption.copyWith(
                                        color: AppPalette.videoControlFg,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Center 3 Buttons: [Rewind -10s on Left] | [Play/Pause] | [Forward +10s on Right] ──
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Rewind -10s (Left)
                          Semantics(
                            button: true,
                            label: 'تأخير 10 ثوانٍ',
                            child: InkWell(
                              borderRadius: AppRadius.pillRadius,
                              onTap: () {
                                _onUserInteracted();
                                widget.onSeekRelative(-10);
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppPalette.videoControlBg,
                                  borderRadius: AppRadius.pillRadius,
                                ),
                                child: Icon(
                                  Icons.replay_10_rounded,
                                  color: AppPalette.videoControlFg,
                                  size: AppIcon.lg,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpace.xl),

                          // Large Play / Pause / Buffer (Center)
                          Semantics(
                            button: true,
                            label: isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                            child: InkWell(
                              borderRadius: AppRadius.pillRadius,
                              onTap: () {
                                _onUserInteracted();
                                if (isPlaying) {
                                  widget.onUserPause?.call();
                                  widget.controller.pause();
                                } else {
                                  widget.onUserPlay?.call();
                                  widget.controller.play();
                                  _startHideTimer();
                                }
                              },
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppPalette.videoControlBg,
                                  borderRadius: AppRadius.pillRadius,
                                ),
                                child: Center(
                                  child: isBuffering
                                      ? SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor: AlwaysStoppedAnimation(
                                              AppPalette.videoScrubberActive,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: AppPalette.videoControlFg,
                                          size: AppIcon.hero,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpace.xl),

                          // Forward +10s (Right)
                          Semantics(
                            button: true,
                            label: 'تقديم 10 ثوانٍ',
                            child: InkWell(
                              borderRadius: AppRadius.pillRadius,
                              onTap: () {
                                _onUserInteracted();
                                widget.onSeekRelative(10);
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppPalette.videoControlBg,
                                  borderRadius: AppRadius.pillRadius,
                                ),
                                child: Icon(
                                  Icons.forward_10_rounded,
                                  color: AppPalette.videoControlFg,
                                  size: AppIcon.lg,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Bottom Bar: LTR Scrubber & [Time (Left) | Chapter | Fullscreen (Right)] ──
                    PositionedDirectional(
                      bottom: 0,
                      start: 0,
                      end: 0,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.md,
                            vertical: AppSpace.xs,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // YouTube Scrubber Slider (Progresses Left-to-Right)
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3.5,
                                  activeTrackColor: AppPalette.videoScrubberActive,
                                  inactiveTrackColor: AppPalette.videoScrubberTrack,
                                  thumbColor: AppPalette.videoScrubberActive,
                                  overlayColor: AppPalette.videoScrubberTrack,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6.0,
                                  ),
                                ),
                                child: Slider(
                                  value: progressFraction,
                                  onChanged: (newVal) {
                                    _cancelHideTimer();
                                    setState(() => _dragFraction = newVal);
                                  },
                                  onChangeEnd: (newVal) {
                                    final seekMs = (newVal * totalMs).round();
                                    final baseStartSec = widget.startSeconds ?? 0;
                                    final absTargetSec = baseStartSec + (seekMs ~/ 1000);
                                    widget.onSeekTo(AppMotion.fromSeconds(absTargetSec));
                                    setState(() => _dragFraction = null);
                                    _startHideTimer();
                                  },
                                ),
                              ),

                              // Meta Row: Time on Left | Active Chapter in Center | FullScreen on Right
                              Row(
                                children: [
                                  Text(
                                    '$posStr / $durStr',
                                    style: context.text.caption.copyWith(
                                      color: AppPalette.videoControlFg,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (activeChapter != null) ...[
                                    const SizedBox(width: AppSpace.sm),
                                    Expanded(
                                      child: Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Text(
                                          '• $activeChapter',
                                          style: context.text.caption.copyWith(
                                            color: AppPalette.videoScrubberActive,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    const Spacer(),
                                  ],
                                  IconButton(
                                    tooltip: widget.isFullScreen
                                        ? 'تصغير الشاشة'
                                        : 'ملء الشاشة',
                                    icon: Icon(
                                      widget.isFullScreen
                                          ? Icons.fullscreen_exit_rounded
                                          : Icons.fullscreen_rounded,
                                      color: AppPalette.videoControlFg,
                                      size: AppIcon.lg,
                                    ),
                                    onPressed: () {
                                      _onUserInteracted();
                                      widget.onToggleFullScreen();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
