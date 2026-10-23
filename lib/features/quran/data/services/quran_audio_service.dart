import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../core/services/audio_coordinator.dart';
import 'quran_audio_downloader.dart';

enum AudioRepeatMode { none, repeatOnce, infinite }

enum AudioPlaybackErrorType { network, sourceNotFound, unknown }

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

  @visibleForTesting
  QuranAudioService.forTesting({
    required AudioPlayer player,
    required Future<AudioSource> Function(int, int, QuranReciter)
    sourceResolver,
    AudioPlayer Function()? playerFactory,
    Future<void> Function()? retryDelay,
  }) : _player = player,
       _sourceResolver = sourceResolver {
    if (playerFactory != null) _playerFactory = playerFactory;
    if (retryDelay != null) _retryDelay = retryDelay;
    _initAudioListener();
  }

  AudioPlayer _player = AudioPlayer();
  AudioPlayer Function() _playerFactory = () => AudioPlayer();
  Future<void> Function() _retryDelay = () =>
      Future<void>.delayed(AppMotion.searchDebounce);
  Future<AudioSource> Function(int, int, QuranReciter)? _sourceResolver;
  StreamSubscription? _playerStateSub;

  Future<void> _recreatePlayer(int operation) async {
    if (!_ownsOperation(operation)) return;
    final previous = _player;
    final previousSubscription = _playerStateSub;
    _player = _playerFactory();
    _initAudioListener();
    try {
      await previousSubscription?.cancel();
      await previous.dispose();
    } catch (_) {}
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
  final ValueNotifier<int?> sleepTimerMinutesNotifier = ValueNotifier<int?>(
    null,
  );

  bool _isContinuous = false;
  bool _isSingleVerseOnly = false;
  bool _hasExplicitEnd = false;
  bool _playWhenReady = false;
  int _endAyah = 0;
  bool _isTransitioning = false;
  bool _completionArmed = false;
  bool _disposed = false;
  int _operation = 0;
  int _ayahRepeatCount = 0;
  QuranReciter? _playbackReciter;

  bool _ownsOperation(int operation) => !_disposed && operation == _operation;

  bool get isContinuous => _isContinuous;

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

  Future<void> _handlePlaybackError(dynamic e, [int? operation]) async {
    if (!_ownsOperation(operation ?? _operation)) return;
    _completionArmed = false;
    _playWhenReady = false;
    final err = classifyError(e);
    isPlayingNotifier.value = false;
    errorNotifier.value = err;
    try {
      await _player.stop();
    } catch (_) {}
  }

  void _initAudioListener() {
    AudioCoordinator.onPauseQuran = pause;
    _playerStateSub?.cancel();
    final player = _player;
    _playerStateSub = _player.playerStateStream.listen(
      (state) {
        if (_disposed || player != _player) return;
        isPlayingNotifier.value =
            state.playing && state.processingState != ProcessingState.completed;
        if (state.processingState == ProcessingState.completed) {
          _handleTrackCompleted();
        }
      },
      onError: (Object e) {
        if (_disposed || player != _player || _isTransitioning) return;
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
  Future<void> playVerse(
    int surah,
    int ayah, {
    QuranReciter? reciter,
    bool singleVerse = false,
  }) async {
    _ayahRepeatCount = 0;
    _isContinuous = false;
    _isSingleVerseOnly = singleVerse;
    await _startPlay(surah, ayah, reciter: reciter ?? _selectedReciter);
  }

  /// Play continuous verses (e.g. whole Surah or Page)
  Future<void> playContinuous({
    required int surah,
    required int startAyah,
    int? endAyah,
    QuranReciter? reciter,
  }) async {
    _ayahRepeatCount = 0;
    _isContinuous = true;
    _isSingleVerseOnly = false;
    _hasExplicitEnd = endAyah != null;
    _endAyah = endAyah ?? quran.getVerseCount(surah);
    await _startPlay(surah, startAyah, reciter: reciter ?? _selectedReciter);
  }

  /// Resolves the audio source: uses locally downloaded file if exists, otherwise streams from URL.
  Future<AudioSource> getAudioSource(
    int surah,
    int ayah, {
    QuranReciter? reciter,
  }) async {
    final r = reciter ?? _selectedReciter;
    if (_sourceResolver != null) return _sourceResolver!(surah, ayah, r);
    final surahName = quran.getSurahNameArabic(surah);
    final tag = MediaItem(
      id: '${r.id}_${surah}_$ayah',
      album: 'سورة $surahName',
      title: 'الآية $ayah - سورة $surahName',
      artist: r.name,
      artUri: Uri.parse(
        'android.resource://com.example.talib_ilm/mipmap/ic_launcher',
      ),
      displayTitle: 'سورة $surahName',
      displaySubtitle: 'الآية $ayah · ${r.name}',
      displayDescription: 'تلاوة القرآن الكريم - طالب العلم',
    );

    try {
      final localPath = await QuranAudioDownloader.getLocalAyahPath(
        surah,
        ayah,
        reciter: r,
      );
      final localFile = File(localPath);
      if (localFile.existsSync() && localFile.lengthSync() > 0) {
        return AudioSource.file(localPath, tag: tag);
      }
    } catch (_) {}

    final url = getAudioUrl(surah, ayah, reciter: r);
    return AudioSource.uri(Uri.parse(url), tag: tag);
  }

  Future<void> _startPlay(int surah, int ayah, {QuranReciter? reciter}) async {
    if (_disposed) return;
    final operation = ++_operation;
    clearError();
    final r = reciter ?? _playbackReciter ?? _selectedReciter;
    _playbackReciter = r;
    _isTransitioning = true;
    _playWhenReady = true;
    _completionArmed = false;
    activeSurahNotifier.value = surah;
    activeAyahNotifier.value = ayah;
    unawaited(AudioCoordinator.acquireFocus(AudioStreamType.quran));

    try {
      for (var attempt = 0; attempt < 3; attempt++) {
        if (!_ownsOperation(operation)) return;
        final player = _player;
        final audioSource = await getAudioSource(surah, ayah, reciter: r);
        if (!_ownsOperation(operation)) return;
        final url = getAudioUrl(surah, ayah, reciter: r);

        bool loaded = false;
        try {
          await player.stop();
          if (!_ownsOperation(operation)) return;
          await player
              .setAudioSource(audioSource)
              .timeout(AppMotion.networkTimeout);
          loaded = true;
        } catch (sourceErr) {
          if (!_ownsOperation(operation)) return;
          debugPrint(
            'setAudioSource failed ($url): $sourceErr, trying direct setUrl',
          );
          try {
            await player.stop();
            if (!_ownsOperation(operation)) return;
            await player.setUrl(url).timeout(AppMotion.networkTimeout);
            loaded = true;
          } catch (urlErr) {
            debugPrint('Direct setUrl failed ($url): $urlErr');
            loaded = false;
          }
        }

        if (!_ownsOperation(operation)) return;
        if (!loaded) {
          if (attempt < 2) {
            await _recreatePlayer(operation);
            await _retryDelay();
            continue;
          }
          throw Exception('Failed to load audio from $url');
        }

        await player.setSpeed(speedNotifier.value);
        if (!_ownsOperation(operation)) return;
        // play() completes at the end of playback, not when playback starts.
        // Loading is over now; completion events must be allowed during playback.
        _isTransitioning = false;
        _completionArmed = true;
        if (!_playWhenReady) return;
        await AudioCoordinator.acquireFocus(AudioStreamType.quran);
        if (!_ownsOperation(operation) || !_playWhenReady) return;
        unawaited(
          player.play().catchError((Object error) async {
            await _handlePlaybackError(error, operation);
          }),
        );
        return;
      }
    } catch (e) {
      await _handlePlaybackError(e, operation);
    } finally {
      if (_ownsOperation(operation)) _isTransitioning = false;
    }
  }

  void _handleTrackCompleted() {
    final surah = activeSurahNotifier.value;
    final ayah = activeAyahNotifier.value;

    if (surah == null || ayah == null) return;

    if (_isTransitioning || !_completionArmed || !_playWhenReady) return;
    _completionArmed = false;
    _isTransitioning = true;

    // 1. Infinite Repeat Mode (stays repeating the exact same ayah indefinitely)
    if (repeatModeNotifier.value == AudioRepeatMode.infinite) {
      _startPlay(surah, ayah);
      return;
    }

    // 2. Repeat Once Mode (repeats the ayah once, then advances to next)
    if (repeatModeNotifier.value == AudioRepeatMode.repeatOnce) {
      if (_ayahRepeatCount < 1) {
        _ayahRepeatCount++;
        _startPlay(surah, ayah);
        return;
      }
      _ayahRepeatCount = 0;
    }

    // 3. Single Verse Mode: stops after completing the requested single verse
    if (_isSingleVerseOnly) {
      _isSingleVerseOnly = false;
      stop();
      return;
    }

    final totalVerses = quran.getVerseCount(surah);
    final limit = (_isContinuous && _endAyah > 0) ? _endAyah : totalVerses;

    // 4. Continuous / Standard Playback (sequential verse by verse)
    if (_isContinuous) {
      if (ayah < limit) {
        _startPlay(surah, ayah + 1);
      } else if (!_hasExplicitEnd && surah < 114) {
        playContinuous(
          surah: surah + 1,
          startAyah: 1,
          reciter: _playbackReciter,
        );
      } else {
        stop();
      }
    } else {
      // By default, reading verse N advances to N+1
      if (ayah < totalVerses) {
        _startPlay(surah, ayah + 1);
      } else {
        stop();
      }
    }
  }

  Future<void> pause() {
    _playWhenReady = false;
    AudioCoordinator.releaseFocus(AudioStreamType.quran);
    return _player.pause();
  }

  Future<void> resume() async {
    if (_disposed || activeAyahNotifier.value == null) return;
    await AudioCoordinator.acquireFocus(AudioStreamType.quran);
    _playWhenReady = true;
    if (_isTransitioning) return;
    if (activeSurahNotifier.value != null && activeAyahNotifier.value != null) {
      if (_player.processingState == ProcessingState.idle) {
        await _startPlay(activeSurahNotifier.value!, activeAyahNotifier.value!);
        return;
      }
    }
    if (_disposed || activeAyahNotifier.value == null) return;
    final operation = _operation;
    unawaited(
      _player.play().catchError((Object error) async {
        await _handlePlaybackError(error, operation);
      }),
    );
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
      await _navigateTo(s, a + 1);
    } else if (s < 114) {
      await _navigateTo(s + 1, 1);
    } else {
      await stop();
    }
  }

  Future<void> previousAyah() async {
    final s = activeSurahNotifier.value;
    final a = activeAyahNotifier.value;
    if (s == null || a == null) return;

    if (a > 1) {
      await _navigateTo(s, a - 1);
    } else if (s > 1) {
      final prevTotal = quran.getVerseCount(s - 1);
      await _navigateTo(s - 1, prevTotal);
    }
  }

  Future<void> _navigateTo(int surah, int ayah) async {
    _ayahRepeatCount = 0;
    _isSingleVerseOnly = false;
    if (_isContinuous &&
        (surah != activeSurahNotifier.value || ayah > _endAyah)) {
      // Manual navigation outside the current range starts an unrestricted
      // continuation at the chosen verse, using that surah's own boundaries.
      _hasExplicitEnd = false;
      _endAyah = quran.getVerseCount(surah);
    }
    await _startPlay(surah, ayah);
  }

  Future<void> stop() async {
    if (_disposed) return;
    AudioCoordinator.releaseFocus(AudioStreamType.quran);
    ++_operation;
    _completionArmed = false;
    _playWhenReady = false;
    _playbackReciter = null;
    _ayahRepeatCount = 0;
    _isTransitioning = false;
    _isSingleVerseOnly = false;
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
    if (_disposed) return;
    _disposed = true;
    if (AudioCoordinator.onPauseQuran == pause) {
      AudioCoordinator.onPauseQuran = null;
    }
    ++_operation;
    _sleepTimer?.cancel();
    _playerStateSub?.cancel();
    errorNotifier.dispose();
    _player.dispose();
  }
}
