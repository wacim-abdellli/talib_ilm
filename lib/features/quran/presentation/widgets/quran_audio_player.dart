import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
// unused import removed
import '../../data/models/quran_models.dart';

class QuranAudioPlayer extends StatefulWidget {
  final Ayah ayah;
  final String surahName;
  final String reciterId; // e.g. "ar.alafasy"
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const QuranAudioPlayer({
    super.key,
    required this.ayah,
    required this.surahName,
    required this.reciterId,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<QuranAudioPlayer> createState() => _QuranAudioPlayerState();
}

class _QuranAudioPlayerState extends State<QuranAudioPlayer>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;
  bool _isMinimized = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _setupPlayerListeners();
    _loadAudio();
  }

  @override
  void didUpdateWidget(QuranAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ayah.number != widget.ayah.number ||
        oldWidget.reciterId != widget.reciterId) {
      _loadAudio();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _setupPlayerListeners() {
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            widget.onNext();
          }
        });
      }
    });

    _player.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d ?? Duration.zero);
    });

    _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  Future<void> _loadAudio() async {
    setState(() => _isLoading = true);
    try {
      String reciter = widget.reciterId;
      if (!reciter.contains('.')) {
        reciter = 'ar.alafasy'; // Default fallback
      }

      final url =
          'https://cdn.alquran.cloud/media/audio/ayah/$reciter/${widget.ayah.number}';
      await _player.setUrl(url);

      if (_isPlaying) {
        // Auto-play if already playing
        await _player.play();
      } else {
        await _player.play(); // Auto-play on load as requested conceptually
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isMinimized) {
      return _buildMiniPlayer();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // responsive removed

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height:
          220 +
          MediaQuery.of(
            context,
          ).padding.bottom, // Increased height for vertical layout
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Drag Handle
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _isMinimized = true),
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // TOP ROW: Reciter Info & Options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Reciter Info
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: const DecorationImage(
                                image: AssetImage(
                                  'assets/images/reciter_placeholder.png',
                                ), // Ideally real image
                                fit: BoxFit.cover,
                              ),
                              color: isDark
                                  ? const Color(0xFF333333)
                                  : Colors.grey[200],
                              border: Border.all(
                                color: const Color(
                                  0xFF14B8A6,
                                ).withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.grey,
                            ), // Fallback
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getReciterName(widget.reciterId),
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'سورة ${widget.surahName}',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Options (Speed/More)
                    Row(
                      children: [
                        _buildOptionIconButton(Icons.speed, isDark, "1.0x"),
                        const SizedBox(width: 8),
                        _buildOptionIconButton(Icons.more_horiz, isDark, null),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // MIDDLE ROW: Player Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {}, // Shuffle/Repeat
                      icon: Icon(
                        Icons.shuffle,
                        color: isDark ? Colors.white38 : Colors.grey[400],
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.skip_next_rounded,
                        size: 32,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      onPressed: widget.onPrevious, // RTL
                    ),
                    const SizedBox(width: 24),
                    _buildPlayButton(),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: Icon(
                        Icons.skip_previous_rounded,
                        size: 32,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      onPressed: widget.onNext,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {}, // Like/Bookmark
                      icon: Icon(
                        Icons.favorite_border,
                        color: isDark ? Colors.white38 : Colors.grey[400],
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // BOTTOM ROW: Progress
                Column(
                  children: [
                    SizedBox(
                      height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _duration.inMilliseconds > 0
                              ? _position.inMilliseconds /
                                    _duration.inMilliseconds
                              : 0,
                          backgroundColor: isDark
                              ? Colors.white10
                              : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF14B8A6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF94A3B8),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF94A3B8),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getReciterName(String id) {
    const names = {
      'ar.alafasy': 'مشاري العفاسي',
      'ar.minshawi': 'محمد صديق المنشاوي',
      'ar.sudais': 'عبد الرحمن السديس',
    };
    return names[id] ?? 'قارئ';
  }

  Widget _buildOptionIconButton(IconData icon, bool isDark, String? label) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: label != null
          ? Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            )
          : Icon(
              icon,
              size: 18,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
    );
  }

  Widget _buildMiniPlayer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _isMinimized = false),
      child: Container(
        height: 70 + MediaQuery.of(context).padding.bottom,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF14B8A6),
              ),
              child: const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سورة ${widget.surahName}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Text(
                    'اضغط للتكبير',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: const Color(0xFF14B8A6),
              ),
              onPressed: () {
                if (_isPlaying) {
                  _player.pause();
                } else {
                  _player.play();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTapDown: (_) => setState(
        () {},
      ), // Trigger scale (would need state var but GestureDetector basic scale works if animated container)
      // Better: Use a simple state var for scale or just AnimatedScale on separate controller.
      // For now, let's just make the Icon AnimatedSwitcher.
      onTap: () {
        if (_isPlaying) {
          _player.pause();
        } else {
          _player.play();
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF14B8A6), Color(0xFF06B6D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(_isPlaying),
                  color: Colors.white,
                  size: 32,
                ),
              ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }
}
