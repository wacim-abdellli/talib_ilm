import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;

enum AudioRepeatMode {
  none,
  singleAyah,
  surah,
}

class QuranReciter {
  final String id;
  final String name;
  final String subfolder;

  const QuranReciter({
    required this.id,
    required this.name,
    required this.subfolder,
  });
}

class QuranAudioService {
  static final QuranAudioService _instance = QuranAudioService._internal();
  factory QuranAudioService() => _instance;
  QuranAudioService._internal() {
    _initAudioListener();
  }

  final AudioPlayer _player = AudioPlayer();

  static const List<QuranReciter> reciters = [
    QuranReciter(
      id: 'alafasy',
      name: 'مشاري راشد العفاسي',
      subfolder: 'Alafasy_128kbps',
    ),
    QuranReciter(
      id: 'husary',
      name: 'محمود خليل الحصري',
      subfolder: 'Husary_128kbps',
    ),
    QuranReciter(
      id: 'minshawi',
      name: 'محمد صديق المنشاوي',
      subfolder: 'Minshawy_Murattal_128kbps',
    ),
    QuranReciter(
      id: 'abdulbasit',
      name: 'عبد الباسط عبد الصمد',
      subfolder: 'AbdulSamad_64kbps_QuranExplorer.Com',
    ),
    QuranReciter(
      id: 'ghamadi',
      name: 'سعد الغامدي',
      subfolder: 'Ghamadi_40kbps',
    ),
  ];

  QuranReciter _selectedReciter = reciters[0];
  QuranReciter get selectedReciter => _selectedReciter;
  void setSelectedReciter(QuranReciter reciter) => _selectedReciter = reciter;

  // State Notifiers for selective, high-performance UI rebuilds
  final ValueNotifier<int?> activeSurahNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<int?> activeAyahNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> speedNotifier = ValueNotifier<double>(1.0);
  final ValueNotifier<AudioRepeatMode> repeatModeNotifier =
      ValueNotifier<AudioRepeatMode>(AudioRepeatMode.none);

  Timer? _sleepTimer;
  final ValueNotifier<int?> sleepTimerMinutesNotifier = ValueNotifier<int?>(null);

  bool _isContinuous = false;
  int _endAyah = 0;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  bool get isPlaying => _player.playing;

  void _initAudioListener() {
    _player.playerStateStream.listen((state) {
      isPlayingNotifier.value = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _handleTrackCompleted();
      }
    });
  }

  String _formatNumber(int n) => n.toString().padLeft(3, '0');

  String getAudioUrl(int surah, int ayah, {QuranReciter? reciter}) {
    final r = reciter ?? _selectedReciter;
    final sStr = _formatNumber(surah);
    final aStr = _formatNumber(ayah);
    return 'https://everyayah.com/data/${r.subfolder}/$sStr$aStr.mp3';
  }

  /// Play a single verse
  Future<void> playVerse(int surah, int ayah, {QuranReciter? reciter}) async {
    _isContinuous = false;
    await _startPlay(surah, ayah, reciter: reciter);
  }

  /// Play continuous verses (e.g. whole Surah or Page)
  Future<void> playContinuous({
    required int surah,
    required int startAyah,
    int? endAyah,
    QuranReciter? reciter,
  }) async {
    _isContinuous = true;
    _endAyah = endAyah ?? quran.getVerseCount(surah);
    await _startPlay(surah, startAyah, reciter: reciter);
  }

  Future<void> _startPlay(int surah, int ayah, {QuranReciter? reciter}) async {
    final r = reciter ?? _selectedReciter;
    activeSurahNotifier.value = surah;
    activeAyahNotifier.value = ayah;

    try {
      final url = getAudioUrl(surah, ayah, reciter: r);
      await _player.setUrl(url);
      await _player.setSpeed(speedNotifier.value);
      await _player.play();
    } catch (e) {
      debugPrint('QuranAudioService play error: $e');
    }
  }

  void _handleTrackCompleted() {
    final surah = activeSurahNotifier.value;
    final ayah = activeAyahNotifier.value;

    if (surah == null || ayah == null) return;

    if (repeatModeNotifier.value == AudioRepeatMode.singleAyah) {
      playVerse(surah, ayah);
      return;
    }

    if (_isContinuous) {
      final totalVerses = quran.getVerseCount(surah);
      if (ayah < _endAyah && ayah < totalVerses) {
        // Next verse in same surah
        _startPlay(surah, ayah + 1);
      } else if (ayah >= totalVerses && surah < 114) {
        // Next surah
        if (repeatModeNotifier.value == AudioRepeatMode.surah) {
          playContinuous(surah: surah, startAyah: 1);
        } else {
          playContinuous(surah: surah + 1, startAyah: 1);
        }
      } else if (repeatModeNotifier.value == AudioRepeatMode.surah) {
        playContinuous(surah: surah, startAyah: 1);
      } else {
        stop();
      }
    } else {
      stop();
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();

  Future<void> setPlaybackSpeed(double speed) async {
    speedNotifier.value = speed;
    await _player.setSpeed(speed);
  }

  void setRepeatMode(AudioRepeatMode mode) {
    repeatModeNotifier.value = mode;
  }

  void setSleepTimer(int? minutes) {
    _sleepTimer?.cancel();
    sleepTimerMinutesNotifier.value = minutes;

    if (minutes != null && minutes > 0) {
      _sleepTimer = Timer(Duration(minutes: minutes), () {
        stop();
        sleepTimerMinutesNotifier.value = null;
      });
    }
  }

  Future<void> nextAyah() async {
    final s = activeSurahNotifier.value;
    final a = activeAyahNotifier.value;
    if (s == null || a == null) return;

    final total = quran.getVerseCount(s);
    if (a < total) {
      await _startPlay(s, a + 1);
    } else if (s < 114) {
      await _startPlay(s + 1, 1);
    }
  }

  Future<void> previousAyah() async {
    final s = activeSurahNotifier.value;
    final a = activeAyahNotifier.value;
    if (s == null || a == null) return;

    if (a > 1) {
      await _startPlay(s, a - 1);
    } else if (s > 1) {
      final prevTotal = quran.getVerseCount(s - 1);
      await _startPlay(s - 1, prevTotal);
    }
  }

  Future<void> stop() async {
    activeSurahNotifier.value = null;
    activeAyahNotifier.value = null;
    isPlayingNotifier.value = false;
    _isContinuous = false;
    _sleepTimer?.cancel();
    sleepTimerMinutesNotifier.value = null;
    await _player.stop();
  }

  void dispose() {
    _sleepTimer?.cancel();
    _player.dispose();
  }
}
