import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/constants/app_policy.dart';
import '../../../../core/services/audio_coordinator.dart';
import '../../../../core/services/offline_connectivity_service.dart';
import '../catalogs/mutun_audio_catalog.dart';
import 'mutun_audio_source_loader.dart';
export '../catalogs/mutun_audio_catalog.dart'
    show BookAudioChapter, BookAudioEdition, MatnAudioSource, MutunReciter, MutunReciterDefaults, MutunRepeatMode;

class MutunAudioService {
  static final MutunAudioService _instance = MutunAudioService._internal();
  factory MutunAudioService() => _instance;
  MutunAudioService._internal() : _loader = MutunAudioSourceLoader() {
    _initAudioListener();
    OfflineConnectivityService().isOfflineNotifier.addListener(_onConnectivityChanged);
  }

  @visibleForTesting
  MutunAudioService.forTesting({
    AudioPlayer? player,
    MutunAudioSourceLoader? loader,
    AudioPlayer Function()? playerFactory,
  }) : _loader = loader ?? MutunAudioSourceLoader() {
    if (playerFactory != null) _playerFactory = playerFactory;
    if (player != null) _player = player;
    _initAudioListener();
    OfflineConnectivityService().isOfflineNotifier.addListener(_onConnectivityChanged);
  }

  final MutunAudioSourceLoader _loader;
  AudioPlayer Function() _playerFactory = () => AudioPlayer();
  AudioPlayer _player = AudioPlayer();
  StreamSubscription? _playerStateSub, _playbackEventSub, _positionSub, _durationSub, _currentIndexSub;
  Future<void>? _recreatingFuture;
  bool _isLoadingInFlight = false;
  bool _lastLoadFailed = false;
  int _loadOp = 0;

  void _onConnectivityChanged() {
    if (!OfflineConnectivityService().isOfflineNotifier.value) {
      _loader.resetTransientFailures();
      if (playbackErrorNotifier.value != null) playbackErrorNotifier.value = null;
    }
  }

  void _ensurePlayerActive() {
    try {
      final _ = _player.processingState;
    } catch (_) {
      unawaited(_recreatePlayer());
    }
  }

  Future<void> _recreatePlayer() {
    if (_recreatingFuture != null) return _recreatingFuture!;
    final completer = Completer<void>();
    _recreatingFuture = completer.future;
    () async {
      try {
        _cancelSubscriptions();
        final prev = _player;
        _player = _playerFactory();
        _initAudioListener();
        try { await prev.dispose(); } catch (_) {}
      } finally {
        _recreatingFuture = null;
        if (!completer.isCompleted) completer.complete();
      }
    }();
    return completer.future;
  }

  void _cancelSubscriptions() {
    for (final s in [_playerStateSub, _playbackEventSub, _positionSub, _durationSub, _currentIndexSub]) {
      s?.cancel();
    }
  }

  static const List<MutunReciter> defaultReciters = [
    MutunReciterDefaults.sini, MutunReciterDefaults.haliba, MutunReciterDefaults.shaydzmi,
    MutunReciterDefaults.fahad, MutunReciterDefaults.suwaid, MutunReciterDefaults.afasy,
  ];
  static const List<MutunReciter> availableReciters = defaultReciters;

  MutunReciter _selectedReciter = MutunReciterDefaults.sini;
  MutunReciter get selectedReciter => _selectedReciter;

  final activeBookIdNotifier = ValueNotifier<String?>(null);
  final activeParagraphNotifier = ValueNotifier<int?>(null);
  final activeChapterIndexNotifier = ValueNotifier<int>(0);
  final isPlayingNotifier = ValueNotifier<bool>(false);
  final isLoadingNotifier = ValueNotifier<bool>(false);
  final speedNotifier = ValueNotifier<double>(1.0);
  final repeatModeNotifier = ValueNotifier<MutunRepeatMode>(MutunRepeatMode.none);
  final selectedReciterNotifier = ValueNotifier<MutunReciter>(MutunReciterDefaults.sini);
  final positionNotifier = ValueNotifier<Duration>(Duration.zero);
  final durationNotifier = ValueNotifier<Duration>(Duration.zero);
  final playbackErrorNotifier = ValueNotifier<String?>(null);

  String? _currentAudioUrl;
  int _totalParagraphs = 1;
  bool _isMultiChapterActive = false;

  List<MutunReciter> getAvailableRecitersForBook(String? bookId) =>
      MutunAudioCatalog.getRecitersForBook(bookId);

  MutunReciter effectiveReciterForBook(String? bookId) =>
      _loader.effectiveReciterForBook(bookId, _selectedReciter);

