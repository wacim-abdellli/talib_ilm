import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import 'quran_audio_downloader.dart';

enum AudioRepeatMode {
  none,
  singleAyah,
  surah,
}

enum AudioPlaybackErrorType {
  network,
  sourceNotFound,
  unknown,
}

class AudioPlaybackError {
  final AudioPlaybackErrorType type;
  final String message;
  final dynamic originalError;

  const AudioPlaybackError({
    required this.type,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'AudioPlaybackError($type: $message)';
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

  AudioPlayer _player = AudioPlayer();
  StreamSubscription? _playerStateSub;

  void _ensurePlayerActive() {
    try {
      final _ = _player.processingState;
    } catch (_) {
      _recreatePlayer();
    }
  }

  Future<void> _recreatePlayer() async {
    try {
      _playerStateSub?.cancel();
      await _player.dispose();
    } catch (_) {}
    _player = AudioPlayer();
    _initAudioListener();
  }

  static const List<QuranReciter> reciters = [
    QuranReciter(
      id: 'alafasy',
      name: 'مشاري راشد العفاسي',
      subfolder: 'Alafasy_128kbps',
    ),
    QuranReciter(
      id: 'qatami',
      name: 'ناصر القطامي',
      subfolder: 'Nasser_Alqatami_128kbps',
    ),
    QuranReciter(
      id: 'dossari',
      name: 'ياسر الدوسري',
      subfolder: 'Yasser_Ad-Dussary_128kbps',
    ),
    QuranReciter(
      id: 'muaiqly',
      name: 'ماهر المعيقلي',
      subfolder: 'MaherAlMuaiqly128kbps',
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
    QuranReciter(
      id: 'shatri',
      name: 'أبو بكر الشاطري',
      subfolder: 'Abu_Bakr_Ash-Shaatree_128kbps',
    ),
    QuranReciter(
      id: 'shuraym',
      name: 'سعود الشريم',
      subfolder: 'Saood_ash-Shuraym_128kbps',
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
  final ValueNotifier<AudioPlaybackError?> errorNotifier =
      ValueNotifier<AudioPlaybackError?>(null);

  Timer? _sleepTimer;
  final ValueNotifier<int?> sleepTimerMinutesNotifier = ValueNotifier<int?>(null);

  bool _isContinuous = false;
  int _endAyah = 0;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  bool get isPlaying => _player.playing;

  void clearError() {
    errorNotifier.value = null;
  }

  static AudioPlaybackError classifyError(dynamic e) {
    final str = e.toString().toLowerCase();
    if (str.contains('socketexception') ||
        str.contains('failed host lookup') ||
        str.contains('network') ||
        str.contains('connection') ||
        str.contains('timed out') ||
        str.contains('timeout')) {
      return const AudioPlaybackError(
        type: AudioPlaybackErrorType.network,
        message: 'تعذر تشغيل التلاوة. يرجى التحقق من الاتصال بالإنترنت',
      );
    } else if (str.contains('404') ||
        str.contains('not found') ||
        str.contains('filenotfound')) {
      return const AudioPlaybackError(
        type: AudioPlaybackErrorType.sourceNotFound,
        message: 'ملف التلاوة غير متوفر لهذا القارئ حالياً',
      );
    } else {
      return AudioPlaybackError(
        type: AudioPlaybackErrorType.unknown,
        message: 'تعذر تشغيل التلاوة، يرجى المحاولة مرة أخرى',
        originalError: e,
      );
    }
  }

  Future<void> _handlePlaybackError(dynamic e) async {
    final err = classifyError(e);
    isPlayingNotifier.value = false;
    errorNotifier.value = err;
    try {
      await _player.stop();
    } catch (_) {}
  }

  void _initAudioListener() {
    _playerStateSub?.cancel();
    _playerStateSub = _player.playerStateStream.listen(
      (state) {
        isPlayingNotifier.value = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _handleTrackCompleted();
        }
      },
      onError: (Object e) {
        debugPrint('QuranAudioService stream error: $e');
        _handlePlaybackError(e);
      },
    );
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

  /// Resolves the audio source: uses locally downloaded file if exists, otherwise streams from URL.
  Future<AudioSource> getAudioSource(int surah, int ayah, {QuranReciter? reciter}) async {
    final r = reciter ?? _selectedReciter;
    final surahName = quran.getSurahNameArabic(surah);
    final tag = MediaItem(
      id: '${surah}_$ayah',
      album: 'سورة $surahName',
      title: 'الآية $ayah - سورة $surahName',
      artist: r.name,
      artUri: Uri.parse('android.resource://com.example.talib_ilm/mipmap/ic_launcher'),
      displayTitle: 'سورة $surahName',
      displaySubtitle: 'الآية $ayah · ${r.name}',
      displayDescription: 'تلاوة القرآن الكريم - طالب العلم',
    );

    try {
      final localPath = await QuranAudioDownloader.getLocalAyahPath(surah, ayah, reciter: r);
      final localFile = File(localPath);
      if (localFile.existsSync() && localFile.lengthSync() > 0) {
        return AudioSource.file(localPath, tag: tag);
      }
    } catch (_) {}

    final url = getAudioUrl(surah, ayah, reciter: r);
    return AudioSource.uri(Uri.parse(url), tag: tag);
  }

  Future<void> _startPlay(
    int surah,
    int ayah, {
    QuranReciter? reciter,
    int retryCount = 0,
  }) async {
    clearError();
    final r = reciter ?? _selectedReciter;
    activeSurahNotifier.value = surah;
    activeAyahNotifier.value = ayah;

    try {
      _ensurePlayerActive();

      final audioSource = await getAudioSource(surah, ayah, reciter: r);
      final url = getAudioUrl(surah, ayah, reciter: r);

      bool loaded = false;
      try {
        await _player.stop();
        await _player
            .setAudioSource(audioSource)
            .timeout(AppMotion.networkTimeout);
        loaded = true;
      } catch (sourceErr) {
        debugPrint('setAudioSource failed ($url): $sourceErr, trying direct setUrl');
        try {
          await _player.stop();
          await _player
              .setUrl(url)
              .timeout(AppMotion.networkTimeout);
          loaded = true;
        } catch (urlErr) {
          debugPrint('Direct setUrl failed ($url): $urlErr');
          loaded = false;
        }
      }

      if (!loaded) {
        if (retryCount < 2) {
          debugPrint('Audio loading failed, recreating player & retrying (attempt ${retryCount + 1})...');
          await _recreatePlayer();
          await Future.delayed(AppMotion.searchDebounce);
          return _startPlay(surah, ayah, reciter: r, retryCount: retryCount + 1);
        }
        throw Exception('Failed to load audio from $url');
      }

      await _player.setSpeed(speedNotifier.value);
      await _player.play();
    } catch (e) {
      debugPrint('QuranAudioService play error: $e');
      await _handlePlaybackError(e);
    }
  }

  void _handleTrackCompleted() {
    final surah = activeSurahNotifier.value;
    final ayah = activeAyahNotifier.value;

    if (surah == null || ayah == null) return;

    // 1. Single Ayah Repeat Mode (repeats the exact same verse infinitely)
    if (repeatModeNotifier.value == AudioRepeatMode.singleAyah) {
      _startPlay(surah, ayah);
      return;
    }

    final totalVerses = quran.getVerseCount(surah);

    // 2. Surah Repeat Mode (Infinite repeat: plays sequentially, loops back to ayah 1)
    if (repeatModeNotifier.value == AudioRepeatMode.surah) {
      if (ayah < totalVerses) {
        _startPlay(surah, ayah + 1);
      } else {
        // Loop back to verse 1 infinitely!
        _startPlay(surah, 1);
      }
      return;
    }

    final limit = (_isContinuous && _endAyah > 0) ? _endAyah : totalVerses;

    // 3. Continuous / Standard Playback
    if (_isContinuous) {
      if (ayah < limit) {
        _startPlay(surah, ayah + 1);
      } else if (surah < 114) {
        playContinuous(surah: surah + 1, startAyah: 1);
      } else {
        stop();
      }
    } else {
      // By default in modern Quran apps, playing verse N advances to N+1
      if (ayah < totalVerses) {
        _startPlay(surah, ayah + 1);
      } else {
        stop();
      }
    }
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() async {
    if (activeSurahNotifier.value != null && activeAyahNotifier.value != null) {
      if (_player.processingState == ProcessingState.idle) {
        await _startPlay(activeSurahNotifier.value!, activeAyahNotifier.value!);
        return;
      }
    }
    await _player.play();
  }

  Future<void> setPlaybackSpeed(double speed) async {
    speedNotifier.value = speed;
    await _player.setSpeed(speed);
  }

  Future<void> setRepeatMode(AudioRepeatMode mode) async {
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
    clearError();
    try {
      await _player.stop();
    } catch (_) {}
  }

  void dispose() {
    _sleepTimer?.cancel();
    _playerStateSub?.cancel();
    errorNotifier.dispose();
    _player.dispose();
  }
}
