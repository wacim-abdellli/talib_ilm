import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../../../app/theme/app_ui.dart';
import '../catalogs/mutun_audio_catalog.dart';
export '../catalogs/mutun_audio_catalog.dart' show MutunReciter, MutunReciterDefaults;

enum MutunRepeatMode {
  none,
  singleParagraph,
  entireMatn,
}

class MutunAudioService {
  static final MutunAudioService _instance = MutunAudioService._internal();
  factory MutunAudioService() => _instance;

  MutunAudioService._internal() {
    _initAudioListener();
  }

  AudioPlayer _player = AudioPlayer();
  StreamSubscription? _playerStateSub;
  StreamSubscription? _playbackEventSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  void _ensurePlayerActive() {
    try {
      final _ = _player.processingState;
    } catch (_) {
      _player = AudioPlayer();
      _initAudioListener();
    }
  }

  static const List<MutunReciter> defaultReciters = [
    MutunReciterDefaults.sini,
    MutunReciterDefaults.fahad,
    MutunReciterDefaults.faqeeh,
    MutunReciterDefaults.shaydzmi,
    MutunReciterDefaults.afasy,
  ];

  static const List<MutunReciter> availableReciters = defaultReciters;

  MutunReciter _selectedReciter = MutunReciterDefaults.sini;
  MutunReciter get selectedReciter => _selectedReciter;

  // Reactive state notifiers
  final ValueNotifier<String?> activeBookIdNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<int?> activeParagraphNotifier = ValueNotifier<int?>(null);
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

  /// Returns the specific verified reciters available for a book.
  List<MutunReciter> getAvailableRecitersForBook(String? bookId) {
    return MutunAudioCatalog.getRecitersForBook(bookId);
  }

  void _initAudioListener() {
    _playerStateSub?.cancel();
    _playbackEventSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();

    _playerStateSub = _player.playerStateStream.listen((state) {
      final isPlaying = state.playing &&
          state.processingState != ProcessingState.completed &&
          state.processingState != ProcessingState.idle;
      final isLoading = (state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering) &&
          !state.playing;

      if (isPlayingNotifier.value != isPlaying) {
        isPlayingNotifier.value = isPlaying;
      }
      if (isLoadingNotifier.value != isLoading) {
        isLoadingNotifier.value = isLoading;
      }

      if (state.processingState == ProcessingState.completed) {
        _handleTrackCompletion();
      }
    }, onError: (Object err) {
      debugPrint('Audio player state error: $err');
      isLoadingNotifier.value = false;
      isPlayingNotifier.value = false;
      playbackErrorNotifier.value = 'تعذر تشغيل الصوت';
    });

    _playbackEventSub = _player.playbackEventStream.listen(
      (event) {},
      onError: (Object err) {
        debugPrint('Audio playback error: $err');
        isLoadingNotifier.value = false;
        isPlayingNotifier.value = false;
      },
    );

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
  }

  void _updateActiveParagraph(Duration pos) {
    if (isLoadingNotifier.value) return;
    final bookId = activeBookIdNotifier.value;
    final timestamps = bookId != null
        ? MutunAudioCatalog.getParagraphTimestamps(
            bookId,
            reciterId: _selectedReciter.id,
          )
        : null;

    int? activeIndex;
    if (timestamps != null && timestamps.isNotEmpty) {
      final posMs = pos.inMilliseconds;
      int idx = 1;
      for (int i = 0; i < timestamps.length; i++) {
        if (posMs >= timestamps[i]) {
          idx = i + 1;
        } else {
          break;
        }
      }
      final maxP = _totalParagraphs > 1 ? _totalParagraphs : timestamps.length;
      activeIndex = idx.clamp(1, maxP);
    } else {
      final dur = durationNotifier.value;
      if (dur > Duration.zero && _totalParagraphs > 1) {
        final ratio = pos.inMilliseconds / dur.inMilliseconds;
        final estimatedPara = (ratio * _totalParagraphs).floor() + 1;
        activeIndex = estimatedPara.clamp(1, _totalParagraphs);
      }
    }

    if (activeIndex != null && activeParagraphNotifier.value != activeIndex) {
      activeParagraphNotifier.value = activeIndex;
    }
  }

