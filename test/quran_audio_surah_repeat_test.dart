import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_service.dart';

class _MockControlledPlayer implements AudioPlayer {
  final states = StreamController<PlayerState>.broadcast(sync: true);
  final positionCtrl = StreamController<Duration>.broadcast(sync: true);
  final seekHistory = <Duration>[];
  final playedSources = <String>[];
  String currentSource = '';
  bool running = false;
  ProcessingState phase = ProcessingState.idle;
  Duration _currentPos = Duration.zero;
  Duration? _duration;

  @override
  Stream<PlayerState> get playerStateStream => states.stream;

  @override
  Stream<Duration> get positionStream => positionCtrl.stream;

  @override
  Duration get position => _currentPos;

  @override
  Duration? get duration => _duration;

  @override
  ProcessingState get processingState => phase;

  @override
  bool get playing => running;

  void emitState(ProcessingState state) {
    phase = state;
    states.add(PlayerState(running, state));
  }

  void complete() {
    emitState(ProcessingState.completed);
  }

  void emitPosition(Duration pos) {
    _currentPos = pos;
    positionCtrl.add(pos);
  }

  @override
  Future<Duration?> setAudioSource(
    AudioSource audioSource, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    currentSource = (audioSource as UriAudioSource).uri.path;
    _currentPos = initialPosition ?? Duration.zero;
    _duration = const Duration(minutes: 1); // 60s
    emitState(ProcessingState.loading);
    emitState(ProcessingState.ready);
    return _duration;
  }

  @override
  Future<void> play() async {
    running = true;
    playedSources.add(currentSource);
    emitState(ProcessingState.ready);
  }

  @override
  Future<void> pause() async {
    running = false;
    emitState(phase);
  }

  @override
  Future<void> stop() async {
    running = false;
    emitState(ProcessingState.idle);
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    final pos = position ?? Duration.zero;
    _currentPos = pos;
    seekHistory.add(pos);
  }

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> dispose() async {
    await stop();
    await states.close();
    await positionCtrl.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> flushEvents() async {
  for (var i = 0; i < 40; i++) {
    await Future<void>.value();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Full Surah Audio Repetition & 15-Second Jump Prevention Tests', () {
    late _MockControlledPlayer mockPlayer;
    late QuranAudioService service;

    setUp(() {
      mockPlayer = _MockControlledPlayer();
      service = QuranAudioService.forTesting(
        player: mockPlayer,
        sourceResolver: (surah, ayah, reciter) async =>
            AudioSource.uri(Uri.parse('https://audio.test/surah_$surah.mp3')),
      );
    });

    tearDown(() async {
      service.dispose();
      await flushEvents();
    });

    test('cycleRepeatMode and setRepeatMode set surah repeat without corrupting verse repeat target', () async {
      expect(service.repeatModeNotifier.value, AudioRepeatMode.none);
      expect(service.verseRepeatTarget, 1);

      await service.setRepeatMode(AudioRepeatMode.infinite);
      expect(service.repeatModeNotifier.value, AudioRepeatMode.infinite);
      expect(service.verseRepeatTarget, 1, reason: 'Must remain 1 to avoid verse-level looping inside full surah');

      await service.setRepeatMode(AudioRepeatMode.repeatOnce);
      expect(service.repeatModeNotifier.value, AudioRepeatMode.repeatOnce);
      expect(service.verseRepeatTarget, 1, reason: 'Must remain 1 to avoid verse-level looping inside full surah');

      await service.setRepeatMode(AudioRepeatMode.none);
      expect(service.repeatModeNotifier.value, AudioRepeatMode.none);
      expect(service.verseRepeatTarget, 1);
    });

    test('Position ticks near the end of a full surah do NOT rewind by 15s under repeat mode', () async {
      final surahReciter = QuranReciter.defaultReciters.firstWhere((r) => r.isSurahBased);
      service.setSelectedReciter(surahReciter);
      await service.setRepeatMode(AudioRepeatMode.infinite);

      unawaited(service.playFullSurah(surah: 1, reciter: surahReciter));
      await flushEvents();

      expect(service.isFullSurahMode, isTrue);
      expect(service.verseRepeatTarget, 1);

      final totalDurMs = 60000;
      // Emit a position near the end of the last ayah (100ms before duration)
      mockPlayer.emitPosition(Duration(milliseconds: totalDurMs - 100));
      await flushEvents();

      // Ensure NO backwards seeks occurred (specifically no jump back to ayahStartMs)
      expect(
        mockPlayer.seekHistory.where((d) => d > Duration.zero),
        isEmpty,
        reason: 'Audio must never seek backwards by 15s when approaching the end of full surah playback',
      );
    });

    test('Full surah completion under AudioRepeatMode.infinite restarts cleanly from Duration.zero', () async {
      final surahReciter = QuranReciter.defaultReciters.firstWhere((r) => r.isSurahBased);
      service.setSelectedReciter(surahReciter);
      await service.setRepeatMode(AudioRepeatMode.infinite);

      unawaited(service.playFullSurah(surah: 1, reciter: surahReciter));
      await flushEvents();

      expect(service.activeSurahNotifier.value, 1);
      mockPlayer.seekHistory.clear();

      // Trigger track completion (surah finishes)
      mockPlayer.complete();
      await flushEvents();

      // Player must have seeked to Duration.zero to repeat the full surah from the beginning
      expect(mockPlayer.seekHistory, contains(Duration.zero));
      expect(service.activeAyahNotifier.value, 1);
      expect(service.activeSurahNotifier.value, 1);
      expect(mockPlayer.running, isTrue);
    });

    test('Full surah completion under AudioRepeatMode.repeatOnce replays once from Duration.zero then advances', () async {
      final surahReciter = QuranReciter.defaultReciters.firstWhere((r) => r.isSurahBased);
      service.setSelectedReciter(surahReciter);
      service.setSurahPlaybackQueue([1, 2], downloadedOnly: true);
      await service.setRepeatMode(AudioRepeatMode.repeatOnce);

      unawaited(service.playFullSurah(surah: 1, reciter: surahReciter));
      await flushEvents();

      expect(service.activeSurahNotifier.value, 1);
      mockPlayer.seekHistory.clear();

      // First completion: repeats surah 1 from 0:00
      mockPlayer.complete();
      await flushEvents();

      expect(mockPlayer.seekHistory, contains(Duration.zero));
      expect(service.activeSurahNotifier.value, 1);

      // Second completion: advances to surah 2 in queue
      mockPlayer.complete();
      await flushEvents();

      expect(service.activeSurahNotifier.value, 2);
    });
  });
}
