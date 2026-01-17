import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';

/// Repeat mode for audio playback
enum AudioRepeatMode { off, verse, page, surah }

/// Audio playback state
class AudioPlaybackState {
  final bool isPlaying;
  final bool isLoading;
  final Duration currentPosition;
  final Duration totalDuration;
  final double playbackSpeed;
  final AudioRepeatMode repeatMode;
  final String reciterName;
  final String reciterImage;
  final int currentVerse;
  final String surahName;

  const AudioPlaybackState({
    this.isPlaying = false,
    this.isLoading = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = const Duration(seconds: 60),
    this.playbackSpeed = 1.0,
    this.repeatMode = AudioRepeatMode.off,
    this.reciterName = 'مشاري العفاسي',
    this.reciterImage = '',
    this.currentVerse = 1,
    this.surahName = 'الفاتحة',
  });

  AudioPlaybackState copyWith({
    bool? isPlaying,
    bool? isLoading,
    Duration? currentPosition,
    Duration? totalDuration,
    double? playbackSpeed,
    AudioRepeatMode? repeatMode,
    String? reciterName,
    String? reciterImage,
    int? currentVerse,
    String? surahName,
  }) {
    return AudioPlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      repeatMode: repeatMode ?? this.repeatMode,
      reciterName: reciterName ?? this.reciterName,
      reciterImage: reciterImage ?? this.reciterImage,
      currentVerse: currentVerse ?? this.currentVerse,
      surahName: surahName ?? this.surahName,
    );
  }
}

/// Audio player widget for Quran reading
class QuranAudioPlayer extends StatefulWidget {
  final AudioPlaybackState state;
  final bool nightMode;
  final VoidCallback? onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<double>? onSeek;
  final ValueChanged<double>? onSpeedChange;
  final ValueChanged<AudioRepeatMode>? onRepeatModeChange;

  const QuranAudioPlayer({
    super.key,
    required this.state,
    this.nightMode = false,
    this.onPlayPause,
    this.onPrevious,
    this.onNext,
    this.onSeek,
    this.onSpeedChange,
    this.onRepeatModeChange,
  });

  @override
  State<QuranAudioPlayer> createState() => _QuranAudioPlayerState();
}