  void _handleTrackCompletion() {
    final mode = repeatModeNotifier.value;
    if (mode == MutunRepeatMode.singleParagraph) {
      _player.seek(Duration.zero);
      _player.play();
    } else if (mode == MutunRepeatMode.entireMatn) {
      final currentPara = activeParagraphNotifier.value ?? 1;
      if (currentPara < _totalParagraphs) {
        nextParagraph();
      } else {
        seekToParagraph(1);
      }
    } else {
      final currentPara = activeParagraphNotifier.value ?? 1;
      if (currentPara < _totalParagraphs) {
        nextParagraph();
      } else {
        stop();
      }
    }
  }

  void setSelectedReciter(MutunReciter reciter) {
    if (_selectedReciter.id != reciter.id) {
      _selectedReciter = reciter;
      selectedReciterNotifier.value = reciter;
      final bookId = activeBookIdNotifier.value;
      if (bookId != null) {
        final newUrl =
            MutunAudioCatalog.getAudioUrl(bookId, reciterId: reciter.id) ?? '';
        final shouldPlay = isPlayingNotifier.value || isLoadingNotifier.value;
        if (newUrl.isNotEmpty && shouldPlay) {
          playMatnAudio(
            bookId: bookId,
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
  }

  void toggleRepeatMode() {
    switch (repeatModeNotifier.value) {
      case MutunRepeatMode.none:
        repeatModeNotifier.value = MutunRepeatMode.singleParagraph;
        break;
      case MutunRepeatMode.singleParagraph:
        repeatModeNotifier.value = MutunRepeatMode.entireMatn;
        break;
      case MutunRepeatMode.entireMatn:
        repeatModeNotifier.value = MutunRepeatMode.none;
        break;
    }
  }

  Future<void> setSpeed(double speed) async {
    speedNotifier.value = speed;
    await _player.setSpeed(speed);
  }

  void cycleSpeed() {
    final current = speedNotifier.value;
    double next = 1.0;
    if (current == 0.75) {
      next = 1.0;
    } else if (current == 1.0) {
      next = 1.25;
    } else if (current == 1.25) {
      next = 1.5;
    } else if (current == 1.5) {
      next = 2.0;
    } else {
      next = 0.75;
    }
    setSpeed(next);
  }

  Future<void> playMatnAudio({
    required String bookId,
    required String audioUrl,
    int paragraphIndex = 1,
    int totalParagraphs = 1,
    Duration? initialPosition,
    bool isFallbackAttempt = false,
  }) async {
    if (audioUrl.isEmpty) {
      isLoadingNotifier.value = false;
      return;
    }

    activeBookIdNotifier.value = bookId;
    activeParagraphNotifier.value = paragraphIndex;
    _currentAudioUrl = audioUrl;
    final resolvedTotal = totalParagraphs > 1
        ? totalParagraphs
        : MutunAudioCatalog.getTotalParagraphs(bookId, reciterId: _selectedReciter.id);
    _totalParagraphs = resolvedTotal > 1 ? resolvedTotal : 1;
    isLoadingNotifier.value = true;
    playbackErrorNotifier.value = null;

    final entry = MutunAudioCatalog.getEntry(bookId);
    final mediaTitle = entry?.title ?? 'متن طالب العلم';

    // Cleanly stop any existing stream to prevent player deadlock
    try {
      await _player.stop();
    } catch (_) {}

    bool loaded = false;
    Duration? loadedDuration;

    // Primary Attempt: setAudioSource with background MediaItem
    try {
      final mediaItem = MediaItem(
        id: bookId,
        title: mediaTitle,
        artist: _selectedReciter.name,
        album: 'متون طالب العلم',
        displayTitle: mediaTitle,
        displaySubtitle: _selectedReciter.name,
        displayDescription: 'متون طالب العلم - تحقيق الشيخ د. عبدالمحسن القاسم',
      );
      final audioSource = AudioSource.uri(
        Uri.parse(audioUrl),
        tag: mediaItem,
      );
      loadedDuration = await _player.setAudioSource(
        audioSource,
        initialPosition: initialPosition,
      );
      loaded = true;
    } catch (sourceErr) {
      debugPrint('AudioSource.uri failed ($audioUrl): $sourceErr, trying direct setUrl...');
      // Direct setUrl fallback: Bypasses JustAudioBackground/MediaItem metadata serialization
      try {
        await _player.stop();
        loadedDuration = await _player.setUrl(
          audioUrl,
          initialPosition: initialPosition,
        );
        loaded = true;
      } catch (urlErr) {
        debugPrint('Direct setUrl failed ($audioUrl): $urlErr');
        loaded = false;
      }
    }

    if (loaded) {
      try {
        if (loadedDuration != null) {
          durationNotifier.value = loadedDuration;
        }

        // If initialPosition was not provided or was zero, but paragraphIndex > 1:
        // calculate target and seek BEFORE calling play() so 0:00 never leaks!
        if ((initialPosition == null || initialPosition == Duration.zero) &&
            paragraphIndex > 1) {
          final timestamps = MutunAudioCatalog.getParagraphTimestamps(
            bookId,
            reciterId: _selectedReciter.id,
          );
          int targetMs = 0;
          if (timestamps != null &&
              paragraphIndex >= 1 &&
              paragraphIndex <= timestamps.length) {
            targetMs = timestamps[paragraphIndex - 1];
          } else {
            final dur = loadedDuration ?? durationNotifier.value;
            if (dur > Duration.zero && _totalParagraphs > 1) {
              targetMs =
                  ((paragraphIndex - 1) / _totalParagraphs * dur.inMilliseconds)
                      .round();
            }
          }
          if (targetMs > 0) {
            await _player.seek(_audioPosition(targetMs));
          }
        }

        await _player.setSpeed(speedNotifier.value);
        await _player.play();
        isLoadingNotifier.value = false;
        isPlayingNotifier.value = true;
        return;
      } catch (playErr) {
        debugPrint('Player play error ($audioUrl): $playErr');
      }
    }

    // If primary URL completely failed and we haven't tried fallback yet
    if (!isFallbackAttempt) {
      final fallbackUrl =
          MutunAudioCatalog.getFallbackAudioUrl(bookId, reciterId: _selectedReciter.id) ??
          MutunAudioCatalog.getAudioUrl(bookId, reciterId: 'sini');
      if (fallbackUrl != null && fallbackUrl.isNotEmpty && fallbackUrl != audioUrl) {
        debugPrint('Retrying with backup audio stream ($fallbackUrl)...');
        await playMatnAudio(
          bookId: bookId,
          audioUrl: fallbackUrl,
          paragraphIndex: paragraphIndex,
          totalParagraphs: totalParagraphs,
          initialPosition: initialPosition,
          isFallbackAttempt: true,
        );
        return;
      }
    }

    playbackErrorNotifier.value = 'تعذر تشغيل الصوت. يرجى التحقق من الاتصال بالإنترنت';
    isLoadingNotifier.value = false;
    isPlayingNotifier.value = false;
  }

  Future<void> seekToParagraph(int index, {String? bookId}) async {
    final targetBookId = bookId ?? activeBookIdNotifier.value;
    activeParagraphNotifier.value = index;

    final timestamps = targetBookId != null
        ? MutunAudioCatalog.getParagraphTimestamps(
            targetBookId,
            reciterId: _selectedReciter.id,
          )
        : null;

    int targetMs = 0;
    if (timestamps != null && index >= 1 && index <= timestamps.length) {
      targetMs = timestamps[index - 1];
    } else {
      final dur = durationNotifier.value;
      if (dur > Duration.zero && _totalParagraphs > 1) {
        targetMs =
            ((index - 1) / _totalParagraphs * dur.inMilliseconds).round();
      }
    }

    final isNotReady = _player.audioSource == null ||
        _player.processingState == ProcessingState.idle ||
        _currentAudioUrl == null ||
        (targetBookId != null && activeBookIdNotifier.value != targetBookId);

    if (targetBookId != null && isNotReady) {
      final audioUrl = MutunAudioCatalog.getAudioUrl(
            targetBookId,
            reciterId: _selectedReciter.id,
          ) ??
          MutunAudioCatalog.getAudioUrl(
            targetBookId,
            reciterId: 'sini',
          ) ??
          '';
      final totalParas = MutunAudioCatalog.getTotalParagraphs(
        targetBookId,
        reciterId: _selectedReciter.id,
      );
      await playMatnAudio(
        bookId: targetBookId,
        audioUrl: audioUrl,
        paragraphIndex: index,
        totalParagraphs: totalParas,
        initialPosition: targetMs > 0 ? _audioPosition(targetMs) : null,
      );
      return;
    }

    await _player.seek(_audioPosition(targetMs));
    if (!_player.playing) {
      await _player.play();
    }
  }

  static Duration _audioPosition(int ms) =>
      Duration(milliseconds: ms); // ui-lint: allow audio seek position

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _updateActiveParagraph(position);
  }

  Future<void> seekForward5s() async {
    final current = _player.position;
    final dur = durationNotifier.value;
    final target = current + AppMotion.seekStep;
    final clamped = dur > Duration.zero && target > dur ? dur : target;
    await _player.seek(clamped);
    _updateActiveParagraph(clamped);
  }

  Future<void> seekBackward5s() async {
    final current = _player.position;
    final target = current - AppMotion.seekStep;
    final clamped = target < Duration.zero ? Duration.zero : target;
    await _player.seek(clamped);
    _updateActiveParagraph(clamped);
  }

  void clearActiveParagraph() {
    activeParagraphNotifier.value = null;
  }

  void nextParagraph() {
    final current = activeParagraphNotifier.value ?? 1;
    if (current < _totalParagraphs) {
      seekToParagraph(current + 1);
    }
  }

  void previousParagraph() {
    final current = activeParagraphNotifier.value ?? 1;
    if (current > 1) {
      seekToParagraph(current - 1);
    }
  }

  Future<void> togglePlayPause({String? bookId}) async {
    try {
      _ensurePlayerActive();
      final targetBookId = bookId ?? activeBookIdNotifier.value;

      // Check if target reciter is available for this book, otherwise pick the first available
      if (targetBookId != null) {
        final availableReciters = MutunAudioCatalog.getRecitersForBook(targetBookId);
        final hasSelected =
            availableReciters.any((r) => r.id == _selectedReciter.id);
        if (!hasSelected && availableReciters.isNotEmpty) {
          _selectedReciter = availableReciters.first;
          selectedReciterNotifier.value = _selectedReciter;
        }
      }

      final isStaleOrIdle = _player.processingState == ProcessingState.idle ||
          _player.processingState == ProcessingState.completed ||
          _player.audioSource == null;

      // If starting a new book, first-time playback, or player in idle/completed state
      if (targetBookId != null &&
          (_currentAudioUrl == null ||
              activeBookIdNotifier.value != targetBookId ||
              isStaleOrIdle)) {
        final audioUrl = MutunAudioCatalog.getAudioUrl(
              targetBookId,
              reciterId: _selectedReciter.id,
            ) ??
            MutunAudioCatalog.getAudioUrl(
              targetBookId,
              reciterId: 'sini',
            ) ??
            '';
        final totalParas = MutunAudioCatalog.getTotalParagraphs(
          targetBookId,
          reciterId: _selectedReciter.id,
        );

        final isSameBook = activeBookIdNotifier.value == targetBookId;
        final resumePara = isSameBook ? (activeParagraphNotifier.value ?? 1) : 1;
        final resumePos = isSameBook && positionNotifier.value > Duration.zero
            ? positionNotifier.value
            : null;

        await playMatnAudio(
          bookId: targetBookId,
          audioUrl: audioUrl,
          paragraphIndex: resumePara,
          totalParagraphs: totalParas,
          initialPosition: resumePos,
        );
        return;
      }

      if (_player.playing) {
        await _player.pause();
        isPlayingNotifier.value = false;
      } else {
        await _player.play();
        isPlayingNotifier.value = true;
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
  }

  Future<void> resume() async {
    try {
      _ensurePlayerActive();
      await _player.play();
      isPlayingNotifier.value = true;
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      _ensurePlayerActive();
      await _player.stop();
    } catch (_) {}
    activeBookIdNotifier.value = null;
    activeParagraphNotifier.value = null;
    positionNotifier.value = Duration.zero;
    isPlayingNotifier.value = false;
    isLoadingNotifier.value = false;
  }

  void dispose() {
    pause();
  }
}