  MatnAudioSource? getSourceForBook(String? bookId, {String? reciterId}) {
    if (bookId == null) return null;
    final effectiveId = reciterId ?? effectiveReciterForBook(bookId).id;
    return MutunAudioCatalog.getSource(bookId, reciterId: effectiveId);
  }

  List<BookAudioChapter> getChaptersForBook(String? bookId, {String? reciterId}) =>
      getSourceForBook(bookId, reciterId: reciterId)?.chapters ??
      const <BookAudioChapter>[];

  bool get hasAudio =>
      activeBookIdNotifier.value != null &&
      MutunAudioCatalog.hasAudio(activeBookIdNotifier.value!);

  void _initAudioListener() {
    AudioCoordinator.onPauseMutun = pause;
    _cancelSubscriptions();

    _playerStateSub = _player.playerStateStream.listen((state) {
      final isPlaying = state.playing &&
          state.processingState != ProcessingState.completed &&
          state.processingState != ProcessingState.idle;
      final isLoading = (state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering) &&
          !state.playing;
      if (isPlayingNotifier.value != isPlaying) isPlayingNotifier.value = isPlaying;
      if (isLoadingNotifier.value != isLoading) isLoadingNotifier.value = isLoading;
      if (state.processingState == ProcessingState.completed) _handleTrackCompletion();
    }, onError: (Object err) {
      debugPrint('Audio player state error: $err');
      if (_isLoadingInFlight) return;
      unawaited(_handleAsyncStreamError());
    });

    _playbackEventSub = _player.playbackEventStream.listen((_) {}, onError: (Object err) {
      debugPrint('Audio playback error: $err');
      if (_isLoadingInFlight) return;
      unawaited(_handleAsyncStreamError());
    });

    _positionSub = _player.positionStream.listen((pos) {
      positionNotifier.value = pos;
      _updateActiveParagraph(pos);
    });
    _durationSub = _player.durationStream.listen((dur) {
      if (dur != null) {
        durationNotifier.value = dur;
        _updateActiveParagraph(_player.position);
      }
    });
    _currentIndexSub = _player.currentIndexStream.listen((idx) {
      if (idx != null && activeChapterIndexNotifier.value != idx) {
        activeChapterIndexNotifier.value = idx;
        final bookId = activeBookIdNotifier.value;
        if (bookId != null && _isMultiChapterActive) {
          _loader.persistBookChapter(bookId, _selectedReciter.id, idx);
        }
      }
    });
  }

  Future<void> _handleAsyncStreamError() async {
    final wasPlaying = isPlayingNotifier.value;
    final bookId = activeBookIdNotifier.value;
    await _recreatePlayer();
    final isOffline = await OfflineConnectivityService().checkConnectivity();
    if (!isOffline && wasPlaying && bookId != null && !_isMultiChapterActive) {
      await _reloadBook(bookId, keepPosition: true, isFallback: true);
      return;
    }
    _lastLoadFailed = true;
    _currentAudioUrl = null;
    isLoadingNotifier.value = false;
    isPlayingNotifier.value = false;
    playbackErrorNotifier.value = await _loader.resolveErrorMessage();
  }

  Future<void> _reloadBook(String bookId, {bool keepPosition = true, bool isFallback = false}) async {
    await playMatnAudio(
      bookId: bookId,
      audioUrl: _urlForBook(bookId),
      paragraphIndex: keepPosition ? (activeParagraphNotifier.value ?? 1) : 1,
      totalParagraphs: MutunAudioCatalog.getTotalParagraphs(bookId, reciterId: _selectedReciter.id),
      initialPosition: keepPosition && positionNotifier.value > Duration.zero ? positionNotifier.value : null,
      isFallbackAttempt: isFallback,
    );
  }

  Future<void> syncReciterForBook(String bookId) async {
    if ((isPlayingNotifier.value || isLoadingNotifier.value) &&
        activeBookIdNotifier.value != null &&
        activeBookIdNotifier.value != bookId) {
      return;
    }
    final chosen = await _loader.pickReciterForBook(bookId, _selectedReciter);
    if (chosen == null) return;
    if (_selectedReciter.id != chosen.id) {
      _selectedReciter = chosen;
      selectedReciterNotifier.value = chosen;
    }
    if (activeBookIdNotifier.value != bookId) {
      final chapters = getChaptersForBook(bookId, reciterId: chosen.id);
      activeChapterIndexNotifier.value =
          await _loader.loadSavedChapter(bookId, chosen.id, chapters.length);
    }
  }

