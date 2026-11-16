part of 'quran_audio_service.dart';

extension _QuranAudioHifdhHandlers on QuranAudioService {
  Future<void> _seekWithinFullSurahImpl(int targetMs) async {
    if (_disposed || _isSeekingFullSurah) return;
    _isSeekingFullSurah = true;
    try {
      await seekMilliseconds(targetMs);
      if (_playWhenReady && !_player.playing) {
        unawaited(_player.play());
      }
    } catch (_) {
    } finally {
      _isSeekingFullSurah = false;
    }
  }

  void _handleFullSurahPositionTickImpl(int posMs, int durMs) {
    final surah = activeSurahNotifier.value;
    if (surah == null || durMs <= 0) return;

    if (_pendingInitialSeekAyah > 1) {
      final targetAyah = _pendingInitialSeekAyah;
      _pendingInitialSeekAyah = 1;
      final startMs = HifdhAudioRangeHelper.ayahStartMs(
        surah,
        targetAyah,
        durMs,
        includeOpeningOnFirstAyah: false,
      );
      activeAyahNotifier.value = targetAyah;
      unawaited(_seekWithinFullSurah(startMs));
      return;
    }

    final totalVerses = quran.getVerseCount(surah);
    final rangeConfig = hifdhRangeNotifier.value;
    final repeatTarget = _verseRepeatTarget;
    final isInfiniteVerse = _verseRepeatTarget == 0;

    if (rangeConfig != null && rangeConfig.surah == surah) {
      final trackedAyah = (activeAyahNotifier.value ?? rangeConfig.startAyah)
          .clamp(rangeConfig.startAyah, rangeConfig.endAyah);
      final ayahEnd = HifdhAudioRangeHelper.ayahEndMs(surah, trackedAyah, durMs);

      if (posMs >= ayahEnd - 150) {
        if (isInfiniteVerse) {
          final startMs = HifdhAudioRangeHelper.ayahStartMs(
            surah,
            trackedAyah,
            durMs,
            includeOpeningOnFirstAyah: false,
          );
          unawaited(_seekWithinFullSurah(startMs));
          return;
        }
        if (repeatTarget > 1 && _ayahRepeatCount < repeatTarget - 1) {
          _ayahRepeatCount++;
          final startMs = HifdhAudioRangeHelper.ayahStartMs(
            surah,
            trackedAyah,
            durMs,
            includeOpeningOnFirstAyah: false,
          );
          unawaited(_seekWithinFullSurah(startMs));
          return;
        }

        _ayahRepeatCount = 0;
        if (trackedAyah < rangeConfig.endAyah) {
          activeAyahNotifier.value = trackedAyah + 1;
        } else {
          // Reached end of range inside full surah recording
          if (rangeConfig.isInfinite ||
              rangeConfig.currentIteration + 1 < rangeConfig.repeatCount) {
            final nextRange = rangeConfig.nextIteration();
            hifdhRangeNotifier.value = nextRange;
            activeAyahNotifier.value = nextRange.startAyah;
            final startMs = HifdhAudioRangeHelper.ayahStartMs(
              surah,
              nextRange.startAyah,
              durMs,
              includeOpeningOnFirstAyah: false,
            );
            unawaited(_seekWithinFullSurah(startMs));
          } else {
            hifdhRangeNotifier.value = null;
            unawaited(pause());
          }
        }
      }
      return;
    }

    if (isInfiniteVerse || repeatTarget > 1) {
      final trackedAyah = (activeAyahNotifier.value ?? 1).clamp(1, totalVerses);
      final ayahEnd = HifdhAudioRangeHelper.ayahEndMs(surah, trackedAyah, durMs);
      if (posMs >= ayahEnd - 150) {
        if (isInfiniteVerse) {
          final startMs = HifdhAudioRangeHelper.ayahStartMs(
            surah,
            trackedAyah,
            durMs,
            includeOpeningOnFirstAyah: false,
          );
          unawaited(_seekWithinFullSurah(startMs));
          return;
        }
        if (_ayahRepeatCount < repeatTarget - 1) {
          _ayahRepeatCount++;
          final startMs = HifdhAudioRangeHelper.ayahStartMs(
            surah,
            trackedAyah,
            durMs,
            includeOpeningOnFirstAyah: false,
          );
          unawaited(_seekWithinFullSurah(startMs));
          return;
        }
        _ayahRepeatCount = 0;
        if (trackedAyah < totalVerses) {
          activeAyahNotifier.value = trackedAyah + 1;
        }
      }
      return;
    }

    final detectedAyah = HifdhAudioRangeHelper.ayahAtPosition(
      surah,
      posMs,
      durMs,
    );
    if (activeAyahNotifier.value != detectedAyah) {
      activeAyahNotifier.value = detectedAyah;
    }
  }

