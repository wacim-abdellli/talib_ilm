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
    final height =
        140.0 +
        MediaQuery.of(
          context,
        ).padding.bottom; // Increased height for controls + slider

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Stack(
        children: [
          // Minimize Button
          Positioned(
            top: 8,
            left: 16,
            child: GestureDetector(
              onTap: () => setState(() => _isMinimized = true),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: isDark ? Colors.grey : Colors.grey[600],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // LEFT SECTION: Reciter
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[800],
                                border: Border.all(color: Colors.white12),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white70,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'الشيخ مشاري', // Hardcoded or mapped
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_isPlaying)
                                    SizedBox(
                                      height: 12,
                                      child: _buildWaveform(isDark),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // CENTER SECTION: Controls
                      Expanded(
                        flex: 4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.skip_next_rounded,
                                size: 28,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              onPressed: widget
                                  .onPrevious, // RTL Logic: Next is Previous in sequence? No, skip_next sends to visual next right
                            ),
                            const SizedBox(width: 12),
                            _buildPlayButton(),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: Icon(
                                Icons.skip_previous_rounded,
                                size: 28,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              onPressed: widget.onNext,
                            ),
                          ],
                        ),
                      ),

                      // RIGHT SECTION: Options
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildOptionIcon(
                              Icons.speed,
                              '1.0x',
                              isDark,
                            ), // Placeholder text
                            const SizedBox(width: 8),
                            _buildOptionIcon(Icons.repeat, '', isDark),
                            const SizedBox(width: 8),
                            _buildOptionIcon(Icons.volume_up, '', isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress Slider
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
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
                                : Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF14B8A6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
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

  Widget _buildOptionIcon(IconData icon, String label, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.grey : Colors.grey[600]),
        if (label.isNotEmpty)
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildWaveform(bool isDark) {
    // Placeholder for waveform animation
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Container(
          width: 3,
          height: 8 + (index % 3) * 4.0,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: const Color(0xFF14B8A6),
            borderRadius: BorderRadius.circular(2),
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