  void _updateActiveParagraph(Duration pos) {
    if (isLoadingNotifier.value || _isMultiChapterActive) return;
    final activeIndex = _loader.computeActiveParagraph(
      bookId: activeBookIdNotifier.value,
      reciterId: _selectedReciter.id,
      pos: pos,
      duration: durationNotifier.value,
      totalParagraphs: _totalParagraphs,
    );
    if (activeIndex != null && activeParagraphNotifier.value != activeIndex) {
      activeParagraphNotifier.value = activeIndex;
    }
  }

  void _handleTrackCompletion() {
    final mode = repeatModeNotifier.value;
    if (_isMultiChapterActive) {
      mode == MutunRepeatMode.entireMatn ? seekToChapter(0) : stop();
      return;
    }
    if (mode == MutunRepeatMode.singleParagraph ||
        mode == MutunRepeatMode.entireMatn) {
      _player.seek(Duration.zero);
      _player.play();
    } else {
      stop();
    }
  }

  void setSelectedReciter(MutunReciter reciter, {String? forBookId}) {
    final targetBookId = forBookId ?? activeBookIdNotifier.value;
    if (_selectedReciter.id == reciter.id) return;
    _selectedReciter = reciter;
    selectedReciterNotifier.value = reciter;
    activeChapterIndexNotifier.value = 0;
    if (targetBookId != null) {
      _loader.persistReciterChoice(targetBookId, reciter.id);
      final chapters = getChaptersForBook(targetBookId, reciterId: reciter.id);
      if (chapters.length > 1) {
        _loader.loadSavedChapter(targetBookId, reciter.id, chapters.length).then((idx) {
          if (_selectedReciter.id == reciter.id && !isPlayingNotifier.value) {
            activeChapterIndexNotifier.value = idx;
          }
        });
      }
    }
    final activeBook = activeBookIdNotifier.value;
    if (activeBook != null && (forBookId == null || forBookId == activeBook)) {
      _lastLoadFailed = false;
      _currentAudioUrl = null;
      playbackErrorNotifier.value = null;
      durationNotifier.value = Duration.zero;
      positionNotifier.value = Duration.zero;
      if (isPlayingNotifier.value || isLoadingNotifier.value) {
        final newUrl =
            MutunAudioCatalog.getAudioUrl(activeBook, reciterId: reciter.id) ??
                '';
        if (newUrl.isNotEmpty) {
          playMatnAudio(
            bookId: activeBook,
            audioUrl: newUrl,
            paragraphIndex: activeParagraphNotifier.value ?? 1,
            totalParagraphs: _totalParagraphs,
          );
        }
      }
    }
  }

  void setRepeatMode(MutunRepeatMode mode) {
    repeatModeNotifier.value = mode;
    _applyLoopMode(mode);
  }

  void toggleRepeatMode() {
    const m = [MutunRepeatMode.none, MutunRepeatMode.singleParagraph, MutunRepeatMode.entireMatn];
    setRepeatMode(m[(m.indexOf(repeatModeNotifier.value) + 1) % m.length]);
  }

  void _applyLoopMode(MutunRepeatMode mode) {
    if (!_isMultiChapterActive) return;
    try {
      _player.setLoopMode(switch (mode) {
        MutunRepeatMode.none => LoopMode.off,
        MutunRepeatMode.singleParagraph => LoopMode.one,
        MutunRepeatMode.entireMatn => LoopMode.all,
      });
    } catch (_) {}
  }

  Future<void> setSpeed(double speed) async {
    speedNotifier.value = speed;
    try {
      await _player.setSpeed(speed);
    } catch (_) {}
  }

  void cycleSpeed() {
    const s = [0.75, 1.0, 1.25, 1.5, 2.0];
    setSpeed(s[(s.indexOf(speedNotifier.value) + 1) % s.length]);
  }

