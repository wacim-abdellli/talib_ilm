import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../core/constants/app_policy.dart';
import '../../../../core/services/audio_coordinator.dart';
export '../models/audio_playback_error.dart';
import '../models/audio_playback_error.dart';
export '../models/quran_reciter.dart';
import '../models/quran_reciter.dart';
import 'quran_audio_downloader.dart';
import 'quran_audio_frame_merger.dart';

enum AudioRepeatMode { none, repeatOnce, infinite }

/// Configuration for repeating a custom range of ayahs for Quran memorization (حفظ القرآن).
class HifdhRangeConfig {
  final int surah;
  final int startAyah;
  final int endAyah;
  final int repeatCount; // 1, 3, 5, 10, or 0 (infinite)
  final int currentIteration;

  const HifdhRangeConfig({
    required this.surah,
    required this.startAyah,
    required this.endAyah,
    this.repeatCount = 1,
    this.currentIteration = 0,
  });

  bool get isInfinite => repeatCount == 0;
  bool get isCompleted => !isInfinite && currentIteration >= repeatCount;

  HifdhRangeConfig nextIteration() {
    return HifdhRangeConfig(
      surah: surah,
      startAyah: startAyah,
      endAyah: endAyah,
      repeatCount: repeatCount,
      currentIteration: currentIteration + 1,
    );
  }
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
      Future<void>.delayed(AppPolicy.debounce);
  Future<AudioSource> Function(int, int, QuranReciter)? _sourceResolver;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;

  Future<void> _recreatePlayer(int operation) async {
    if (!_ownsOperation(operation)) return;
    final previous = _player;
    final previousSubscription = _playerStateSub;
    final previousPosSub = _positionSub;
    _player = _playerFactory();
    _initAudioListener();
    try {
      await previousSubscription?.cancel();
      await previousPosSub?.cancel();
      await previous.dispose();
    } catch (_) {}
  }

  static List<QuranReciter> get reciters => QuranReciter.defaultReciters;

  QuranReciter _selectedReciter = reciters[0];
  QuranReciter get selectedReciter => _selectedReciter;
  QuranReciter get activeReciter => _playbackReciter ?? _selectedReciter;
  final ValueNotifier<QuranReciter> selectedReciterNotifier =
      ValueNotifier<QuranReciter>(QuranReciter.defaultReciters.first);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  void setSelectedReciter(QuranReciter reciter) {
    _selectedReciter = reciter;
    selectedReciterNotifier.value = reciter;
  }

  /// Changes the reciter for the active session and resumes at its current
  /// reading position, preserving pause state, speed, and continuation bounds.
  Future<void> switchReciter(QuranReciter reciter) async {
    if (_selectedReciter.id == reciter.id) return;

    final surah = activeSurahNotifier.value;
    final ayah = activeAyahNotifier.value;
    final shouldPlay = _playWhenReady;
    final wasFullSurah = isFullSurahMode;
    final wasContinuous = _isContinuous;
    final wasSingleVerse = _isSingleVerseOnly;
    final hadExplicitEnd = _hasExplicitEnd;
    final endAyah = _endAyah;

    setSelectedReciter(reciter);
    if (surah == null || ayah == null) return;

    // Preserve a one-ayah session when the user changes reciters. Surah-only
    // recordings cannot start at an ayah boundary, so select an ayah-based
    // reciter instead of silently changing this into full-surah playback.
    if (wasSingleVerse) {
      final verseReciter = reciter.isSurahBased
          ? QuranReciter.defaultReciters.firstWhere(
              (candidate) => !candidate.isSurahBased,
            )
          : reciter;
      if (verseReciter.id != reciter.id) setSelectedReciter(verseReciter);
      await playVerse(
        surah,
        ayah,
        reciter: verseReciter,
        singleVerse: true,
        autoPlay: shouldPlay,
      );
      return;
    }

    if (wasFullSurah || reciter.isSurahBased) {
      await playFullSurah(surah: surah, reciter: reciter, autoPlay: shouldPlay);
    } else if (wasContinuous) {
      await playContinuous(
        surah: surah,
        startAyah: ayah,
        endAyah: hadExplicitEnd ? endAyah : null,
        reciter: reciter,
        autoPlay: shouldPlay,
      );
    } else {
      await playVerse(
        surah,
        ayah,
        reciter: reciter,
        singleVerse: wasSingleVerse,
        autoPlay: shouldPlay,
      );
    }
  }

