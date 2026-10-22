import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../app/constants/app_strings.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_ui.dart';
import '../../features/ilm/data/models/lesson_model.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'app_popup.dart';
import 'icon_badge.dart';
import 'primary_app_bar.dart';

/// Modern, YouTube-grade scholarly video player with interactive chapters,
/// section-focused playback, quick-seek controls, and playlist switcher.
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
  double _playbackSpeed = 1.0;
  bool _isLessonCompleted = false;

  @override
  void initState() {
    super.initState();
    _cleanVideoId = _extractCleanVideoId(widget.videoId);
    _resolvedPlaylistId =
        _extractPlaylistId(widget.videoId) ?? widget.playlistId;

    if (_cleanVideoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: _cleanVideoId!,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          enableCaption: true,
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

  String? _getEmbedUrl() {
    final startParam =
        widget.startSeconds != null ? '&start=${widget.startSeconds}' : '';
    final endParam =
        widget.endSeconds != null ? '&end=${widget.endSeconds}' : '';

    if (_cleanVideoId != null) {
      return 'https://www.youtube-nocookie.com/embed/$_cleanVideoId?autoplay=1&playsinline=1&rel=0$startParam$endParam';
    }
    final pid = _resolvedPlaylistId;
    if (pid != null && pid.isNotEmpty) {
      return 'https://www.youtube-nocookie.com/embed/videoseries?list=$pid&autoplay=1&playsinline=1&rel=0';
    }
    return null;
  }

  @override
  void dispose() {
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

  void _togglePlayPause() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
    HapticFeedback.selectionClick();
  }

  Future<void> _openInYouTube() async {
    final Uri targetUrl;
    final positionParam = _position.inSeconds > 0 ? '&t=${_position.inSeconds}s' : '';

    if (_cleanVideoId != null) {
      targetUrl = Uri.parse(
        'https://www.youtube.com/watch?v=$_cleanVideoId$positionParam',
      );
    } else if (_resolvedPlaylistId != null && _resolvedPlaylistId!.startsWith('PL')) {
      targetUrl = Uri.parse(
        'https://www.youtube.com/playlist?list=$_resolvedPlaylistId',
      );
    } else {
      final terms = [widget.scholar, widget.title]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(' ');
      targetUrl = Uri.parse(
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(terms)}',
      );
    }

    try {
      final launched = await launchUrl(
        targetUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(targetUrl, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      await launchUrl(targetUrl, mode: LaunchMode.platformDefault);
    }
  }

  void _showSpeedSheet() {
    final palette = context.palette;
    final speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpace.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      color: palette.gold,
                      size: AppIcon.md,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      'سرعة التشغيل',
                      style: context.text.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: speeds.map((s) {
                    final isSelected = _playbackSpeed == s;
                    return InkWell(
                      borderRadius: AppRadius.pillRadius,
                      onTap: () {
                        setState(() => _playbackSpeed = s);
                        _controller?.setPlaybackRate(s);
                        Navigator.pop(ctx);
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.lg,
                          vertical: AppSpace.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? palette.primarySoft
                              : palette.surfaceRaised,
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(
                            color: isSelected
                                ? palette.primary
                                : palette.border,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${s}x',
                          style: context.text.body.copyWith(
                            color: isSelected
                                ? palette.primary
                                : palette.text,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChaptersSheet() {
    final palette = context.palette;
    final chapters = widget.chapters ?? const [];
    if (chapters.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (_, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.border,
                          borderRadius: AppRadius.pillRadius,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Row(
                      children: [
                        Icon(
                          Icons.format_list_bulleted_rounded,
                          color: palette.gold,
                          size: AppIcon.md,
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Text(
                          'فهرس محاور وأقسام الدرس',
                          style: context.text.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${chapters.length} محاور',
                          style: context.text.caption.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: chapters.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: AppSpace.xs),
                        itemBuilder: (context, idx) {
                          final ch = chapters[idx];
                          final isActive = _position.inSeconds >=
                                  ch.startSeconds &&
                              (idx == chapters.length - 1 ||
                                  _position.inSeconds <
                                      chapters[idx + 1].startSeconds);

                          return InkWell(
                            borderRadius: AppRadius.mdRadius,
                            onTap: () {
                              _controller?.seekTo(
                                AppMotion.fromSeconds(ch.startSeconds),
                              );
                              _controller?.play();
                              Navigator.pop(ctx);
                              HapticFeedback.lightImpact();
                            },
                            child: Container(
                              padding: const EdgeInsetsDirectional.all(
                                AppSpace.sm,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? palette.primarySoft
                                    : Colors.transparent,
                                borderRadius: AppRadius.mdRadius,
                                border: Border.all(
                                  color: isActive
                                      ? palette.primary.withValues(alpha: 0.5)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsetsDirectional.symmetric(
                                      horizontal: AppSpace.sm,
                                      vertical: AppSpace.xxs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? palette.primary
                                          : palette.surface,
                                      borderRadius: AppRadius.smRadius,
                                    ),
                                    child: Text(
                                      ch.timestampFormatted,
                                      style: context.text.caption.copyWith(
                                        color: isActive
                                            ? palette.onPrimary
                                            : palette.gold,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.md),
                                  Expanded(
                                    child: Text(
                                      ch.title,
                                      style: context.text.bodySmall.copyWith(
                                        color: isActive
                                            ? palette.primary
                                            : palette.text,
                                        fontWeight: isActive
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isActive)
                                    Icon(
                                      Icons.volume_up_rounded,
                                      color: palette.primary,
                                      size: AppIcon.sm,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _formatTime(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final supported = Platform.isAndroid || Platform.isIOS;

    if (!supported) {
      return Scaffold(
        backgroundColor: palette.bg,
        appBar: UnifiedAppBar(
          title: widget.title,
          showBack: true,
          onLeadingTap: _finish,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpace.xl),
            child: Text(
              AppStrings.videoUnsupported,
              textAlign: TextAlign.center,
              style: context.text.body.copyWith(color: palette.textMuted),
            ),
          ),
        ),
      );
    }

    final canUseNativePlayer =
        _cleanVideoId != null && _controller != null && !_hasPlayerError;

    if (canUseNativePlayer) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: palette.gold,
          bottomActions: const [
            CurrentPosition(),
            ProgressBar(isExpanded: true),
            RemainingDuration(),
            PlaybackSpeedButton(),
            FullScreenButton(),
          ],
        ),
        builder: (context, player) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              _finish();
            },
            child: Scaffold(
              backgroundColor: palette.bg,
              appBar: UnifiedAppBar(
                title: widget.title,
                showBack: true,
                onLeadingTap: _finish,
                actions: [
                  IconButton(
                    tooltip: 'سرعة التشغيل',
                    icon: Icon(
                      Icons.speed_rounded,
                      color: palette.text,
                      size: AppIcon.md,
                    ),
                    onPressed: _showSpeedSheet,
                  ),
                  IconButton(
                    tooltip: 'فتح في تطبيق يوتيوب',
                    icon: Icon(
                      Icons.open_in_new_rounded,
                      color: palette.text,
                      size: AppIcon.md,
                    ),
                    onPressed: _openInYouTube,
                  ),
                ],
              ),
              body: Column(
                children: [
                  player,
                  _buildModernPlayerStrip(context),
                  Expanded(
                    child: _buildLessonDetails(context),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    final embedUrl = _getEmbedUrl();
    if (embedUrl != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _finish();
        },
        child: Scaffold(
          backgroundColor: palette.bg,
          appBar: UnifiedAppBar(
            title: widget.title,
            showBack: true,
            onLeadingTap: _finish,
            actions: [
              IconButton(
                tooltip: 'فتح في تطبيق يوتيوب',
                icon: Icon(
                  Icons.open_in_new_rounded,
                  color: palette.text,
                  size: AppIcon.md,
                ),
                onPressed: _openInYouTube,
              ),
            ],
          ),
          body: Column(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(embedUrl),
                    headers: {
                      'Referer': 'https://www.youtube.com/',
                    },
                  ),
                  initialSettings: InAppWebViewSettings(
                    allowsInlineMediaPlayback: true,
                    mediaPlaybackRequiresUserGesture: false,
                    javaScriptEnabled: true,
                    transparentBackground: true,
                    supportZoom: false,
                    userAgent:
                        'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                  ),
                ),
              ),
              Expanded(
                child: _buildLessonDetails(context),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _finish();
      },
      child: Scaffold(
        backgroundColor: palette.bg,
        appBar: UnifiedAppBar(
          title: widget.title,
          showBack: true,
          onLeadingTap: _finish,
        ),
        body: _buildFallbackView(context),
      ),
    );
  }

  /// Modern player toolbar strip below the video container
  Widget _buildModernPlayerStrip(BuildContext context) {
    final palette = context.palette;
    final isPlaying = _controller?.value.isPlaying ?? false;
    final posStr = _formatTime(_sectionPosition);
    final durStr = _formatTime(_sectionDuration);

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        border: Border(
          bottom: BorderSide(color: palette.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Rewind 10s
          IconButton(
            tooltip: 'تأخير 10 ثوانٍ',
            icon: Icon(
              Icons.replay_10_rounded,
              color: palette.text,
              size: AppIcon.md,
            ),
            onPressed: () => _seekRelative(-10),
          ),
          // Play / Pause
          IconButton(
            tooltip: isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
            icon: Icon(
              isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              color: palette.primary,
              size: AppIcon.lg,
            ),
            onPressed: _togglePlayPause,
          ),
          // Forward 10s
          IconButton(
            tooltip: 'تقديم 10 ثوانٍ',
            icon: Icon(
              Icons.forward_10_rounded,
              color: palette.text,
              size: AppIcon.md,
            ),
            onPressed: () => _seekRelative(10),
          ),
          const SizedBox(width: AppSpace.xs),
          // Time Position / Section Duration
          Expanded(
            child: Text(
              '$posStr / $durStr',
              style: context.text.caption.copyWith(
                color: palette.textMuted,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Chapters Trigger
          if (widget.chapters != null && widget.chapters!.isNotEmpty) ...[
            InkWell(
              borderRadius: AppRadius.pillRadius,
              onTap: _showChaptersSheet,
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xxs,
                ),
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.format_list_bulleted_rounded,
                      color: palette.gold,
                      size: AppIcon.xs,
                    ),
                    const SizedBox(width: AppSpace.xxs),
                    Text(
                      'المحاور',
                      style: context.text.caption.copyWith(
                        color: palette.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpace.xs),
          ],
          // Speed Pill
          InkWell(
            borderRadius: AppRadius.pillRadius,
            onTap: _showSpeedSheet,
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.sm,
                vertical: AppSpace.xxs,
              ),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadius.pillRadius,
                border: Border.all(color: palette.border, width: 1),
              ),
              child: Text(
                '${_playbackSpeed}x',
                style: context.text.caption.copyWith(
                  color: palette.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
          // ── Title & Segment Badge ──
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

                    return InkWell(
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

    return Center(
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
                style: textTheme.title.copyWith(
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
    );
  }
}