  Future<void> playMatnAudio({
    required String bookId,
    required String audioUrl,
    int paragraphIndex = 1,
    int totalParagraphs = 1,
    int? initialChapterIndex,
    Duration? initialPosition,
    bool isFallbackAttempt = false,
  }) async {
    if (audioUrl.isEmpty) {
      isLoadingNotifier.value = false;
      isPlayingNotifier.value = false;
      playbackErrorNotifier.value = 'لا يتوفر تسجيل صوتي لهذا الكتاب';
      return;
    }

    final op = ++_loadOp;
    _isLoadingInFlight = true;
    final switchingBook = activeBookIdNotifier.value != bookId;
    if (switchingBook || _lastLoadFailed || initialPosition == null) {
      durationNotifier.value = Duration.zero;
      positionNotifier.value = initialPosition ?? Duration.zero;
    }

    activeBookIdNotifier.value = bookId;
    activeParagraphNotifier.value = paragraphIndex;
    final resolvedTotal = totalParagraphs > 1
        ? totalParagraphs
        : MutunAudioCatalog.getTotalParagraphs(bookId, reciterId: _selectedReciter.id);
    _totalParagraphs = resolvedTotal > 1 ? resolvedTotal : 1;
    final hadPreviousFailure = _lastLoadFailed;
    _lastLoadFailed = false;
    isLoadingNotifier.value = true;
    playbackErrorNotifier.value = null;

    if (!isFallbackAttempt) _loader.resetTransientFailures();
    await AudioCoordinator.acquireFocus(AudioStreamType.mutun);
    if (_recreatingFuture != null) await _recreatingFuture;
    if (op != _loadOp) return;

    if (hadPreviousFailure) {
      await _recreatePlayer();
    } else {
      try {
        await _player.stop();
      } catch (_) {
        await _recreatePlayer();
      }
    }
    if (op != _loadOp) return;

    final res = await _loader.loadWithFallback(
      getPlayer: () => _player,
      recreatePlayer: _recreatePlayer,
      bookId: bookId,
      requestedUrl: audioUrl,
      reciter: _selectedReciter,
      initialChapterIndex: initialChapterIndex,
      initialPosition: initialPosition,
      isFallbackAttempt: isFallbackAttempt,
    );
    if (op != _loadOp) return;

    _isMultiChapterActive = res.isMultiChapter;
    if (res.isMultiChapter) {
      activeChapterIndexNotifier.value = res.startChapter;
      _applyLoopMode(repeatModeNotifier.value);
    }

    if (res.loaded) {
      _currentAudioUrl = res.effectiveUrl;
      _lastLoadFailed = false;
      try {
        if (res.duration != null) durationNotifier.value = res.duration!;
        await _player.setSpeed(speedNotifier.value);
        await _player.play();
        if (op == _loadOp) {
          _isLoadingInFlight = false;
          isLoadingNotifier.value = false;
          isPlayingNotifier.value = true;
        }
        return;
      } catch (playErr) {
        debugPrint('Player play error (${res.effectiveUrl}): $playErr');
      }
    }

    if (op == _loadOp) {
      _currentAudioUrl = null;
      _lastLoadFailed = true;
      _isLoadingInFlight = false;
      isLoadingNotifier.value = false;
      isPlayingNotifier.value = false;
      final msg = await _loader.resolveErrorMessage();
      if (op == _loadOp) playbackErrorNotifier.value = msg;
    }
  }

  Future<void> seekToChapter(int chapterIndex, {String? bookId}) async {
    final targetBookId = bookId ?? activeBookIdNotifier.value;
    if (targetBookId == null) return;
    await syncReciterForBook(targetBookId);
    final chapters = getChaptersForBook(targetBookId, reciterId: _selectedReciter.id);
    if (chapters.isEmpty) return;
    final clamped = chapterIndex.clamp(0, chapters.length - 1);
    activeChapterIndexNotifier.value = clamped;
    _loader.persistBookChapter(targetBookId, _selectedReciter.id, clamped);

    final sameActivePlaylist = activeBookIdNotifier.value == targetBookId &&
        _isMultiChapterActive &&
        _player.audioSource != null &&
        _player.processingState != ProcessingState.idle;
    if (sameActivePlaylist) {
      try {
        await _player.seek(Duration.zero, index: clamped);
        if (!_player.playing) await _player.play();
        return;
      } catch (_) {}
    }

    final url =
        MutunAudioCatalog.getAudioUrl(targetBookId, reciterId: _selectedReciter.id) ??
            chapters[clamped].audioUrl;
    await playMatnAudio(
      bookId: targetBookId,
      audioUrl: url,
      initialChapterIndex: clamped,
    );
  }

  Future<void> nextChapter({String? bookId}) async {
    final id = bookId ?? activeBookIdNotifier.value;
    final chapters = getChaptersForBook(id);
    if (chapters.length > 1 && activeChapterIndexNotifier.value + 1 < chapters.length) {
      await seekToChapter(activeChapterIndexNotifier.value + 1, bookId: id);
    }
  }

  Future<void> previousChapter({String? bookId}) async {
    final id = bookId ?? activeBookIdNotifier.value;
    if (getChaptersForBook(id).length > 1 && activeChapterIndexNotifier.value > 0) {
      await seekToChapter(activeChapterIndexNotifier.value - 1, bookId: id);
    }
  }

