import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/quran_models.dart';

/// Playback mode for audio
enum PlaybackMode {
  single,     // Play one ayah and stop
  continuous, // Auto-play next ayah
  repeatOne,  // Repeat current ayah
}

/// Compact Quran Audio Player
class QuranAudioPlayer extends StatefulWidget {
  final Ayah ayah;
  final String surahName;
  final int surahNumber;
  final int totalAyahs;
  final String reciterId;
  final int startingAyahNumber; // Which ayah to start from
  final VoidCallback? onClose;
  final ValueChanged<int>? onAyahChanged; // Callback when ayah changes

  const QuranAudioPlayer({
    super.key,
    required this.ayah,
    required this.surahName,
    required this.surahNumber,
    required this.totalAyahs,
    required this.reciterId,
    required this.startingAyahNumber,
    this.onClose,
    this.onAyahChanged,
  });

  @override
  State<QuranAudioPlayer> createState() => _QuranAudioPlayerState();
}

class _QuranAudioPlayerState extends State<QuranAudioPlayer> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;
  String? _error;
  
  // Track current ayah internally
  late int _currentAyahNumber;
  late int _globalAyahNumber;
  
  // Playback mode
  PlaybackMode _playbackMode = PlaybackMode.continuous;

  static const _accent = Color(0xFFFFC107);
  
  // Flag to prevent double initialization
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    // Start from the specified ayah, not the page ayah
    _currentAyahNumber = widget.startingAyahNumber;
    // Calculate global ayah number from starting ayah
    _globalAyahNumber = widget.ayah.number - widget.ayah.numberInSurah + widget.startingAyahNumber;
    _setupPlayerListeners();
    // Delay loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_initialized) {
        _initialized = true;
        _loadAudio();
      }
    });
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
            _onAyahCompleted();
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

  void _onAyahCompleted() {
    switch (_playbackMode) {
      case PlaybackMode.single:
        // Stop - do nothing
        break;
      case PlaybackMode.continuous:
        _playNext();
        break;
      case PlaybackMode.repeatOne:
        _player.seek(Duration.zero);
        _player.play();
        break;
    }
  }

  Future<void> _loadAudio() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Try everyayah.com first for higher quality audio (192kbps)
      final reciterFolder = _getReciterFolder(widget.reciterId);
      final surahPadded = widget.surahNumber.toString().padLeft(3, '0');
      final ayahPadded = _currentAyahNumber.toString().padLeft(3, '0');
      
      final primaryUrl = 'https://everyayah.com/data/$reciterFolder/$surahPadded$ayahPadded.mp3';
      
      try {
        await _player.setUrl(primaryUrl).timeout(const Duration(seconds: 5));
        if (mounted) {
          setState(() => _isLoading = false);
          await _player.play();
        }
      } catch (_) {
        // Fallback to alquran.cloud API
        final fallbackUrl = 'https://cdn.islamic.network/quran/audio/128/${widget.reciterId}/$_globalAyahNumber.mp3';
        await _player.setUrl(fallbackUrl).timeout(const Duration(seconds: 5));
        if (mounted) {
          setState(() => _isLoading = false);
          await _player.play();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'تعذر تحميل الصوت';
        });
      }
    }
  }

  // Map reciter ID to everyayah.com folder name (192kbps high quality)
  String _getReciterFolder(String reciterId) {
    const reciterFolders = {
      'alafasy': 'Alafasy_128kbps',
      'ar.alafasy': 'Alafasy_128kbps',
      'minshawi': 'Minshawy_Murattal_128kbps',
      'ar.minshawi': 'Minshawy_Murattal_128kbps',
      'sudais': 'Abdurrahmaan_As-Sudais_192kbps',
      'ar.abdurrahmaansudais': 'Abdurrahmaan_As-Sudais_192kbps',
      'shuraim': 'Saood_ash-Shuraym_128kbps',
      'ar.saaborinah': 'Saood_ash-Shuraym_128kbps',
      'husary': 'Husary_128kbps',
      'ar.husary': 'Husary_128kbps',
      'abdulbasit': 'Abdul_Basit_Murattal_192kbps',
      'ar.abdulbasit': 'Abdul_Basit_Murattal_192kbps',
    };
    return reciterFolders[reciterId] ?? 'Alafasy_128kbps';
  }

  void _playNext() {
    if (_currentAyahNumber < widget.totalAyahs) {
      setState(() {
        _currentAyahNumber++;
        _globalAyahNumber++;
      });
      widget.onAyahChanged?.call(_currentAyahNumber);
      _loadAudio();
    }
  }

  void _playPrevious() {
    if (_currentAyahNumber > 1) {
      setState(() {
        _currentAyahNumber--;
        _globalAyahNumber--;
      });
      widget.onAyahChanged?.call(_currentAyahNumber);
      _loadAudio();
    }
  }

  void _togglePlay() {
    HapticFeedback.lightImpact();
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _cyclePlaybackMode() {
    HapticFeedback.selectionClick();
    setState(() {
      switch (_playbackMode) {
        case PlaybackMode.continuous:
          _playbackMode = PlaybackMode.single;
          break;
        case PlaybackMode.single:
          _playbackMode = PlaybackMode.repeatOne;
          break;
        case PlaybackMode.repeatOne:
          _playbackMode = PlaybackMode.continuous;
          break;
      }
    });
  }

  IconData _getPlaybackModeIcon() {
    switch (_playbackMode) {
      case PlaybackMode.continuous:
        return Icons.repeat_rounded;
      case PlaybackMode.single:
        return Icons.looks_one_rounded;
      case PlaybackMode.repeatOne:
        return Icons.repeat_one_rounded;
    }
  }

  String _getPlaybackModeTooltip() {
    switch (_playbackMode) {
      case PlaybackMode.continuous:
        return 'تشغيل متواصل';
      case PlaybackMode.single:
        return 'آية واحدة';
      case PlaybackMode.repeatOne:
        return 'تكرار الآية';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF0D0D0D),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + bottomPadding),
            child: Column(
              children: [
                // Surah info header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 16,
                            color: _accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.surahName,
                            style: const TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEDEDED),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_currentAyahNumber/${widget.totalAyahs}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Progress slider with better styling
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 5,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                    activeTrackColor: _accent,
                    inactiveTrackColor: const Color(0xFF2A2A2A),
                    thumbColor: _accent,
                    overlayColor: _accent.withValues(alpha: 0.2),
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: _duration.inMilliseconds > 0
                        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                        : 0,
                    onChanged: (value) {
                      final newPosition = Duration(
                        milliseconds: (value * _duration.inMilliseconds).round(),
                      );
                      _player.seek(newPosition);
                    },
                  ),
                ),

                // Time display
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF808080),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF808080),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Main controls row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Playback mode button
                    _buildControlButton(
                      icon: _getPlaybackModeIcon(),
                      onTap: _cyclePlaybackMode,
                      isActive: _playbackMode != PlaybackMode.continuous,
                      size: 22,
                    ),
                    
                    // Previous ayah
                    _buildControlButton(
                      icon: Icons.skip_previous_rounded,
                      onTap: _currentAyahNumber > 1 ? _playPrevious : null,
                      size: 32,
                    ),
                    
                    // Play/Pause button (main)
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _accent,
                              _accent.withValues(alpha: 0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _accent.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(18),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF1A1A1A),
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Icon(
                                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: const Color(0xFF1A1A1A),
                                size: 36,
                              ),
                      ),
                    ),
                    
                    // Next ayah
                    _buildControlButton(
                      icon: Icons.skip_next_rounded,
                      onTap: _currentAyahNumber < widget.totalAyahs ? _playNext : null,
                      size: 32,
                    ),
                    
                    // Close button
                    _buildControlButton(
                      icon: Icons.close_rounded,
                      onTap: () {
                        _player.stop();
                        widget.onClose?.call();
                      },
                      size: 22,
                      isClose: true,
                    ),
                  ],
                ),

                // Error message
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Colors.red[300],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onTap,
    double size = 24,
    bool isActive = false,
    bool isClose = false,
  }) {
    final isEnabled = onTap != null;
    final color = isClose 
        ? const Color(0xFF606060)
        : isActive 
            ? _accent 
            : (isEnabled ? const Color(0xFFEDEDED) : const Color(0xFF404040));
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? _accent.withValues(alpha: 0.15) : const Color(0xFF1E1E1E),
          shape: BoxShape.circle,
          border: isActive ? Border.all(color: _accent.withValues(alpha: 0.3), width: 1) : null,
        ),
        child: Icon(
          icon,
          size: size,
          color: color,
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }
}

