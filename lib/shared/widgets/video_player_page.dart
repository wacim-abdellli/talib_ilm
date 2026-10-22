import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../app/constants/app_strings.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../features/ilm/data/models/lesson_model.dart';
import '../../features/ilm/data/services/mutun_audio_service.dart';
import 'app_popup.dart';
import 'video_player_details.dart';
import 'video_player_overlay.dart';
import 'video_player_sheets.dart';

/// Fullscreen YouTube-grade video player with chapters, speed control, and sectioning.
class VideoPlayerPage extends StatefulWidget {
  final String title;
  final String videoId;
  final String? scholar;
  final String? playlistId;
  final int? startSeconds;
  final int? endSeconds;
  final List<LessonChapter>? chapters;
  final List<Lesson>? playlistLessons;
  final int? currentLessonIndex;
  final ValueChanged<int>? onLessonSelected;

  const VideoPlayerPage({
    super.key,
    required this.title,
    required this.videoId,
    this.scholar,
    this.playlistId,
    this.startSeconds,
    this.endSeconds,
    this.chapters,
    this.playlistLessons,
    this.currentLessonIndex,
    this.onLessonSelected,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  YoutubePlayerController? _controller;
  String? _cleanVideoId;
  String? _resolvedPlaylistId;
  bool _hasPlayerError = false;
  bool _initialSeekDone = false;
  bool _isFullScreen = false;
  double _playbackSpeed = 1.0;
  bool _isLessonCompleted = false;

  // Autoplay reliability & user pause tracking
  bool _userPaused = false;
  int _autoResumeAttempts = 0;
  Timer? _autoResumeTimer;
  final GlobalKey _playerGlobalKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Pause any ongoing recitation audio to avoid audio focus collision
    try {
      MutunAudioService().pause();
    } catch (_) {}

    _resolvedPlaylistId =
        _extractPlaylistId(widget.videoId) ?? widget.playlistId;

    // Resolve clean playable video ID
    String? rawId = widget.videoId;
    if (rawId.startsWith('PL') &&
        widget.playlistLessons != null &&
        widget.playlistLessons!.isNotEmpty) {
      rawId = widget.playlistLessons!.first.videoId;
    }
    _cleanVideoId = _extractCleanVideoId(rawId);

    if (_cleanVideoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: _cleanVideoId!,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          hideControls: true, // We provide authentic YouTube overlay
          enableCaption: false,
          startAt: widget.startSeconds ?? 0,
          endAt: widget.endSeconds,
          useHybridComposition: true,
        ),
      )..addListener(_onPlayerStateChanged);
    }
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    if (_controller?.value.hasError == true && !_hasPlayerError) {
      setState(() => _hasPlayerError = true);
    }

    final state = _controller?.value.playerState;
    final isPlaying = _controller?.value.isPlaying == true;

    // Reset auto-resume counter once video is playing normally
    if (isPlaying) {
      _autoResumeAttempts = 0;
      _autoResumeTimer?.cancel();
    }

    // Auto-recovery watchdog:
    // If the video stops/pauses unexpectedly during initial startup (e.g. mobile WebView
    // autoplay policy interception or initial buffering glitch) without the user pressing pause,
    // automatically resume playback seamlessly.
    if (state == PlayerState.paused &&
        !_userPaused &&
        _autoResumeAttempts < 3 &&
        mounted) {
      _autoResumeAttempts++;
      _autoResumeTimer?.cancel();
      _autoResumeTimer = Timer(AppMotion.searchDebounce, () {
        if (mounted && !_userPaused && _controller?.value.isPlaying == false) {
          _controller?.play();
        }
      });
    }

    // Fallback sync: if startSeconds is configured but iframe played from 0, align once
    if (!_initialSeekDone &&
        widget.startSeconds != null &&
        widget.startSeconds! > 0 &&
        isPlaying &&
        _position.inSeconds < widget.startSeconds! - 3) {
      _initialSeekDone = true;
      _controller?.seekTo(AppMotion.fromSeconds(widget.startSeconds!));
    }

