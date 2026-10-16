import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../app/constants/app_strings.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_ui.dart';
import 'app_button.dart';
import 'primary_app_bar.dart';

/// Bulletproof scholarly YouTube video and playlist player page.
/// Plays videos and playlists directly inside the app with seamless native & webview support.
class VideoPlayerPage extends StatefulWidget {
  final String title;
  final String videoId;
  final String? scholar;
  final String? playlistId;

  const VideoPlayerPage({
    super.key,
    required this.title,
    required this.videoId,
    this.scholar,
    this.playlistId,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  YoutubePlayerController? _controller;
  String? _cleanVideoId;
  String? _resolvedPlaylistId;
  bool _hasPlayerError = false;

  @override
  void initState() {
    super.initState();
    _cleanVideoId = _extractCleanVideoId(widget.videoId);
    _resolvedPlaylistId =
        _extractPlaylistId(widget.videoId) ?? widget.playlistId;

    if (_cleanVideoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: _cleanVideoId!,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          enableCaption: true,
        ),
      )..addListener(_onPlayerStateChanged);
    }
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    if (_controller?.value.hasError == true && !_hasPlayerError) {
      setState(() {
        _hasPlayerError = true;
      });
    }
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
    if (_cleanVideoId != null) {
      return 'https://www.youtube-nocookie.com/embed/$_cleanVideoId?autoplay=1&playsinline=1&rel=0';
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

  double get _progressFraction {
    if (_duration.inSeconds == 0) return 0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  void _finish([bool? forceCompleted]) {
    final watchedEnough = forceCompleted ?? (_progressFraction >= 0.85);
    Navigator.of(context).pop(watchedEnough);
  }

  Future<void> _openInYouTube() async {
    final Uri targetUrl;
    final bool isRealPlaylist = _resolvedPlaylistId != null &&
        _resolvedPlaylistId!.startsWith('PL') &&
        !RegExp(r'1a2b|2b3c|3c4d|4d5e|5e6f|6f7g|7g8h|8h9i|9i0j|0j1k|1k2l|2w3x|3x4y|9z8y|k1l2|m8n9|xO2k|cRz3|vK2h|jFh_')
            .hasMatch(_resolvedPlaylistId!);

    if (_cleanVideoId != null) {
      targetUrl = Uri.parse('https://www.youtube.com/watch?v=$_cleanVideoId');
    } else if (isRealPlaylist) {
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
                  ),
                  initialSettings: InAppWebViewSettings(
                    allowsInlineMediaPlayback: true,
                    mediaPlaybackRequiresUserGesture: false,
                    javaScriptEnabled: true,
                    transparentBackground: true,
                    supportZoom: false,
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

  Widget _buildLessonDetails(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: textTheme.titleSmall.copyWith(
              color: palette.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.scholar != null && widget.scholar!.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: AppIcon.sm,
                  color: palette.gold,
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    widget.scholar!,
                    style: textTheme.caption.copyWith(
                      color: palette.gold,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          AppButton(
            label: 'تحديد الدرس كمكتمل',
            icon: Icons.check_circle_outline_rounded,
            size: AppButtonSize.md,
            onPressed: () => _finish(true),
          ),
          const SizedBox(height: AppSpace.sm),
          AppButton(
            label: 'فتح في تطبيق يوتيوب',
            variant: AppButtonVariant.tonal,
            icon: Icons.open_in_new_rounded,
            size: AppButtonSize.md,
            onPressed: _openInYouTube,
          ),
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