  Future<void> seekToParagraph(int index, {String? bookId}) async => activeParagraphNotifier.value = index;

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _updateActiveParagraph(position);
  }

  Future<void> seekForward5s() async {
    final dur = durationNotifier.value, target = _player.position + AppPolicy.seekStep;
    await seek(dur > Duration.zero && target > dur ? dur : target);
  }

  Future<void> seekBackward5s() async {
    final target = _player.position - AppPolicy.seekStep;
    await seek(target < Duration.zero ? Duration.zero : target);
  }

  void clearActiveParagraph() => activeParagraphNotifier.value = null;
  void nextParagraph() { if ((activeParagraphNotifier.value ?? 1) < _totalParagraphs) activeParagraphNotifier.value = (activeParagraphNotifier.value ?? 1) + 1; }
  void previousParagraph() { if ((activeParagraphNotifier.value ?? 1) > 1) activeParagraphNotifier.value = (activeParagraphNotifier.value ?? 1) - 1; }

  String _urlForBook(String bookId) => _loader.urlForBook(bookId, _selectedReciter.id);

  Future<void> togglePlayPause({String? bookId}) async {
    try {
      _ensurePlayerActive();
      final targetBookId = bookId ?? activeBookIdNotifier.value;
      if (targetBookId == null) {
        isLoadingNotifier.value = false;
        isPlayingNotifier.value = false;
        return;
      }

      final available = MutunAudioCatalog.getRecitersForBook(targetBookId);
      if (available.isNotEmpty && !available.any((r) => r.id == _selectedReciter.id)) {
        await syncReciterForBook(targetBookId);
        if (!available.any((r) => r.id == _selectedReciter.id)) {
          _selectedReciter = available.first;
          selectedReciterNotifier.value = _selectedReciter;
        }
      }

      final isDifferentBook = activeBookIdNotifier.value != targetBookId;
      final hasError = _lastLoadFailed || playbackErrorNotifier.value != null;
      final isStaleOrIdle = _player.processingState == ProcessingState.idle ||
          _player.processingState == ProcessingState.completed ||
          _player.audioSource == null;

      if (isDifferentBook || isStaleOrIdle || _currentAudioUrl == null || hasError) {
        if (isDifferentBook) await syncReciterForBook(targetBookId);
        if (hasError) {
          _loader.resetTransientFailures();
          playbackErrorNotifier.value = null;
          _lastLoadFailed = false;
          await _recreatePlayer();
        }
        await OfflineConnectivityService().checkConnectivity();
        await _reloadBook(targetBookId, keepPosition: !isDifferentBook);
        return;
      }

      if (_player.playing) {
        await _player.pause();
        isPlayingNotifier.value = false;
        isLoadingNotifier.value = false;
        return;
      }

      if (_player.processingState == ProcessingState.completed) await _player.seek(Duration.zero);

      try {
        await _player.play();
        isPlayingNotifier.value = true;
        isLoadingNotifier.value = false;
      } catch (_) {
        _loader.resetTransientFailures();
        await _recreatePlayer();
        await _reloadBook(targetBookId);
      }
    } catch (e) {
      debugPrint('togglePlayPause error: $e');
      isLoadingNotifier.value = false;
      isPlayingNotifier.value = false;
    }
  }

  Future<void> pause() async {
    try {
      _ensurePlayerActive();
      await _player.pause();
    } catch (_) {}
    isPlayingNotifier.value = false;
    isLoadingNotifier.value = false;
    AudioCoordinator.releaseFocus(AudioStreamType.mutun);
  }

  Future<void> resume() async {
    if (_lastLoadFailed || _player.processingState == ProcessingState.idle) {
      await togglePlayPause();
      return;
    }
    try {
      _ensurePlayerActive();
      await AudioCoordinator.acquireFocus(AudioStreamType.mutun);
      await _player.play();
      isPlayingNotifier.value = true;
    } catch (_) {
      await togglePlayPause();
    }
  }

  Future<void> stop() async {
    ++_loadOp;
    _isLoadingInFlight = false;
    _lastLoadFailed = false;
    _currentAudioUrl = null;
    playbackErrorNotifier.value = null;
    activeBookIdNotifier.value = null;
    activeParagraphNotifier.value = null;
    positionNotifier.value = Duration.zero;
    durationNotifier.value = Duration.zero;
    isPlayingNotifier.value = false;
    isLoadingNotifier.value = false;
    AudioCoordinator.releaseFocus(AudioStreamType.mutun);
    try {
      _ensurePlayerActive();
      await _player.stop();
    } catch (_) {}
  }

  void dispose() {
    if (AudioCoordinator.onPauseMutun == pause) AudioCoordinator.onPauseMutun = null;
    pause();
  }
}
