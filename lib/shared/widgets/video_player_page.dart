import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_text.dart';
import 'primary_app_bar.dart';

class VideoPlayerPage extends StatefulWidget {
  final String title;
  final String videoId;

  const VideoPlayerPage({
    super.key,
    required this.title,
    required this.videoId,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final convertedVideoId =
        YoutubePlayer.convertUrlToId(widget.videoId) ?? '';

    _controller = YoutubePlayerController(
      initialVideoId: convertedVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration get _position => _controller.value.position;
  Duration get _duration => _controller.value.metaData.duration;

  double get _progressFraction {
    if (_duration.inSeconds == 0) return 0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  void _finish() {
    final watchedEnough = _progressFraction >= 0.9;
    Navigator.of(context).pop(watchedEnough);
  }

  @override
  Widget build(BuildContext context) {
    final supported = Platform.isAndroid || Platform.isIOS;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _finish();
      },
      child: Scaffold(
        appBar: UnifiedAppBar(
          title: widget.title,
          showBack: true,
          onLeadingTap: _finish,
        ),
        body: supported
            ? YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
              )
            : Center(
                child: Text(
                  AppStrings.videoUnsupported,
                  textAlign: TextAlign.center,
                  style: AppText.body,
                ),
              ),
      ),
    );
  }
}
