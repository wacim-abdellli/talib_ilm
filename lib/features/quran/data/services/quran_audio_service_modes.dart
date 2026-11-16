part of 'quran_audio_service.dart';

extension _QuranAudioModesHandlers on QuranAudioService {
  Future<void> _switchReciterImpl(QuranReciter reciter) async {
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
      await playFullSurah(
        surah: surah,
        reciter: reciter,
        autoPlay: shouldPlay,
        initialAyah: ayah,
        queue: _surahPlaybackQueue,
      );
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

  Future<void> _playVerseImpl(
    int surah,
    int ayah, {
    QuranReciter? reciter,
    bool singleVerse = false,
    bool autoPlay = true,
  }) async {
    if (!QuranAudioService.isValidSurah(surah) ||
        !QuranAudioService.isValidVerse(surah, ayah)) {
      return;
    }
    var r = reciter ?? _selectedReciter;
    if (r.isSurahBased) {
      r = QuranReciter.defaultReciters.firstWhere(
        (candidate) => !candidate.isSurahBased,
      );
      setSelectedReciter(r);
    }
    _ayahRepeatCount = 0;
    _surahRepeatIteration = 0;
    _isContinuous = false;
    _isSingleVerseOnly = singleVerse;
    isFullSurahModeNotifier.value = false;
    await _startPlay(surah, ayah, reciter: r, autoPlay: autoPlay);
  }

  void _prepareFullSurahState({
    required int totalVerses,
    required int startAyah,
    required QuranReciter reciter,
    required bool hasExplicitEnd,
    required bool isRepeatCycle,
  }) {
    _ayahRepeatCount = 0;
    if (!isRepeatCycle) {
      _surahRepeatIteration = 0;
    }
    _isContinuous = true;
    _isSingleVerseOnly = false;
    _hasExplicitEnd = hasExplicitEnd;
    _endAyah = totalVerses;
    _pendingInitialSeekAyah = startAyah > 1 ? startAyah : 1;
    isFullSurahModeNotifier.value = true;
    _playbackReciter = reciter;
  }

  Future<void> _playFullSurahImpl({
    required int surah,
    QuranReciter? reciter,
    bool autoPlay = true,
    bool hasExplicitEnd = false,
    int initialAyah = 1,
    List<int>? queue,
    bool isRepeatCycle = false,
  }) async {
    if (!QuranAudioService.isValidSurah(surah)) return;
    final r = reciter ?? _selectedReciter;
    if (queue != null && queue.isNotEmpty) {
      setSurahPlaybackQueue(queue, downloadedOnly: true);
    }
    final totalVerses = quran.getVerseCount(surah);
    final startAyah = initialAyah.clamp(1, totalVerses);
    File? fullFile;
    if (_sourceResolver == null) {
      try {
        fullFile = await QuranAudioFrameMerger.getFullSurahAudioFile(
          surah,
          reciter: r,
        );
      } catch (_) {}
    }
    final hasOfflineFullFile = fullFile != null && fullFile.existsSync();

    if (hasOfflineFullFile) {
      _prepareFullSurahState(
        totalVerses: totalVerses,
        startAyah: startAyah,
        reciter: r,
        hasExplicitEnd: hasExplicitEnd,
        isRepeatCycle: isRepeatCycle,
      );
      if (_surahPlaybackQueue == null) {
        _downloadedQueueOnly = true;
      }
      final surahName = quran.getSurahNameArabic(surah);
      final tag = QuranSurahQueueResolver.buildSurahMediaItem(
        surah,
        r,
        surahName,
      );
      await _startPlaySource(
        surah,
        startAyah,
        audioSource: AudioSource.file(fullFile.path, tag: tag),
        reciter: r,
        autoPlay: autoPlay,
      );
      return;
    }

    if (queue == null && _surahPlaybackQueue == null) {
      _downloadedQueueOnly = false;
    }

    if (r.isSurahBased) {
      if (!r.hasSurah(surah)) {
        final fallback = QuranReciter.defaultReciters.first;
        await playFullSurah(
          surah: surah,
          reciter: fallback,
          autoPlay: autoPlay,
          hasExplicitEnd: hasExplicitEnd,
          initialAyah: initialAyah,
          isRepeatCycle: isRepeatCycle,
        );
        return;
      }
      _prepareFullSurahState(
        totalVerses: totalVerses,
        startAyah: startAyah,
        reciter: r,
        hasExplicitEnd: hasExplicitEnd,
        isRepeatCycle: isRepeatCycle,
      );
      final surahName = quran.getSurahNameArabic(surah);
      final tag = QuranSurahQueueResolver.buildSurahMediaItem(
        surah,
        r,
        surahName,
      );
      final url =
          '${r.surahBaseUrl}${QuranSurahQueueResolver.formatNumber(surah)}.mp3';
      await _startPlaySource(
        surah,
        startAyah,
        audioSource: AudioSource.uri(Uri.parse(url), tag: tag),
        reciter: r,
        autoPlay: autoPlay,
      );
      return;
    }

    await playContinuous(
      surah: surah,
      startAyah: startAyah,
      reciter: r,
      autoPlay: autoPlay,
    );
  }

  Future<void> _playContinuousImpl({
    required int surah,
    required int startAyah,
    int? endAyah,
    QuranReciter? reciter,
    bool autoPlay = true,
    List<int>? queue,
  }) async {
    if (!QuranAudioService.isValidSurah(surah) ||
        !QuranAudioService.isValidVerse(surah, startAyah)) {
      return;
    }
    final r = reciter ?? _selectedReciter;
    if (queue != null && queue.isNotEmpty) {
      setSurahPlaybackQueue(queue, downloadedOnly: true);
    }
    final totalVerses = quran.getVerseCount(surah);
    final isRangeBounded = startAyah > 1 ||
        (endAyah != null && endAyah < totalVerses) ||
        hifdhRangeNotifier.value != null ||
        _verseRepeatTarget > 1;

    if (r.isSurahBased) {
      await playFullSurah(
        surah: surah,
        reciter: r,
        autoPlay: autoPlay,
        hasExplicitEnd: endAyah != null,
        initialAyah: startAyah,
      );
      return;
    }

    // If starting from verse 1 for full surah and offline recording exists,
    // and no range loop or verse repeat is active, play the full recording directly.
    if (!isRangeBounded &&
        _sourceResolver == null &&
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
    _surahRepeatIteration = 0;
    _isContinuous = true;
    _isSingleVerseOnly = false;
    isFullSurahModeNotifier.value = false;
    _hasExplicitEnd = endAyah != null;
    _endAyah = endAyah ?? totalVerses;
    await _startPlay(surah, startAyah, reciter: r, autoPlay: autoPlay);
  }

  Future<void> _nextSurahImpl() async {
    final s = activeSurahNotifier.value;
    if (s == null) return;
    final r = _playbackReciter;
    final next = await _resolveNextSurah(s, r);
    if (next != null) {
      if (isFullSurahMode || (r?.isSurahBased ?? selectedReciter.isSurahBased)) {
        await playFullSurah(surah: next, reciter: r);
      } else {
        await playContinuous(surah: next, startAyah: 1, reciter: r);
      }
    } else {
      await stop();
    }
  }

  Future<void> _previousSurahImpl() async {
    final s = activeSurahNotifier.value;
    if (s == null) return;
    if (_player.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    final r = _playbackReciter;
    final prev = await _resolvePreviousSurah(s, r);
    if (prev != null) {
      if (isFullSurahMode || (r?.isSurahBased ?? selectedReciter.isSurahBased)) {
        await playFullSurah(surah: prev, reciter: r);
      } else {
        await playContinuous(surah: prev, startAyah: 1, reciter: r);
      }
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> _nextAyahImpl() async {
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

  Future<void> _previousAyahImpl() async {
    final s = activeSurahNotifier.value, a = activeAyahNotifier.value;
    if (s == null || a == null) return;
    if (a > 1) {
      await _navigateTo(s, a - 1);
    } else if (s > 1) {
      await _navigateTo(s - 1, quran.getVerseCount(s - 1));
    }
  }

  Future<void> _navigateToImpl(int surah, int ayah) async {
    _ayahRepeatCount = 0;
    _surahRepeatIteration = 0;
    _isSingleVerseOnly = false;
    if (_isContinuous &&
        (surah != activeSurahNotifier.value || ayah > _endAyah)) {
      _hasExplicitEnd = false;
      _endAyah = quran.getVerseCount(surah);
    }
    await _startPlay(surah, ayah);
  }
}
