import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;
import 'dart:io';

import '../../../../core/constants/app_policy.dart';
import '../../../../core/services/audio_coordinator.dart';
import '../models/audio_playback_error.dart';
import '../models/hifdh_range_config.dart';
import '../models/quran_reciter.dart';
import 'hifdh_audio_range_helper.dart';
import 'quran_audio_downloader.dart';
import 'quran_audio_frame_merger.dart';
import 'quran_surah_queue_resolver.dart';

export '../models/audio_playback_error.dart';
export '../models/hifdh_range_config.dart';
export '../models/quran_reciter.dart';

part 'quran_audio_service_hifdh.dart';
part 'quran_audio_service_modes.dart';
part 'quran_audio_service_playback.dart';

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

  static List<QuranReciter> get reciters => QuranReciter.defaultReciters;

  QuranReciter _selectedReciter = reciters[0];
  QuranReciter get selectedReciter => _selectedReciter;
  QuranReciter get activeReciter => _playbackReciter ?? _selectedReciter;
  final ValueNotifier<QuranReciter> selectedReciterNotifier =
      ValueNotifier<QuranReciter>(QuranReciter.defaultReciters.first);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

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
  bool _isTransitioning = false,
      _completionArmed = false,
      _disposed = false,
      _isSeekingFullSurah = false;
  int _endAyah = 0,
      _operation = 0,
      _ayahRepeatCount = 0,
      _surahRepeatIteration = 0,
      _verseRepeatTarget = 1,
      _pendingInitialSeekAyah = 1;
  QuranReciter? _playbackReciter;
  List<int>? _surahPlaybackQueue;
  bool _downloadedQueueOnly = false;

  /// Active queue of surah numbers (e.g. downloaded surahs list) for auto-advancing,
  /// nextSurah(), and previousSurah().
  List<int>? get surahPlaybackQueue => _surahPlaybackQueue;
  bool get isDownloadedQueueOnly => _downloadedQueueOnly;
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

  int get _safeDurationMs {
    try {
      return _player.duration?.inMilliseconds ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static bool isValidSurah(int surah) =>
      QuranSurahQueueResolver.isValidSurah(surah);

  static bool isValidVerse(int surah, int ayah) =>
      QuranSurahQueueResolver.isValidVerse(surah, ayah);

  static AudioPlaybackError classifyError(dynamic e) =>
      AudioPlaybackError.classify(e);

  void setSelectedReciter(QuranReciter reciter) {
    _selectedReciter = reciter;
    selectedReciterNotifier.value = reciter;
  }

  /// Changes the reciter for the active session and resumes at its current
  /// reading position, preserving pause state, speed, and continuation bounds.
  Future<void> switchReciter(QuranReciter reciter) =>
      _switchReciterImpl(reciter);

  void setSurahPlaybackQueue(List<int>? queue, {bool downloadedOnly = true}) {
    if (queue == null || queue.isEmpty) {
      _surahPlaybackQueue = null;
      _downloadedQueueOnly = false;
    } else {
      _surahPlaybackQueue = List<int>.unmodifiable(queue);
      _downloadedQueueOnly = downloadedOnly;
    }
  }

  void clearSurahPlaybackQueue() {
    _surahPlaybackQueue = null;
    _downloadedQueueOnly = false;
  }

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
          unawaited(_handleTrackCompleted());
        }
      },
      onError: (Object e) {
        if (_disposed || player != _player || _isTransitioning) return;
        debugPrint('QuranAudioService stream error: $e');
        _handlePlaybackError(e);
      },
    );
    try {
      _positionSub = _player.positionStream.listen((pos) {
        if (_disposed || player != _player) return;
        if (_sleepTimerEndTime != null &&
            DateTime.now().isAfter(_sleepTimerEndTime!)) {
          _triggerSleepTimer();
          return;
        }
        if (isFullSurahMode && !_isTransitioning && !_isSeekingFullSurah) {
          final durMs = _safeDurationMs;
          if (durMs > 0) {
            _handleFullSurahPositionTick(pos.inMilliseconds, durMs);
          }
        }
      });
    } catch (_) {}
  }

  String getAudioUrl(int surah, int ayah, {QuranReciter? reciter}) =>
      QuranSurahQueueResolver.buildAudioUrl(
        surah,
        ayah,
        reciter: reciter ?? _selectedReciter,
      );

  /// Play a single verse
  Future<void> playVerse(
    int surah,
    int ayah, {
    QuranReciter? reciter,
    bool singleVerse = false,
    bool autoPlay = true,
  }) =>
      _playVerseImpl(
        surah,
        ayah,
        reciter: reciter,
        singleVerse: singleVerse,
        autoPlay: autoPlay,
      );

  /// Plays full surah recorded audio as a single continuous track if downloaded
  /// or if reciter is surah-based; otherwise delegates to continuous verse playback.
  Future<void> playFullSurah({
    required int surah,
    QuranReciter? reciter,
    bool autoPlay = true,
    bool hasExplicitEnd = false,
    int initialAyah = 1,
    List<int>? queue,
    bool isRepeatCycle = false,
  }) =>
      _playFullSurahImpl(
        surah: surah,
        reciter: reciter,
        autoPlay: autoPlay,
        hasExplicitEnd: hasExplicitEnd,
        initialAyah: initialAyah,
        queue: queue,
        isRepeatCycle: isRepeatCycle,
      );

  /// Play continuous verses (e.g. whole Surah or Page)
  Future<void> playContinuous({
    required int surah,
    required int startAyah,
    int? endAyah,
    QuranReciter? reciter,
    bool autoPlay = true,
    List<int>? queue,
  }) =>
      _playContinuousImpl(
        surah: surah,
        startAyah: startAyah,
        endAyah: endAyah,
        reciter: reciter,
        autoPlay: autoPlay,
        queue: queue,
      );

  /// Resolves the audio source: uses locally downloaded file if exists, otherwise streams from URL.
  Future<AudioSource> getAudioSource(
    int surah,
    int ayah, {
    QuranReciter? reciter,
  }) =>
      _getAudioSourceImpl(surah, ayah, reciter: reciter);

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
        if (isFullSurahMode) {
          await playFullSurah(
            surah: activeSurahNotifier.value!,
            reciter: _playbackReciter,
            initialAyah: activeAyahNotifier.value ?? 1,
            autoPlay: true,
          );
        } else {
          await _startPlay(activeSurahNotifier.value!, activeAyahNotifier.value!);
        }
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
    _surahRepeatIteration = 0;
    _verseRepeatTarget = 1;
    verseRepeatTargetNotifier.value = 1;
  }

  void setVerseRepeatCount(int count) => _setVerseRepeatCountImpl(count);

  Future<void> playHifdhRange({
    required int surah,
    required int startAyah,
    required int endAyah,
    int repeatCount = 1,
    QuranReciter? reciter,
  }) =>
      _playHifdhRangeImpl(
        surah: surah,
        startAyah: startAyah,
        endAyah: endAyah,
        repeatCount: repeatCount,
        reciter: reciter,
      );

  void clearHifdhRange() => hifdhRangeNotifier.value = null;

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

  void setSleepTimer(int? minutes, {bool atEndOfSurah = false}) =>
      _setSleepTimerImpl(minutes, atEndOfSurah: atEndOfSurah);

  Future<void> nextSurah() => _nextSurahImpl();
  Future<void> previousSurah() => _previousSurahImpl();
  Future<void> nextAyah() => _nextAyahImpl();
  Future<void> previousAyah() => _previousAyahImpl();
  Future<void> _navigateTo(int surah, int ayah) =>
      _navigateToImpl(surah, ayah);

  Future<void> stop() async {
    if (_disposed) return;
    AudioCoordinator.releaseFocus(AudioStreamType.quran);
    ++_operation;
    _completionArmed = false;
    _playWhenReady = false;
    _playbackReciter = null;
    _ayahRepeatCount = 0;
    _surahRepeatIteration = 0;
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

  // Internal delegation bridges for split part libraries
  Future<void> _recreatePlayer(int operation) => _recreatePlayerImpl(operation);
  Future<void> _handlePlaybackError(dynamic e, [int? operation]) =>
      _handlePlaybackErrorImpl(e, operation);
  void _handleFullSurahPositionTick(int posMs, int durMs) =>
      _handleFullSurahPositionTickImpl(posMs, durMs);
  Future<void> _seekWithinFullSurah(int targetMs) =>
      _seekWithinFullSurahImpl(targetMs);
  Future<void> _startPlay(
    int surah,
    int ayah, {
    QuranReciter? reciter,
    bool autoPlay = true,
  }) =>
      _startPlayImpl(surah, ayah, reciter: reciter, autoPlay: autoPlay);
  Future<void> _startPlaySource(
    int surah,
    int ayah, {
    required AudioSource audioSource,
    QuranReciter? reciter,
    bool autoPlay = true,
  }) =>
      _startPlaySourceImpl(
        surah,
        ayah,
        audioSource: audioSource,
        reciter: reciter,
        autoPlay: autoPlay,
      );
  Future<void> _handleTrackCompleted() => _handleTrackCompletedImpl();
  Future<void> _restartCurrentFullSurah(int surah) =>
      _restartCurrentFullSurahImpl(surah);
  void _triggerSleepTimer() => _triggerSleepTimerImpl();

  Future<int?> _resolveNextSurah(int currentSurah, QuranReciter? reciter) =>
      QuranSurahQueueResolver.resolveAdjacentSurah(
        currentSurah: currentSurah,
        step: 1,
        reciter: reciter ?? _selectedReciter,
        playbackQueue: _surahPlaybackQueue,
        downloadedQueueOnly: _downloadedQueueOnly,
        repeatMode: repeatModeNotifier.value,
      );

  Future<int?> _resolvePreviousSurah(int currentSurah, QuranReciter? reciter) =>
      QuranSurahQueueResolver.resolveAdjacentSurah(
        currentSurah: currentSurah,
        step: -1,
        reciter: reciter ?? _selectedReciter,
        playbackQueue: _surahPlaybackQueue,
        downloadedQueueOnly: _downloadedQueueOnly,
        repeatMode: repeatModeNotifier.value,
      );
}