  // State Notifiers for selective, high-performance UI rebuilds
  final ValueNotifier<int?> activeSurahNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<int?> activeAyahNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> speedNotifier = ValueNotifier<double>(1.0);
  final ValueNotifier<AudioRepeatMode> repeatModeNotifier =
      ValueNotifier<AudioRepeatMode>(AudioRepeatMode.none);
  final ValueNotifier<int> verseRepeatTargetNotifier = ValueNotifier<int>(1);
  final ValueNotifier<HifdhRangeConfig?> hifdhRangeNotifier =
      ValueNotifier<HifdhRangeConfig?>(null);
  final ValueNotifier<AudioPlaybackError?> errorNotifier =
      ValueNotifier<AudioPlaybackError?>(null);
  final ValueNotifier<int?> sleepTimerMinutesNotifier = ValueNotifier<int?>(
    null,
  );
  final ValueNotifier<int?> sleepTimerRemainingSecondsNotifier =
      ValueNotifier<int?>(null);
  final ValueNotifier<bool> stopAtEndOfSurahNotifier = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<bool> isFullSurahModeNotifier = ValueNotifier<bool>(
    false,
  );

  Timer? _sleepTimer;
  DateTime? _sleepTimerEndTime;
  bool _isContinuous = false,
      _isSingleVerseOnly = false,
      _hasExplicitEnd = false,
      _playWhenReady = false;
  bool _isTransitioning = false, _completionArmed = false, _disposed = false;
  int _endAyah = 0,
      _operation = 0,
      _ayahRepeatCount = 0,
      _verseRepeatTarget = 1;
  QuranReciter? _playbackReciter;

  int get verseRepeatTarget => _verseRepeatTarget;

  bool get isFullSurahMode => isFullSurahModeNotifier.value;
  bool _ownsOperation(int operation) => !_disposed && operation == _operation;
  bool get isContinuous => _isContinuous;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get isPlaying => _player.playing;

  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> seekMilliseconds(int ms) =>
      _player.seek(Duration(days: 0, milliseconds: ms));
  Future<void> seekRelativeSeconds(int seconds) =>
      seekRelative(Duration(days: 0, seconds: seconds));

  Future<void> seekRelative(Duration offset) async {
    final cur = _player.position,
        tot = _player.duration ?? Duration.zero,
        tgt = cur + offset;
    await _player.seek(
      tgt < Duration.zero
          ? Duration.zero
          : (tot > Duration.zero && tgt > tot ? tot : tgt),
    );
  }

  void clearError() => errorNotifier.value = null;