class _QuranAudioPlayerState extends State<QuranAudioPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _playPauseController;

  @override
  void initState() {
    super.initState();
    _playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    if (widget.state.isPlaying) {
      _playPauseController.forward();
    }
  }

  @override
  void didUpdateWidget(QuranAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.isPlaying != oldWidget.state.isPlaying) {
      if (widget.state.isPlaying) {
        _playPauseController.forward();
      } else {
        _playPauseController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _playPauseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showSpeedOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SpeedOptionsSheet(
        currentSpeed: widget.state.playbackSpeed,
        nightMode: widget.nightMode,
        onSpeedSelected: (speed) {
          widget.onSpeedChange?.call(speed);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _cycleRepeatMode() {
    final modes = AudioRepeatMode.values;
    final currentIndex = modes.indexOf(widget.state.repeatMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    widget.onRepeatModeChange?.call(modes[nextIndex]);
  }

  IconData _getRepeatIcon() {
    switch (widget.state.repeatMode) {
      case AudioRepeatMode.off:
        return Icons.repeat;
      case AudioRepeatMode.verse:
        return Icons.repeat_one;
      case AudioRepeatMode.page:
        return Icons.repeat;
      case AudioRepeatMode.surah:
        return Icons.repeat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final isDark = widget.nightMode;
    final state = widget.state;

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF14B8A6).withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress slider
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFF14B8A6),
                    inactiveTrackColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade200,
                    thumbColor: const Color(0xFF14B8A6),
                    overlayColor: const Color(
                      0xFF14B8A6,
                    ).withValues(alpha: 0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                  ),
                  child: Slider(
                    value: state.currentPosition.inSeconds.toDouble(),
                    min: 0,
                    max: state.totalDuration.inSeconds.toDouble(),
                    onChanged: (value) {
                      widget.onSeek?.call(value);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(state.currentPosition),
                        style: TextStyle(
                          fontSize: responsive.sp(11),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        _formatDuration(state.totalDuration),
                        style: TextStyle(
                          fontSize: responsive.sp(11),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main controls row
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Reciter image
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF14B8A6),
                        width: 2,
                      ),
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: isDark ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Now playing info
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.reciterName,
                          style: TextStyle(
                            fontSize: responsive.sp(12),
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.grey.shade600,
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${state.surahName} - آية ${state.currentVerse}',
                          style: TextStyle(
                            fontSize: responsive.sp(14),
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Repeat mode button
                  IconButton(
                    onPressed: _cycleRepeatMode,
                    icon: Icon(
                      _getRepeatIcon(),
                      size: 22,
                      color: state.repeatMode != AudioRepeatMode.off
                          ? const Color(0xFF14B8A6)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.grey.shade400),
                    ),
                  ),

                  // Previous verse
                  IconButton(
                    onPressed: widget.onPrevious,
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      size: 28,
                      color: isDark ? Colors.white : Colors.grey.shade700,
                    ),
                  ),

                  // Play/Pause button
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onPlayPause,
                        borderRadius: BorderRadius.circular(28),
                        child: Center(
                          child: state.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : AnimatedIcon(
                                  icon: AnimatedIcons.play_pause,
                                  progress: _playPauseController,
                                  size: 32,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ),

                  // Next verse
                  IconButton(
                    onPressed: widget.onNext,
                    icon: Icon(
                      Icons.skip_next_rounded,
                      size: 28,
                      color: isDark ? Colors.white : Colors.grey.shade700,
                    ),
                  ),

                  // Speed button
                  GestureDetector(
                    onTap: _showSpeedOptions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${state.playbackSpeed}x',
                        style: TextStyle(
                          fontSize: responsive.sp(12),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF14B8A6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Speed options bottom sheet
class _SpeedOptionsSheet extends StatelessWidget {
  final double currentSpeed;
  final bool nightMode;
  final ValueChanged<double> onSpeedSelected;

  const _SpeedOptionsSheet({
    required this.currentSpeed,
    required this.nightMode,
    required this.onSpeedSelected,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: nightMode ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'سرعة التشغيل',
            style: TextStyle(
              fontSize: responsive.sp(18),
              fontWeight: FontWeight.w700,
              color: nightMode ? Colors.white : Colors.grey.shade800,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: speeds.map((speed) {
              final isSelected = speed == currentSpeed;
              return GestureDetector(
                onTap: () => onSpeedSelected(speed),
                child: Container(
                  width: 70,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF14B8A6)
                        : (nightMode
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF14B8A6)
                          : (nightMode
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.shade200),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${speed}x',
                      style: TextStyle(
                        fontSize: responsive.sp(14),
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (nightMode ? Colors.white : Colors.grey.shade700),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }
}

/// Mini audio player (collapsed version)
class MiniAudioPlayer extends StatelessWidget {
  final AudioPlaybackState state;
  final bool nightMode;
  final VoidCallback? onPlayPause;
  final VoidCallback? onExpand;

  const MiniAudioPlayer({
    super.key,
    required this.state,
    this.nightMode = false,
    this.onPlayPause,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final isDark = nightMode;

    return GestureDetector(
      onTap: onExpand,
      child: Container(
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Progress indicator
            Container(
              width: 4,
              height: 40,
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.bottomCenter,
                heightFactor: state.totalDuration.inSeconds > 0
                    ? state.currentPosition.inSeconds /
                          state.totalDuration.inSeconds
                    : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${state.surahName} - آية ${state.currentVerse}',
                    style: TextStyle(
                      fontSize: responsive.sp(13),
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    state.reciterName,
                    style: TextStyle(
                      fontSize: responsive.sp(11),
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.grey.shade500,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Play/Pause
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: onPlayPause,
                icon: Icon(
                  state.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
