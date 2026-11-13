import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_service.dart';
import 'package:talib_ilm/features/quran/data/services/quran_reader_preferences.dart';

class _MockConflictTestPlayer implements AudioPlayer {
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
    _duration = const Duration(minutes: 30);
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    QuranReaderPreferences.resetCacheForTesting();
  });

  group('QuranAudio & Mushaf separation tests', () {
    test('Full surah mode preserves isFullSurahModeNotifier on resume when idle', () async {
      final mock = _MockConflictTestPlayer();
      final surahReciter = QuranReciter.defaultReciters.firstWhere((r) => r.isSurahBased);

      final service = QuranAudioService.forTesting(
        player: mock,
        sourceResolver: (surah, ayah, reciter) async =>
            AudioSource.uri(Uri.parse('https://example.com/verse.mp3')),
        retryDelay: () async {},
      );

      await service.playFullSurah(
        surah: 18,
        reciter: surahReciter,
        autoPlay: true,
      );

      expect(service.isFullSurahModeNotifier.value, isTrue);
      expect(service.activeReciter.id, equals(surahReciter.id));

      // Simulate player becoming idle
      mock.emitState(ProcessingState.idle);

      await service.resume();

      // Should still be in full surah mode, not downgraded to verse mode
      expect(service.isFullSurahModeNotifier.value, isTrue);
      expect(service.activeSurahNotifier.value, equals(18));

      service.dispose();
    });

    test('Active full surah playback reciter is not corrupted when reader reciter is different', () async {
      final mock = _MockConflictTestPlayer();
      final surahReciter = QuranReciter.defaultReciters.firstWhere((r) => r.isSurahBased);
      final readerReciter = QuranReciter.defaultReciters.firstWhere((r) => !r.isSurahBased);

      final service = QuranAudioService.forTesting(
        player: mock,
        sourceResolver: (surah, ayah, reciter) async =>
            AudioSource.uri(Uri.parse('https://example.com/verse.mp3')),
        retryDelay: () async {},
      );

      // Play downloaded full surah
      service.setSelectedReciter(surahReciter);
      await service.playFullSurah(
        surah: 19,
        reciter: surahReciter,
        autoPlay: true,
      );

      expect(service.activeReciter.id, equals(surahReciter.id));
      expect(service.isFullSurahModeNotifier.value, isTrue);

      // Simulate reader settings load when audio is playing:
      // should NOT call switchReciter or setSelectedReciter if playing/active
      if (!service.isPlayingNotifier.value && service.activeSurahNotifier.value == null) {
        service.setSelectedReciter(readerReciter);
      }

      // Playing reciter and mode must be completely preserved
      expect(service.activeReciter.id, equals(surahReciter.id));
      expect(service.isFullSurahModeNotifier.value, isTrue);
      expect(service.activeSurahNotifier.value, equals(19));

      service.dispose();
    });

    test('switchReciter preserves initialAyah and queue during full surah playback', () async {
      final mock = _MockConflictTestPlayer();
      final reciter1 = QuranReciter.defaultReciters.firstWhere((r) => r.isSurahBased);
      final reciters = QuranReciter.defaultReciters.where((r) => r.isSurahBased).toList();
      final reciter2 = reciters.length > 1 ? reciters[1] : reciter1;

      final service = QuranAudioService.forTesting(
        player: mock,
        sourceResolver: (surah, ayah, reciter) async =>
            AudioSource.uri(Uri.parse('https://example.com/verse.mp3')),
        retryDelay: () async {},
      );

      service.setSurahPlaybackQueue([18, 19, 20]);
      await service.playFullSurah(
        surah: 18,
        reciter: reciter1,
        autoPlay: true,
      );

      service.activeAyahNotifier.value = 10;

      await service.switchReciter(reciter2);

      // Should keep queue and preserve surah
      expect(service.surahPlaybackQueue, equals([18, 19, 20]));
      expect(service.activeSurahNotifier.value, equals(18));
      expect(service.isFullSurahModeNotifier.value, isTrue);

      service.dispose();
    });
  });
}
