import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../app/constants/app_strings.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../features/ilm/data/models/lesson_model.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'app_popup.dart';
import 'icon_badge.dart';
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

  @override
  void initState() {
    super.initState();
    _resolvedPlaylistId = _extractPlaylistId(widget.videoId) ?? widget.playlistId;

    // Resolve clean playable video ID
    String? rawId = widget.videoId;
    if (rawId.startsWith('PL') && widget.playlistLessons != null && widget.playlistLessons!.isNotEmpty) {
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
        ),
      )..addListener(_onPlayerStateChanged);
    }
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    if (_controller?.value.hasError == true && !_hasPlayerError) {
      setState(() => _hasPlayerError = true);
    }

    // Ensure initial seek for segmented lessons
    if (!_initialSeekDone &&
        widget.startSeconds != null &&
        widget.startSeconds! > 0 &&
        _controller?.value.isReady == true) {
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
      urlsToTry.add('https://www.youtube.com/watch?v=$_cleanVideoId$startParam');
      urlsToTry.add('vnd.youtube:$_cleanVideoId');
    }
    if (_resolvedPlaylistId != null) {
      urlsToTry.add('https://www.youtube.com/playlist?list=$_resolvedPlaylistId');
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
      return _buildFallbackView(context);
    }

    final playerWithOverlay = Stack(
      fit: StackFit.expand,
      children: [
        YoutubePlayer(
          controller: _controller!,
          aspectRatio: isLandscape ? MediaQuery.sizeOf(context).aspectRatio : 16 / 9,
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
                      child: _buildLessonDetails(context),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLessonDetails(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final isSegmented = widget.startSeconds != null;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Title ──
          Text(
            widget.title,
            style: textTheme.titleSmall.copyWith(
              color: palette.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpace.sm),

          // ── Scholar & Meta Row ──
          Row(
            children: [
              IconBadge(
                icon: Icons.school_rounded,
                bg: palette.primarySoft,
                fg: palette.primary,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.scholar ?? 'شرح المتن العلمي',
                            style: textTheme.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: palette.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Icon(
                          Icons.verified_rounded,
                          size: AppIcon.xs,
                          color: palette.gold,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      isSegmented
                          ? 'مقطع دراسي مركّز (${_formatTime(_sectionDuration)})'
                          : 'المدة الإجمالية: ${_formatTime(_sectionDuration)}',
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpace.lg),

          // ── Action Buttons Row ──
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: _isLessonCompleted
                      ? 'تم إنجاز الدرس ✓'
                      : 'تحديد الدرس كمكتمل',
                  icon: _isLessonCompleted
                      ? Icons.check_circle_rounded
                      : Icons.check_circle_outline_rounded,
                  size: AppButtonSize.md,
                  variant: _isLessonCompleted
                      ? AppButtonVariant.tonal
                      : AppButtonVariant.primary,
                  onPressed: () {
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
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              IconButton.filledTonal(
                tooltip: 'فتح في تطبيق يوتيوب',
                icon: Icon(
                  Icons.open_in_new_rounded,
                  size: AppIcon.md,
                  color: palette.text,
                ),
                onPressed: _openInYouTube,
              ),
            ],
          ),

          // ── Interactive Chapters Card ──
          if (widget.chapters != null && widget.chapters!.isNotEmpty) ...[
            const SizedBox(height: AppSpace.lg),
            AppCard(
              padding: const EdgeInsetsDirectional.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.segment_rounded,
                        color: palette.gold,
                        size: AppIcon.sm,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        'محاور وموضوعات المقطع',
                        style: textTheme.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _showChaptersSheet,
                        child: Text(
                          'عرض الكل',
                          style: textTheme.caption.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  ...widget.chapters!.take(4).map((ch) {
                    final isCurrentChapter = _position.inSeconds >=
                            ch.startSeconds &&
                        (ch.endSeconds == null ||
                            _position.inSeconds < ch.endSeconds!);

                    return Semantics(
                      button: true,
                      label: '${ch.title} عند ${ch.timestampFormatted}',
                      child: InkWell(
                        borderRadius: AppRadius.smRadius,
                        onTap: () {
                          _controller?.seekTo(
                            AppMotion.fromSeconds(ch.startSeconds),
                          );
                          _controller?.play();
                          HapticFeedback.lightImpact();
                        },
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            vertical: AppSpace.xs,
                            horizontal: AppSpace.xs,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpace.xs,
                                  vertical: AppSpace.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrentChapter
                                      ? palette.goldSoft
                                      : palette.surfaceRaised,
                                  borderRadius: AppRadius.smRadius,
                                ),
                                child: Text(
                                  ch.timestampFormatted,
                                  style: textTheme.caption.copyWith(
                                    color: isCurrentChapter
                                        ? palette.gold
                                        : palette.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Expanded(
                                child: Text(
                                  ch.title,
                                  style: textTheme.bodySmall.copyWith(
                                    color: isCurrentChapter
                                        ? palette.primary
                                        : palette.text,
                                    fontWeight: isCurrentChapter
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCurrentChapter)
                                Icon(
                                  Icons.play_arrow_rounded,
                                  size: AppIcon.xs,
                                  color: palette.primary,
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
          ],

          // ── Next Lessons in Playlist ──
          if (widget.playlistLessons != null &&
              widget.playlistLessons!.length > 1) ...[
            const SizedBox(height: AppSpace.lg),
            Text(
              'الدروس التالية في هذا المتن',
              style: textTheme.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            ...widget.playlistLessons!
                .where((l) => l.index != widget.currentLessonIndex)
                .take(3)
                .map((nextLesson) {
              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: AppSpace.xs),
                child: AppCard(
                  onTap: () {
                    if (widget.onLessonSelected != null) {
                      widget.onLessonSelected!(nextLesson.index);
                    }
                  },
                  padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: palette.surfaceRaised,
                          borderRadius: AppRadius.smRadius,
                        ),
                        child: Center(
                          child: Text(
                            '${nextLesson.index + 1}',
                            style: textTheme.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: palette.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextLesson.title,
                              style: textTheme.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${nextLesson.durationMinutes} دقيقة',
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.play_circle_outline_rounded,
                        color: palette.primary,
                        size: AppIcon.md,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildFallbackView(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          tooltip: 'رجوع',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.all(AppSpace.xl),
          child: Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.xl),
            decoration: BoxDecoration(
              color: palette.surfaceRaised,
              borderRadius: AppRadius.lgRadius,
              border: Border.all(color: palette.border, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: palette.goldSoft,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Icon(
                    Icons.play_circle_filled_rounded,
                    color: palette.gold,
                    size: AppIcon.xl,
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.scholar != null && widget.scholar!.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    widget.scholar!,
                    textAlign: TextAlign.center,
                    style: textTheme.caption.copyWith(
                      color: palette.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.md),
                Text(
                  'هذا الدرس متاح للمشاهدة المباشرة عبر تطبيق يوتيوب ضمن السلسلة العلمية المعتمدة.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall.copyWith(
                    color: palette.textMuted,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                AppButton(
                  label: 'فتح ومشاهدة الدرس في يوتيوب',
                  icon: Icons.open_in_new_rounded,
                  size: AppButtonSize.md,
                  onPressed: _openInYouTube,
                ),
                const SizedBox(height: AppSpace.sm),
                AppButton(
                  label: 'تحديد الدرس كمكتمل',
                  variant: AppButtonVariant.tonal,
                  icon: Icons.check_circle_outline_rounded,
                  size: AppButtonSize.md,
                  onPressed: () => _finish(true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
}
