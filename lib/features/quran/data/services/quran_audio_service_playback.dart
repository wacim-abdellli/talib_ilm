part of 'quran_audio_service.dart';

extension _QuranAudioPlaybackHandlers on QuranAudioService {
  Future<void> _recreatePlayerImpl(int operation) async {
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

  Future<void> _handlePlaybackErrorImpl(dynamic e, [int? operation]) async {
    if (!_ownsOperation(operation ?? _operation)) return;
    _completionArmed = false;
    _playWhenReady = false;
    final err = QuranAudioService.classifyError(e);
    isPlayingNotifier.value = false;
    errorNotifier.value = err;
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<AudioSource> _getAudioSourceImpl(
    int surah,
    int ayah, {
    QuranReciter? reciter,
  }) async {
    final r = reciter ?? _selectedReciter;
    if (_sourceResolver != null) return _sourceResolver!(surah, ayah, r);
    final surahName = quran.getSurahNameArabic(surah);
    final tag = QuranSurahQueueResolver.buildAyahMediaItem(
      surah,
      ayah,
      r,
      surahName,
    );

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

  Future<void> _startPlayImpl(
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
          await player
              .setAudioSource(audioSource)
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

  Future<void> _startPlaySourceImpl(
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
          .setAudioSource(audioSource)
          .timeout(AppPolicy.networkTimeout);
      if (!_ownsOperation(operation)) return;
      await player.setSpeed(speedNotifier.value);
      if (!_ownsOperation(operation)) return;
      if (_pendingInitialSeekAyah > 1) {
        final durMs = _safeDurationMs;
        if (durMs > 0) {
          final targetAyah = _pendingInitialSeekAyah;
          _pendingInitialSeekAyah = 1;
          final startMs = HifdhAudioRangeHelper.ayahStartMs(
            surah,
            targetAyah,
            durMs,
            includeOpeningOnFirstAyah: false,
          );
          await seekMilliseconds(startMs);
        }
      }
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

  Future<void> _handleTrackCompletedImpl() async {
    final surah = activeSurahNotifier.value;
    final ayah = activeAyahNotifier.value;

    if (surah == null || ayah == null) return;

    if (_isTransitioning || !_completionArmed || !_playWhenReady) return;
    _completionArmed = false;
    _isTransitioning = true;

    // 0. Full Surah Mode (single continuous recording of the whole surah)
    if (isFullSurahMode) {
      final rangeConfig = hifdhRangeNotifier.value;
      if (rangeConfig != null && rangeConfig.surah == surah) {
        if (rangeConfig.isInfinite ||
            rangeConfig.currentIteration + 1 < rangeConfig.repeatCount) {
          final nextRange = rangeConfig.nextIteration();
          hifdhRangeNotifier.value = nextRange;
          _ayahRepeatCount = 0;
          await playFullSurah(
            surah: surah,
            reciter: _playbackReciter,
            initialAyah: nextRange.startAyah,
          );
          return;
        } else {
          hifdhRangeNotifier.value = null;
          await stop();
          return;
        }
      }
      if (repeatModeNotifier.value == AudioRepeatMode.infinite) {
        _ayahRepeatCount = 0;
        await _restartCurrentFullSurah(surah);
        return;
      }
      if (repeatModeNotifier.value == AudioRepeatMode.repeatOnce) {
        if (_surahRepeatIteration < 1) {
          _surahRepeatIteration++;
          _ayahRepeatCount = 0;
          await _restartCurrentFullSurah(surah);
          return;
        }
        _surahRepeatIteration = 0;
      }
      if (stopAtEndOfSurahNotifier.value) {
        stopAtEndOfSurahNotifier.value = false;
        await stop();
        return;
      }
      if (!_hasExplicitEnd) {
        final next = await _resolveNextSurah(surah, _playbackReciter);
        if (next != null) {
          _surahRepeatIteration = 0;
          await playFullSurah(surah: next, reciter: _playbackReciter);
          return;
        }
      }
      await stop();
      return;
    }

    // 1. Explicit Infinite Verse Repeat Mode (set via Hifdh sheet: 0 = ∞)
    if (_verseRepeatTarget == 0) {
      _startPlay(surah, ayah);
      return;
    }

    // 2. Explicit Verse Repetition Mode (supports multi-count Hifdh repetitions: 2, 3, 5, 10)
    if (_verseRepeatTarget > 1) {
      if (_ayahRepeatCount < _verseRepeatTarget - 1) {
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

    // 5. Continuous / Standard Playback (sequential verse by verse)
    if (_isContinuous) {
      if (ayah < limit) {
        _startPlay(surah, ayah + 1);
      } else if (!_hasExplicitEnd) {
        if (stopAtEndOfSurahNotifier.value) {
          stopAtEndOfSurahNotifier.value = false;
          await stop();
          return;
        }
        if (repeatModeNotifier.value == AudioRepeatMode.infinite) {
          _ayahRepeatCount = 0;
          await playContinuous(
            surah: surah,
            startAyah: 1,
            reciter: _playbackReciter,
          );
          return;
        }
        if (repeatModeNotifier.value == AudioRepeatMode.repeatOnce) {
          if (_surahRepeatIteration < 1) {
            _surahRepeatIteration++;
            _ayahRepeatCount = 0;
            await playContinuous(
              surah: surah,
              startAyah: 1,
              reciter: _playbackReciter,
            );
            return;
          }
          _surahRepeatIteration = 0;
        }
        final next = await _resolveNextSurah(surah, _playbackReciter);
        if (next != null) {
          _surahRepeatIteration = 0;
          await playContinuous(
            surah: next,
            startAyah: 1,
            reciter: _playbackReciter,
          );
        } else {
          await stop();
        }
      } else {
        await stop();
      }
    } else {
      if (repeatModeNotifier.value == AudioRepeatMode.infinite) {
        _startPlay(surah, ayah);
        return;
      }
      if (repeatModeNotifier.value == AudioRepeatMode.repeatOnce) {
        if (_surahRepeatIteration < 1) {
          _surahRepeatIteration++;
          _startPlay(surah, ayah);
          return;
        }
        _surahRepeatIteration = 0;
      }
      // By default, reading verse N advances to N+1
      if (ayah < totalVerses) {
        _startPlay(surah, ayah + 1);
      } else {
        stop();
      }
    }
  }

  Future<void> _restartCurrentFullSurahImpl(int surah) async {
    final r = _playbackReciter ?? _selectedReciter;
    activeSurahNotifier.value = surah;
    activeAyahNotifier.value = 1;
    _completionArmed = true;
    _isTransitioning = false;
    _isSeekingFullSurah = false;
    _playWhenReady = true;

    try {
      await _player.seek(Duration.zero);
      await AudioCoordinator.acquireFocus(AudioStreamType.quran);
      await _player.play();
    } catch (e) {
      debugPrint('QuranAudioService seek(0) error: $e, reloading full surah');
      await playFullSurah(
        surah: surah,
        reciter: r,
        autoPlay: true,
        isRepeatCycle: true,
      );
    }
  }
}