    setState(() {});
  }

  static String? _extractCleanVideoId(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.startsWith('PL') || trimmed.length > 25) {
      return null;
    }
    final converted = YoutubePlayer.convertUrlToId(trimmed);
    if (converted != null && converted.length == 11) {
      return converted;
    }
    if (trimmed.length == 11 &&
        RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(trimmed)) {
      return trimmed;
    }
    return null;
  }

  static String? _extractPlaylistId(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('PL')) {
      return trimmed;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.queryParameters.containsKey('list')) {
      return uri.queryParameters['list'];
    }
    return null;
  }

  @override
  void dispose() {
    _autoResumeTimer?.cancel();
    // Restore orientations and system bars
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _controller?.removeListener(_onPlayerStateChanged);
    _controller?.dispose();
    super.dispose();
  }

  Duration get _position => _controller?.value.position ?? Duration.zero;
  Duration get _duration =>
      _controller?.value.metaData.duration ?? Duration.zero;

  Duration get _sectionDuration {
    if (widget.startSeconds != null && widget.endSeconds != null) {
      return AppMotion.fromSeconds(widget.endSeconds! - widget.startSeconds!);
    }
    return _duration;
  }

  Duration get _sectionPosition {
    if (widget.startSeconds != null) {
      final pos = _position.inSeconds - widget.startSeconds!;
      return AppMotion.fromSeconds(pos.clamp(0, _sectionDuration.inSeconds));
    }
    return _position;
  }

  double get _progressFraction {
    final total = _sectionDuration.inMilliseconds;
    if (total == 0) return 0;
    return (_sectionPosition.inMilliseconds / total).clamp(0.0, 1.0);
  }

  void _finish([bool? forceCompleted]) {
    final watchedEnough =
        forceCompleted ?? (_isLessonCompleted || _progressFraction >= 0.85);
    Navigator.of(context).pop(watchedEnough);
  }

  void _onBackPressed() {
    if (_isFullScreen) {
      _toggleFullScreen();
    } else {
      _finish();
    }
  }

  void _toggleFullScreen() {
    setState(() => _isFullScreen = !_isFullScreen);
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _seekRelative(int seconds) {
    final current = _position;
    final minTime = widget.startSeconds != null
        ? AppMotion.fromSeconds(widget.startSeconds!)
        : Duration.zero;
    final maxTime = widget.endSeconds != null
        ? AppMotion.fromSeconds(widget.endSeconds!)
        : _duration;

    final target = current + AppMotion.fromSeconds(seconds);
    final clamped = target < minTime
        ? minTime
        : (maxTime > Duration.zero && target > maxTime ? maxTime : target);

    _controller?.seekTo(clamped);
    HapticFeedback.selectionClick();
  }

  Future<void> _openInYouTube() async {
    final currentPosSec = _position.inSeconds;
    final startParam = currentPosSec > 0 ? '&t=${currentPosSec}s' : '';

    final urlsToTry = <String>[];
    if (_cleanVideoId != null) {
      urlsToTry
          .add('https://www.youtube.com/watch?v=$_cleanVideoId$startParam');
      urlsToTry.add('vnd.youtube:$_cleanVideoId');
    }
    if (_resolvedPlaylistId != null) {
      urlsToTry
          .add('https://www.youtube.com/playlist?list=$_resolvedPlaylistId');
    }

    for (final urlStr in urlsToTry) {
      final uri = Uri.parse(urlStr);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }

    if (mounted) {
      AppPopup.show(
        context: context,
        title: 'تنبيه',
        message: 'تعذر فتح الرابط في تطبيق يوتيوب',
      );
    }
  }

  void _showSpeedSheet() {
    VideoPlayerSheets.showSpeedSheet(
      context,
      currentSpeed: _playbackSpeed,
      onSpeedChanged: (speed) {
        setState(() => _playbackSpeed = speed);
        _controller?.setPlaybackRate(speed);
      },
    );
  }

  void _showChaptersSheet() {
    if (widget.chapters == null || widget.chapters!.isEmpty) return;
    VideoPlayerSheets.showChaptersSheet(
      context,
      chapters: widget.chapters!,
      currentSeconds: _position.inSeconds,
      onChapterSelected: (startSec) {
        _controller?.seekTo(AppMotion.fromSeconds(startSec));
        _controller?.play();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final orientation = MediaQuery.orientationOf(context);
    final isLandscape = orientation == Orientation.landscape || _isFullScreen;

    final canUseNativePlayer =
        _cleanVideoId != null && _controller != null && !_hasPlayerError;

    if (!canUseNativePlayer) {
      return VideoPlayerFallbackView(
        title: widget.title,
        scholar: widget.scholar,
        onOpenInYouTube: _openInYouTube,
        onComplete: () => _finish(true),
      );
    }

    final playerWithOverlay = Stack(
      fit: StackFit.expand,
      children: [
        KeyedSubtree(
          key: _playerGlobalKey,
          child: YoutubePlayer(
            controller: _controller!,
            aspectRatio:
                isLandscape ? MediaQuery.sizeOf(context).aspectRatio : 16 / 9,
          ),
        ),
        VideoPlayerOverlay(
          controller: _controller!,
          title: widget.title,
          position: _sectionPosition,
          duration: _sectionDuration,
          startSeconds: widget.startSeconds,
          endSeconds: widget.endSeconds,
          chapters: widget.chapters,
          isFullScreen: isLandscape,
          playbackSpeed: _playbackSpeed,
          onToggleFullScreen: _toggleFullScreen,
          onBack: _onBackPressed,
          onOpenSpeedSheet: _showSpeedSheet,
          onOpenChaptersSheet: _showChaptersSheet,
          onSeekRelative: _seekRelative,
          onSeekTo: (target) => _controller?.seekTo(target),
          onUserPlay: () {
            setState(() {
              _userPaused = false;
              _autoResumeAttempts = 0;
            });
          },
          onUserPause: () {
            _autoResumeTimer?.cancel();
            setState(() {
              _userPaused = true;
            });
          },
        ),
      ],
    );

    return PopScope(
      canPop: !isLandscape,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: isLandscape ? AppPalette.light.bg : palette.bg,
        body: isLandscape
            ? SizedBox.expand(child: playerWithOverlay)
            : SafeArea(
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: playerWithOverlay,
                    ),
                    Expanded(
                      child: LessonDetailsSection(
                        title: widget.title,
                        scholar: widget.scholar,
                        startSeconds: widget.startSeconds,
                        sectionDuration: _sectionDuration,
                        position: _position,
                        chapters: widget.chapters,
                        playlistLessons: widget.playlistLessons,
                        currentLessonIndex: widget.currentLessonIndex,
                        isLessonCompleted: _isLessonCompleted,
                        onToggleCompleted: () {
                          setState(
                            () => _isLessonCompleted = !_isLessonCompleted,
                          );
                          HapticFeedback.selectionClick();
                          if (_isLessonCompleted) {
                            AppPopup.show(
                              context: context,
                              title: 'تم تحديد الدرس',
                              message: AppStrings.lessonProgressSaved,
                              icon: Icons.check_circle_rounded,
                            );
                          }
                        },
                        onOpenInYouTube: _openInYouTube,
                        onShowChaptersSheet: _showChaptersSheet,
                        onChapterSelected: (startSec) {
                          _controller?.seekTo(AppMotion.fromSeconds(startSec));
                          _controller?.play();
                          HapticFeedback.lightImpact();
                        },
                        onLessonSelected: widget.onLessonSelected,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
