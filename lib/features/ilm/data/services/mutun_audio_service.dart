import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

enum MutunRepeatMode {
  none,
  singleParagraph,
  entireMatn,
}

class MutunReciter {
  final String id;
  final String name;
  final String description;

  const MutunReciter({
    required this.id,
    required this.name,
    required this.description,
  });
}

class MutunAudioService {
  static final MutunAudioService _instance = MutunAudioService._internal();
  factory MutunAudioService() => _instance;

  MutunAudioService._internal() {
    _initAudioListener();
  }

  final AudioPlayer _player = AudioPlayer();

  static const List<MutunReciter> availableReciters = [
    MutunReciter(
      id: 'sini',
      name: 'د. عبد العزيز الصيني',
      description: 'قراءة محققة متقنة وفق نشرة الشيخ د. عبدالمحسن القاسم',
    ),
    MutunReciter(
      id: 'tayyib',
      name: 'الشيخ معاذ الطيب',
      description: 'قراءة تعليمية مرتلة لمتون طالب العلم',
    ),
  ];

  MutunReciter _selectedReciter = availableReciters[0];
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
      ValueNotifier<MutunReciter>(availableReciters[0]);
  final ValueNotifier<Duration> positionNotifier = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier<Duration>(Duration.zero);

  String? _currentAudioUrl;
  int _totalParagraphs = 1;

  void _initAudioListener() {
    _player.playerStateStream.listen((state) {
      final isPlaying = state.playing &&
          state.processingState != ProcessingState.completed &&
          state.processingState != ProcessingState.idle;
      final isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;

      if (isPlayingNotifier.value != isPlaying) {
        isPlayingNotifier.value = isPlaying;
      }
      if (isLoadingNotifier.value != isLoading) {
        isLoadingNotifier.value = isLoading;
      }

      if (state.processingState == ProcessingState.completed) {
        _handleTrackCompletion();
      }
    });

    _player.positionStream.listen((pos) {
      positionNotifier.value = pos;
    });

    _player.durationStream.listen((dur) {
      if (dur != null) {
        durationNotifier.value = dur;
      }
    });
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
      // Reload audio if currently playing
      if (activeBookIdNotifier.value != null && isPlayingNotifier.value) {
        playMatnAudio(
          bookId: activeBookIdNotifier.value!,
          audioUrl: _currentAudioUrl ?? '',
          paragraphIndex: activeParagraphNotifier.value ?? 1,
          totalParagraphs: _totalParagraphs,
        );
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
  }) async {
    try {
      activeBookIdNotifier.value = bookId;
      activeParagraphNotifier.value = paragraphIndex;
      _currentAudioUrl = audioUrl;
      _totalParagraphs = totalParagraphs;
      isLoadingNotifier.value = true;

      if (audioUrl.isNotEmpty) {
        await _player.setUrl(audioUrl);
        await _player.setSpeed(speedNotifier.value);
        await _player.play();
      }
    } catch (e) {
      debugPrint('Error playing mutn audio: $e');
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  void seekToParagraph(int index) {
    activeParagraphNotifier.value = index;
    // If playing, restart paragraph or seek
    if (isPlayingNotifier.value) {
      _player.seek(Duration.zero);
      _player.play();
    }
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

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    activeBookIdNotifier.value = null;
    activeParagraphNotifier.value = null;
    positionNotifier.value = Duration.zero;
  }

  void dispose() {
    _player.dispose();
  }
}