  void _setVerseRepeatCountImpl(int count) {
    _verseRepeatTarget = count;
    _ayahRepeatCount = 0;
    verseRepeatTargetNotifier.value = count;
    if (count == 0) {
      repeatModeNotifier.value = AudioRepeatMode.infinite;
    } else if (count == 1) {
      repeatModeNotifier.value = AudioRepeatMode.none;
    } else {
      repeatModeNotifier.value = AudioRepeatMode.repeatOnce;
    }
    if (count > 1 || count == 0) {
      final s = activeSurahNotifier.value;
      final a = activeAyahNotifier.value ?? 1;
      // If a verse-based reciter was playing a merged full_surah.mp3, switch to
      // individual verse playback so exact verse files repeat. For surah-based
      // reciters (e.g. Ahmad Talib), keep their reciter and repeat via
      // HifdhAudioRangeHelper timestamps inside full_surah.mp3.
      if (!_selectedReciter.isSurahBased && isFullSurahMode) {
        isFullSurahModeNotifier.value = false;
        if (s != null && isPlayingNotifier.value) {
          playContinuous(
            surah: s,
            startAyah: a,
            endAyah: _endAyah > 0 ? _endAyah : null,
            reciter: _selectedReciter,
            autoPlay: true,
          );
        }
      }
    }
  }

  Future<void> _playHifdhRangeImpl({
    required int surah,
    required int startAyah,
    required int endAyah,
    int repeatCount = 1,
    QuranReciter? reciter,
  }) async {
    final totalVerses = quran.getVerseCount(surah);
    final effectiveStart = startAyah.clamp(1, endAyah);
    final effectiveEnd = endAyah.clamp(effectiveStart, totalVerses);
    _ayahRepeatCount = 0;
    hifdhRangeNotifier.value = HifdhRangeConfig(
      surah: surah,
      startAyah: effectiveStart,
      endAyah: effectiveEnd,
      repeatCount: repeatCount,
      currentIteration: 0,
    );
    final r = reciter ?? _selectedReciter;
    if (r.isSurahBased) {
      final durMs = _safeDurationMs;
      if (isFullSurahMode &&
          activeSurahNotifier.value == surah &&
          activeReciter.id == r.id &&
          durMs > 0) {
        activeAyahNotifier.value = effectiveStart;
        final startMs = HifdhAudioRangeHelper.ayahStartMs(
          surah,
          effectiveStart,
          durMs,
          includeOpeningOnFirstAyah: effectiveStart == 1,
        );
        _playWhenReady = true;
        await _seekWithinFullSurah(startMs);
        if (!isPlayingNotifier.value) {
          await resume();
        }
        return;
      }
      await playFullSurah(
        surah: surah,
        reciter: r,
        autoPlay: true,
        hasExplicitEnd: true,
        initialAyah: effectiveStart,
      );
      return;
    }

    isFullSurahModeNotifier.value = false;
    await playContinuous(
      surah: surah,
      startAyah: effectiveStart,
      endAyah: effectiveEnd,
      reciter: r,
    );
  }

  void _setSleepTimerImpl(int? minutes, {bool atEndOfSurah = false}) {
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

  void _triggerSleepTimerImpl() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerEndTime = null;
    sleepTimerMinutesNotifier.value = null;
    sleepTimerRemainingSecondsNotifier.value = null;
    stopAtEndOfSurahNotifier.value = false;
    pause();
  }
}