  static AudioPlaybackError classifyError(dynamic e) =>
      AudioPlaybackError.classify(e);

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
    _positionSub?.cancel();
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
    try {
      _positionSub = _player.positionStream.listen((_) {
        if (_disposed || player != _player) return;
        if (_sleepTimerEndTime != null &&
            DateTime.now().isAfter(_sleepTimerEndTime!)) {
          _triggerSleepTimer();
        }
      });
    } catch (_) {}
  }

  static bool isValidSurah(int surah) => surah >= 1 && surah <= 114;

  static bool isValidVerse(int surah, int ayah) {
    if (!isValidSurah(surah)) return false;
    return ayah >= 1 && ayah <= quran.getVerseCount(surah);
  }

  String _formatNumber(int n) => n.toString().padLeft(3, '0');

  String getAudioUrl(int surah, int ayah, {QuranReciter? reciter}) {
    if (!isValidSurah(surah)) {
      throw ArgumentError('Invalid surah number: $surah. Must be 1..114');
    }
    if (!isValidVerse(surah, ayah)) {
      throw ArgumentError('Invalid ayah number: $ayah for surah $surah');
    }
    final r = reciter ?? _selectedReciter;
    final sStr = _formatNumber(surah);
    if (r.isSurahBased) {
      return '${r.surahBaseUrl}$sStr.mp3';
    }
    final aStr = _formatNumber(ayah);
    return 'https://everyayah.com/data/${r.subfolder}/$sStr$aStr.mp3';
  }

  /// Play a single verse
  Future<void> playVerse(
    int surah,
    int ayah, {
    QuranReciter? reciter,
    bool singleVerse = false,
    bool autoPlay = true,
  }) async {
    if (!isValidSurah(surah) || !isValidVerse(surah, ayah)) return;
    var r = reciter ?? _selectedReciter;
    // A surah-only recording cannot begin at an individual ayah. Never turn
    // a single-ayah request into a full-surah playback: switch to the first
    // available ayah-based reciter instead and keep the UI selection honest.
    if (r.isSurahBased) {
      r = QuranReciter.defaultReciters.firstWhere(
        (candidate) => !candidate.isSurahBased,
      );
      setSelectedReciter(r);
    }
    _ayahRepeatCount = 0;
    _isContinuous = false;
    _isSingleVerseOnly = singleVerse;
    isFullSurahModeNotifier.value = false;
    await _startPlay(surah, ayah, reciter: r, autoPlay: autoPlay);
  }

  /// Plays full surah recorded audio as a single continuous track if downloaded
  /// or if reciter is surah-based; otherwise delegates to continuous verse playback.
  Future<void> playFullSurah({
    required int surah,
    QuranReciter? reciter,
    bool autoPlay = true,
    bool hasExplicitEnd = false,
  }) async {
    if (!isValidSurah(surah)) return;
    final r = reciter ?? _selectedReciter;
    final fullFile = await QuranAudioFrameMerger.getFullSurahAudioFile(
      surah,
      reciter: r,
    );
    final hasOfflineFullFile = fullFile != null && fullFile.existsSync();

    if (hasOfflineFullFile) {
      _ayahRepeatCount = 0;
      _isContinuous = true;
      _isSingleVerseOnly = false;
      _hasExplicitEnd = hasExplicitEnd;
      _endAyah = quran.getVerseCount(surah);
      isFullSurahModeNotifier.value = true;
      _playbackReciter = r;

      final surahName = quran.getSurahNameArabic(surah);
      final tag = _buildSurahMediaItem(surah, r, surahName);
      final source = AudioSource.file(fullFile.path, tag: tag);
      await _startPlaySource(
        surah,
        1,
        audioSource: source,
        reciter: r,
        autoPlay: autoPlay,
      );
      return;
    }

    if (r.isSurahBased) {
      _ayahRepeatCount = 0;
      _isContinuous = true;
      _isSingleVerseOnly = false;
      _hasExplicitEnd = hasExplicitEnd;
      _endAyah = quran.getVerseCount(surah);
      isFullSurahModeNotifier.value = true;
      _playbackReciter = r;

      final surahName = quran.getSurahNameArabic(surah);
      final tag = _buildSurahMediaItem(surah, r, surahName);
      final sStr = _formatNumber(surah);
      final url = '${r.surahBaseUrl}$sStr.mp3';
      final source = AudioSource.uri(Uri.parse(url), tag: tag);
      await _startPlaySource(
        surah,
        1,
        audioSource: source,
        reciter: r,
        autoPlay: autoPlay,
      );
      return;
    }

    await playContinuous(
      surah: surah,
      startAyah: 1,
      reciter: r,
      autoPlay: autoPlay,
    );
  }

  /// Play continuous verses (e.g. whole Surah or Page)
  Future<void> playContinuous({
    required int surah,
    required int startAyah,
    int? endAyah,
    QuranReciter? reciter,
    bool autoPlay = true,
  }) async {
    if (!isValidSurah(surah) || !isValidVerse(surah, startAyah)) return;
    final r = reciter ?? _selectedReciter;
    if (r.isSurahBased) {
      await playFullSurah(surah: surah, reciter: r, autoPlay: autoPlay);
      return;
    }
    final totalVerses = quran.getVerseCount(surah);
    // If starting from verse 1 for full surah and offline recording exists,
    // play the full recording directly for a single, unbroken listening experience.
    if (_sourceResolver == null &&
        startAyah == 1 &&
        (endAyah == null || endAyah >= totalVerses)) {
      final fullFile = await QuranAudioFrameMerger.getFullSurahAudioFile(
        surah,
        reciter: r,
      );
      if (fullFile != null && fullFile.existsSync()) {
        await playFullSurah(surah: surah, reciter: r, autoPlay: autoPlay);
        return;
      }
    }
    _ayahRepeatCount = 0;
    _isContinuous = true;
    _isSingleVerseOnly = false;
    isFullSurahModeNotifier.value = false;
    _hasExplicitEnd = endAyah != null;
    _endAyah = endAyah ?? totalVerses;
    await _startPlay(surah, startAyah, reciter: r, autoPlay: autoPlay);
  }

  static final Uri _appIconUri = Uri.parse(
    'android.resource://com.talibilm.app/drawable/quran_artwork',
  );

  MediaItem _buildSurahMediaItem(
    int surah,
    QuranReciter r,
    String surahName, [
    Duration? duration,
  ]) =>
      MediaItem(
        id: '${r.id}_surah_$surah',
        album: 'القرآن الكريم',
        title: 'سورة $surahName',
        artist: r.name,
        artUri: _appIconUri,
        duration: duration,
        displayTitle: 'سورة $surahName',
        displaySubtitle: r.name,
        displayDescription: 'تلاوة سورة $surahName كاملة · ${r.name}',
      );

  MediaItem _buildAyahMediaItem(
    int surah,
    int ayah,
    QuranReciter r,
    String surahName,
  ) => MediaItem(
    id: '${r.id}_${surah}_$ayah',
    album: 'سورة $surahName',
    title: 'الآية $ayah - سورة $surahName',
    artist: r.name,
    artUri: _appIconUri,
    displayTitle: 'سورة $surahName',
    displaySubtitle: 'الآية $ayah · ${r.name}',
    displayDescription: 'تلاوة القرآن الكريم - طالب العلم',
  );

  /// Resolves the audio source: uses locally downloaded file if exists, otherwise streams from URL.
  Future<AudioSource> getAudioSource(
    int surah,
    int ayah, {
    QuranReciter? reciter,
  }) async {
    final r = reciter ?? _selectedReciter;
    if (_sourceResolver != null) return _sourceResolver!(surah, ayah, r);
    final surahName = quran.getSurahNameArabic(surah);
    final tag = _buildAyahMediaItem(surah, ayah, r, surahName);

    if (r.isSurahBased) {
      final fullFile = await QuranAudioFrameMerger.getFullSurahAudioFile(
        surah,
        reciter: r,
      );
      if (fullFile != null && fullFile.existsSync()) {
        return AudioSource.file(fullFile.path, tag: tag);
      }
      final url = getAudioUrl(surah, ayah, reciter: r);
      return AudioSource.uri(Uri.parse(url), tag: tag);
    }

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

  Future<void> _startPlay(
    int surah,
    int ayah, {
    QuranReciter? reciter,
    bool autoPlay = true,
  }) async {
    if (_disposed) return;
    final operation = ++_operation;
    clearError();
    final r = reciter ?? _playbackReciter ?? _selectedReciter;
    _playbackReciter = r;
    _isTransitioning = true;
    _playWhenReady = autoPlay;
    isLoadingNotifier.value = true;
    _completionArmed = false;
    activeSurahNotifier.value = surah;
    activeAyahNotifier.value = ayah;
    if (autoPlay) {
      unawaited(AudioCoordinator.acquireFocus(AudioStreamType.quran));
    }

    try {
      for (var attempt = 0; attempt < 3; attempt++) {
        if (!_ownsOperation(operation)) return;
        final player = _player;
        final audioSource = await getAudioSource(surah, ayah, reciter: r);
        if (!_ownsOperation(operation)) return;
        final url = getAudioUrl(surah, ayah, reciter: r);

        bool loaded = false;
        try {
          if (attempt > 0 || player.processingState == ProcessingState.idle) {
            await player.stop();
          }
          if (!_ownsOperation(operation)) return;
          // Do not wait for the remote server to probe the entire source
          // before starting playback. Let just_audio buffer while playing;
          // this removes the long silent spinner on slower connections.
          await player
              .setAudioSource(audioSource, preload: false)
              .timeout(AppPolicy.networkTimeout);
          loaded = true;
        } catch (sourceErr) {
          if (!_ownsOperation(operation)) return;
          debugPrint(
            'setAudioSource failed ($url): $sourceErr, trying direct setUrl',
          );
          try {
            await player.setUrl(url).timeout(AppPolicy.networkTimeout);
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
      if (_ownsOperation(operation)) {
        _isTransitioning = false;
        isLoadingNotifier.value = false;
      }
    }
  }

  Future<void> _startPlaySource(
    int surah,
    int ayah, {
    required AudioSource audioSource,
    QuranReciter? reciter,
    bool autoPlay = true,
  }) async {
    if (_disposed) return;
    final operation = ++_operation;
    clearError();
    final r = reciter ?? _playbackReciter ?? _selectedReciter;
    _playbackReciter = r;
    _isTransitioning = true;
    _playWhenReady = autoPlay;
    isLoadingNotifier.value = true;
    _completionArmed = false;
    activeSurahNotifier.value = surah;
    activeAyahNotifier.value = ayah;
    if (autoPlay) {
      unawaited(AudioCoordinator.acquireFocus(AudioStreamType.quran));
    }

    try {
      if (!_ownsOperation(operation)) return;
      final player = _player;
      if (player.processingState == ProcessingState.idle) {
        await player.stop();
      }
      await player
          .setAudioSource(audioSource, preload: false)
          .timeout(AppPolicy.networkTimeout);
      if (!_ownsOperation(operation)) return;
      await player.setSpeed(speedNotifier.value);
      if (!_ownsOperation(operation)) return;
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
    } catch (e) {
      await _handlePlaybackError(e, operation);
    } finally {
      if (_ownsOperation(operation)) {
        _isTransitioning = false;
        isLoadingNotifier.value = false;
      }
    }
  }

  void _handleTrackCompleted() {
    final surah = activeSurahNotifier.value;
    final ayah = activeAyahNotifier.value;

    if (surah == null || ayah == null) return;

    if (_isTransitioning || !_completionArmed || !_playWhenReady) return;
    _completionArmed = false;
    _isTransitioning = true;

    // 0. Full Surah Mode (single continuous recording of the whole surah)
    if (isFullSurahMode) {
      if (repeatModeNotifier.value == AudioRepeatMode.infinite) {
        playFullSurah(surah: surah, reciter: _playbackReciter);
        return;
      }
      if (repeatModeNotifier.value == AudioRepeatMode.repeatOnce) {
        if (_ayahRepeatCount < 1) {
          _ayahRepeatCount++;
          playFullSurah(surah: surah, reciter: _playbackReciter);
          return;
        }
        _ayahRepeatCount = 0;
      }
      if (stopAtEndOfSurahNotifier.value) {
        stopAtEndOfSurahNotifier.value = false;
        stop();
        return;
      }
      if (!_hasExplicitEnd && surah < 114) {
        playFullSurah(surah: surah + 1, reciter: _playbackReciter);
      } else {
        stop();
      }
      return;
    }

    // 1. Infinite Repeat Mode (stays repeating the exact same ayah indefinitely)
    if (repeatModeNotifier.value == AudioRepeatMode.infinite) {
      _startPlay(surah, ayah);
      return;
    }

    // 2. Verse Repetition Mode (supports repeatOnce and multi-count Hifdh repetitions)
    final repeatTarget = _verseRepeatTarget > 1
        ? _verseRepeatTarget
        : (repeatModeNotifier.value == AudioRepeatMode.repeatOnce ? 2 : 1);
    if (repeatTarget > 1) {
      if (_ayahRepeatCount < repeatTarget - 1) {
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

    // 4. Hifdh Range Loop Mode (repeats a custom range of ayahs for memorization)
    final rangeConfig = hifdhRangeNotifier.value;
    if (rangeConfig != null && rangeConfig.surah == surah) {
      if (ayah < rangeConfig.endAyah) {
        _startPlay(surah, ayah + 1);
      } else {
        // Reached end of range
        if (rangeConfig.isInfinite ||
            rangeConfig.currentIteration + 1 < rangeConfig.repeatCount) {
          hifdhRangeNotifier.value = rangeConfig.nextIteration();
          _startPlay(surah, rangeConfig.startAyah);
        } else {
          hifdhRangeNotifier.value = null;
          stop();
        }
      }
      return;
    }

    final totalVerses = quran.getVerseCount(surah);
    final limit = (_isContinuous && _endAyah > 0) ? _endAyah : totalVerses;

    // 4. Continuous / Standard Playback (sequential verse by verse)
    if (_isContinuous) {
      if (ayah < limit) {
        _startPlay(surah, ayah + 1);
      } else if (!_hasExplicitEnd && surah < 114) {
        if (stopAtEndOfSurahNotifier.value) {
          stopAtEndOfSurahNotifier.value = false;
          stop();
          return;
        }
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
    if (mode == AudioRepeatMode.none) {
      _verseRepeatTarget = 1;
      verseRepeatTargetNotifier.value = 1;
    } else if (mode == AudioRepeatMode.repeatOnce) {
      _verseRepeatTarget = 2;
      verseRepeatTargetNotifier.value = 2;
    } else if (mode == AudioRepeatMode.infinite) {
      _verseRepeatTarget = 0;
      verseRepeatTargetNotifier.value = 0;
    }
  }

  void setVerseRepeatCount(int count) {
    _verseRepeatTarget = count;
    verseRepeatTargetNotifier.value = count;
    if (count == 0) {
      repeatModeNotifier.value = AudioRepeatMode.infinite;
    } else if (count == 1) {
      repeatModeNotifier.value = AudioRepeatMode.none;
    } else {
      repeatModeNotifier.value = AudioRepeatMode.repeatOnce;
    }
  }

  Future<void> playHifdhRange({
    required int surah,
    required int startAyah,
    required int endAyah,
    int repeatCount = 1,
    QuranReciter? reciter,
  }) async {
    final effectiveStart = startAyah.clamp(1, endAyah);
    final effectiveEnd = endAyah.clamp(
      effectiveStart,
      quran.getVerseCount(surah),
    );
    hifdhRangeNotifier.value = HifdhRangeConfig(
      surah: surah,
      startAyah: effectiveStart,
      endAyah: effectiveEnd,
      repeatCount: repeatCount,
      currentIteration: 0,
    );
    await playContinuous(
      surah: surah,
      startAyah: effectiveStart,
      endAyah: effectiveEnd,
      reciter: reciter,
    );
  }

  void clearHifdhRange() {
    hifdhRangeNotifier.value = null;
  }

  Future<void> cycleRepeatMode() async {
    switch (repeatModeNotifier.value) {
      case AudioRepeatMode.none:
        await setRepeatMode(AudioRepeatMode.infinite);
        break;
      case AudioRepeatMode.infinite:
        await setRepeatMode(AudioRepeatMode.repeatOnce);
        break;
      case AudioRepeatMode.repeatOnce:
        await setRepeatMode(AudioRepeatMode.none);
        break;
    }
  }

  void setSleepTimer(int? minutes, {bool atEndOfSurah = false}) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerEndTime = null;
    stopAtEndOfSurahNotifier.value = atEndOfSurah;
    sleepTimerMinutesNotifier.value = minutes;

    if (minutes != null && minutes > 0) {
      final totalSeconds = minutes * 60;
      _sleepTimerEndTime = DateTime.now().add(Duration(minutes: minutes));
      sleepTimerRemainingSecondsNotifier.value = totalSeconds;

      _sleepTimer = Timer.periodic(AppPolicy.oneSecond, (timer) {
        if (_sleepTimerEndTime == null || _disposed) {
          timer.cancel();
          return;
        }
        final remaining = _sleepTimerEndTime!
            .difference(DateTime.now())
            .inSeconds;
        if (remaining <= 0) {
          timer.cancel();
          _triggerSleepTimer();
        } else {
          sleepTimerRemainingSecondsNotifier.value = remaining;
        }
      });
    } else {
      sleepTimerRemainingSecondsNotifier.value = null;
    }
  }

  void _triggerSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerEndTime = null;
    sleepTimerMinutesNotifier.value = null;
    sleepTimerRemainingSecondsNotifier.value = null;
    stopAtEndOfSurahNotifier.value = false;
    pause();
  }

  Future<void> nextSurah() async {
    final s = activeSurahNotifier.value;
    if (s == null) return;
    if (s < 114) {
      if (isFullSurahMode || selectedReciter.isSurahBased) {
        await playFullSurah(surah: s + 1, reciter: _playbackReciter);
      } else {
        await playContinuous(
          surah: s + 1,
          startAyah: 1,
          reciter: _playbackReciter,
        );
      }
    } else {
      await stop();
    }
  }

  Future<void> previousSurah() async {
    final s = activeSurahNotifier.value;
    if (s == null) return;
    if (_player.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    if (s > 1) {
      if (isFullSurahMode || selectedReciter.isSurahBased) {
        await playFullSurah(surah: s - 1, reciter: _playbackReciter);
      } else {
        await playContinuous(
          surah: s - 1,
          startAyah: 1,
          reciter: _playbackReciter,
        );
      }
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> nextAyah() async {
    final s = activeSurahNotifier.value, a = activeAyahNotifier.value;
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
    final s = activeSurahNotifier.value, a = activeAyahNotifier.value;
    if (s == null || a == null) return;
    if (a > 1) {
      await _navigateTo(s, a - 1);
    } else if (s > 1) {
      await _navigateTo(s - 1, quran.getVerseCount(s - 1));
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
    isFullSurahModeNotifier.value = false;
    hifdhRangeNotifier.value = null;
    activeSurahNotifier.value = null;
    activeAyahNotifier.value = null;
    isPlayingNotifier.value = false;
    isLoadingNotifier.value = false;
    _isContinuous = false;
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerEndTime = null;
    sleepTimerMinutesNotifier.value = null;
    sleepTimerRemainingSecondsNotifier.value = null;
    stopAtEndOfSurahNotifier.value = false;
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
    _sleepTimer = null;
    _sleepTimerEndTime = null;
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    errorNotifier.dispose();
    selectedReciterNotifier.dispose();
    isLoadingNotifier.dispose();
    stopAtEndOfSurahNotifier.dispose();
    sleepTimerRemainingSecondsNotifier.dispose();
    isFullSurahModeNotifier.dispose();
    _player.dispose();
  }
}
