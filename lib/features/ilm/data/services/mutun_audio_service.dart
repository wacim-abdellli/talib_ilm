import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/constants/app_policy.dart';
import '../../../../core/services/audio_coordinator.dart';
import '../catalogs/mutun_audio_catalog.dart';
import 'mutun_audio_source_loader.dart';
export '../catalogs/mutun_audio_catalog.dart'
    show BookAudioChapter, BookAudioEdition, MatnAudioSource, MutunReciter, MutunReciterDefaults, MutunRepeatMode;

class MutunAudioService {
  static final MutunAudioService _instance = MutunAudioService._internal();
  factory MutunAudioService() => _instance;
  MutunAudioService._internal() {
    _initAudioListener();
  }

  final MutunAudioSourceLoader _loader = MutunAudioSourceLoader();
  AudioPlayer _player = AudioPlayer();
  StreamSubscription? _playerStateSub, _playbackEventSub, _positionSub, _durationSub, _currentIndexSub;

  void _ensurePlayerActive() {
    try {
      final _ = _player.processingState;
    } catch (_) {
      _recreatePlayer();
    }
  }

  Future<void> _recreatePlayer() async {
    try {
      _cancelSubscriptions();
      await _player.dispose();
    } catch (_) {}
    _player = AudioPlayer();
    _initAudioListener();
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

  final ValueNotifier<String?> activeBookIdNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<int?> activeParagraphNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<int> activeChapterIndexNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> speedNotifier = ValueNotifier<double>(1.0);
  final ValueNotifier<MutunRepeatMode> repeatModeNotifier =
      ValueNotifier<MutunRepeatMode>(MutunRepeatMode.none);
  final ValueNotifier<MutunReciter> selectedReciterNotifier =
      ValueNotifier<MutunReciter>(MutunReciterDefaults.sini);
  final ValueNotifier<Duration> positionNotifier = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<String?> playbackErrorNotifier = ValueNotifier<String?>(null);

  String? _currentAudioUrl;
  int _totalParagraphs = 1;
  bool _isMultiChapterActive = false;

  List<MutunReciter> getAvailableRecitersForBook(String? bookId) =>
      MutunAudioCatalog.getRecitersForBook(bookId);

  MutunReciter effectiveReciterForBook(String? bookId) {
    if (bookId == null) return _selectedReciter;
    final available = MutunAudioCatalog.getRecitersForBook(bookId);
    if (available.isEmpty) return _selectedReciter;
    if (available.any((r) => r.id == _selectedReciter.id)) return _selectedReciter;
    return available.first;
  }

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
      _recreatePlayer();
      isLoadingNotifier.value = false;
      isPlayingNotifier.value = false;
      playbackErrorNotifier.value = 'تعذر تشغيل الصوت';
    });

    _playbackEventSub = _player.playbackEventStream.listen((_) {}, onError: (Object err) {
      debugPrint('Audio playback error: $err');
      final wasPlaying = isPlayingNotifier.value;
      final bookId = activeBookIdNotifier.value;
      final pos = positionNotifier.value;
      final para = activeParagraphNotifier.value ?? 1;
      _recreatePlayer();
      if (wasPlaying && bookId != null && !_isMultiChapterActive) {
        final audioUrl = _currentAudioUrl ?? _urlForBook(bookId);
        if (audioUrl.isNotEmpty) {
          playMatnAudio(
            bookId: bookId,
            audioUrl: audioUrl,
            paragraphIndex: para,
            totalParagraphs: _totalParagraphs,
            initialPosition: pos > Duration.zero ? pos : null,
            isFallbackAttempt: true,
          );
          return;
        }
      }
      isLoadingNotifier.value = false;
      isPlayingNotifier.value = false;
      playbackErrorNotifier.value = 'تعذر تشغيل الصوت';
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

  Future<void> syncReciterForBook(String bookId) async {
    if ((isPlayingNotifier.value || isLoadingNotifier.value) &&
        activeBookIdNotifier.value != null &&
        activeBookIdNotifier.value != bookId) {
      return;
    }
    final available = MutunAudioCatalog.getRecitersForBook(bookId);
    if (available.isEmpty) return;
    var chosen = available.any((r) => r.id == _selectedReciter.id)
        ? _selectedReciter
        : available.first;
    final savedId = await _loader.loadSavedReciterId(bookId);
    if (savedId != null) {
      final match = available.where((r) => r.id == savedId);
      if (match.isNotEmpty) chosen = match.first;
    }
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
    if (mode == MutunRepeatMode.singleParagraph) {
      _player.seek(Duration.zero);
      _player.play();
    } else if ((activeParagraphNotifier.value ?? 1) < _totalParagraphs) {
      nextParagraph();
    } else {
      mode == MutunRepeatMode.entireMatn ? seekToParagraph(1) : stop();
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
    if (activeBook != null &&
        (forBookId == null || forBookId == activeBook) &&
        (isPlayingNotifier.value || isLoadingNotifier.value)) {
      final newUrl = MutunAudioCatalog.getAudioUrl(activeBook, reciterId: reciter.id) ?? '';
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

    activeBookIdNotifier.value = bookId;
    activeParagraphNotifier.value = paragraphIndex;
    final resolvedTotal = totalParagraphs > 1
        ? totalParagraphs
        : MutunAudioCatalog.getTotalParagraphs(bookId, reciterId: _selectedReciter.id);
    _totalParagraphs = resolvedTotal > 1 ? resolvedTotal : 1;
    isLoadingNotifier.value = true;
    playbackErrorNotifier.value = null;

    await AudioCoordinator.acquireFocus(AudioStreamType.mutun);
    try {
      await _player.stop();
    } catch (_) {
      await _recreatePlayer();
    }

    final res = await _loader.loadIntoPlayer(
      player: _player,
      bookId: bookId,
      requestedUrl: audioUrl,
      reciter: _selectedReciter,
      initialChapterIndex: initialChapterIndex,
      initialPosition: initialPosition,
      isFallbackAttempt: isFallbackAttempt,
    );

    _currentAudioUrl = res.effectiveUrl;
    _isMultiChapterActive = res.isMultiChapter;
    if (res.isMultiChapter) {
      activeChapterIndexNotifier.value = res.startChapter;
      _applyLoopMode(repeatModeNotifier.value);
    }

    if (res.loaded) {
      try {
        if (res.duration != null) durationNotifier.value = res.duration!;
        await _player.setSpeed(speedNotifier.value);
        await _player.play();
        isLoadingNotifier.value = false;
        isPlayingNotifier.value = true;
        return;
      } catch (playErr) {
        debugPrint('Player play error (${res.effectiveUrl}): $playErr');
      }
    }

    if (!res.usedFallback) {
      final fallbackUrl =
          MutunAudioCatalog.getFallbackAudioUrl(bookId, reciterId: _selectedReciter.id) ??
              MutunAudioCatalog.getAudioUrl(bookId, reciterId: 'sini');
      if (fallbackUrl != null && fallbackUrl.isNotEmpty && fallbackUrl != res.effectiveUrl) {
        await _recreatePlayer();
        return playMatnAudio(
          bookId: bookId, audioUrl: fallbackUrl, paragraphIndex: paragraphIndex,
          totalParagraphs: totalParagraphs, initialPosition: initialPosition,
          isFallbackAttempt: true,
        );
      }
    }

    playbackErrorNotifier.value = 'تعذر تشغيل الصوت. يرجى التحقق من الاتصال بالإنترنت';
    isLoadingNotifier.value = false;
    isPlayingNotifier.value = false;
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
    final chapters = getChaptersForBook(id);
    if (chapters.length > 1 && activeChapterIndexNotifier.value > 0) {
      await seekToChapter(activeChapterIndexNotifier.value - 1, bookId: id);
    }
  }

  Future<void> seekToParagraph(int index, {String? bookId}) async {
    final targetBookId = bookId ?? activeBookIdNotifier.value;
    activeParagraphNotifier.value = index;
    final targetMs = _loader.resolveParagraphTargetMs(
      bookId: targetBookId,
      reciterId: _selectedReciter.id,
      index: index,
      duration: durationNotifier.value,
      totalParagraphs: _totalParagraphs,
    );
    final isNotReady = _player.audioSource == null ||
        _player.processingState == ProcessingState.idle ||
        _currentAudioUrl == null ||
        (targetBookId != null && activeBookIdNotifier.value != targetBookId);

    if (targetBookId != null && isNotReady) {
      final audioUrl =
          MutunAudioCatalog.getAudioUrl(targetBookId, reciterId: _selectedReciter.id) ??
              MutunAudioCatalog.getAudioUrl(targetBookId, reciterId: 'sini') ??
              '';
      await playMatnAudio(
        bookId: targetBookId,
        audioUrl: audioUrl,
        paragraphIndex: index,
        totalParagraphs:
            MutunAudioCatalog.getTotalParagraphs(targetBookId, reciterId: _selectedReciter.id),
        initialPosition: targetMs > 0 ? _audioPosition(targetMs) : null,
      );
      return;
    }

    try {
      await _player.seek(_audioPosition(targetMs));
      if (!_player.playing) await _player.play();
    } catch (_) {
      if (targetBookId != null) await togglePlayPause(bookId: targetBookId);
    }
  }

  static Duration _audioPosition(int ms) =>
      Duration(milliseconds: ms); // ui-lint: allow audio seek position

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _updateActiveParagraph(position);
  }

  Future<void> seekForward5s() async {
    final dur = durationNotifier.value;
    final target = _player.position + AppPolicy.seekStep;
    await seek(dur > Duration.zero && target > dur ? dur : target);
  }

  Future<void> seekBackward5s() async {
    final target = _player.position - AppPolicy.seekStep;
    await seek(target < Duration.zero ? Duration.zero : target);
  }

  void clearActiveParagraph() => activeParagraphNotifier.value = null;
  void nextParagraph() {
    if ((activeParagraphNotifier.value ?? 1) < _totalParagraphs) {
      seekToParagraph((activeParagraphNotifier.value ?? 1) + 1);
    }
  }

  void previousParagraph() {
    if ((activeParagraphNotifier.value ?? 1) > 1) {
      seekToParagraph((activeParagraphNotifier.value ?? 1) - 1);
    }
  }

  String _urlForBook(String bookId) =>
      MutunAudioCatalog.getAudioUrl(bookId, reciterId: _selectedReciter.id) ??
      MutunAudioCatalog.getAudioUrl(bookId, reciterId: 'sini') ??
      '';

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
      final isStaleOrIdle = _player.processingState == ProcessingState.idle ||
          _player.processingState == ProcessingState.completed ||
          _player.audioSource == null;

      if (isDifferentBook || isStaleOrIdle || _currentAudioUrl == null) {
        if (isDifferentBook) await syncReciterForBook(targetBookId);
        await playMatnAudio(
          bookId: targetBookId,
          audioUrl: _urlForBook(targetBookId),
          paragraphIndex: !isDifferentBook ? (activeParagraphNotifier.value ?? 1) : 1,
          totalParagraphs:
              MutunAudioCatalog.getTotalParagraphs(targetBookId, reciterId: _selectedReciter.id),
          initialPosition: !isDifferentBook && positionNotifier.value > Duration.zero
              ? positionNotifier.value
              : null,
        );
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
        await _recreatePlayer();
        await playMatnAudio(
          bookId: targetBookId,
          audioUrl: _currentAudioUrl ?? _urlForBook(targetBookId),
          paragraphIndex: activeParagraphNotifier.value ?? 1,
          totalParagraphs: _totalParagraphs,
          initialPosition: positionNotifier.value > Duration.zero ? positionNotifier.value : null,
        );
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
    try {
      _ensurePlayerActive();
      await AudioCoordinator.acquireFocus(AudioStreamType.mutun);
      await _player.play();
      isPlayingNotifier.value = true;
    } catch (_) {}
  }

  Future<void> stop() async {
    activeBookIdNotifier.value = null;
    activeParagraphNotifier.value = null;
    positionNotifier.value = Duration.zero;
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
