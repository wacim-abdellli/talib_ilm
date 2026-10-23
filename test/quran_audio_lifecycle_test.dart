import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_service.dart';

class ControlledPlayer implements AudioPlayer {
  final states = StreamController<PlayerState>.broadcast(sync: true);
  final played = <String>[];
  String source = '';
  bool running = false;
  ProcessingState phase = ProcessingState.idle;
  Completer<void>? playback;
  bool failLoads = false;
  bool completeOnStop = true;

  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  @override
  ProcessingState get processingState => phase;
  @override
  bool get playing => running;

  void emit(ProcessingState state) {
    phase = state;
    states.add(PlayerState(running, state));
  }

  void complete({bool duplicate = false}) {
    emit(ProcessingState.completed);
    if (duplicate) emit(ProcessingState.completed);
    playback?.complete();
    playback = null;
  }

  @override
  Future<Duration?> setAudioSource(
    AudioSource audioSource, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    if (failLoads) throw StateError('source unavailable');
    source = (audioSource as UriAudioSource).uri.path;
    emit(ProcessingState.loading);
    emit(ProcessingState.ready);
    return null;
  }

  @override
  Future<void> play() {
    running = true;
    played.add(source);
    emit(ProcessingState.ready);
    playback = Completer<void>();
    return playback!.future;
  }

  @override
  Future<void> pause() async {
    running = false;
    playback?.complete();
    playback = null;
    emit(phase);
  }

  @override
  Future<void> stop() async {
    running = false;
    if (completeOnStop) playback?.complete();
    playback = null;
    emit(ProcessingState.idle);
  }

  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<Duration?> setUrl(
    String url, {
    Map<String, String>? headers,
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async {
    if (failLoads) throw StateError('source unavailable');
    return setAudioSource(AudioSource.uri(Uri.parse(url)));
  }

  @override
  Future<void> dispose() async {
    await stop();
    await states.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<AudioSource> remote(int surah, int ayah, QuranReciter reciter) async =>
    AudioSource.uri(Uri.parse('https://audio.test/$surah/$ayah'));

Future<void> flushOperations() async {
  // Drain the finite chain of controlled futures, without wall-clock sleeps.
  for (var i = 0; i < 40; i++) {
    await Future<void>.value();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ControlledPlayer player;
  late QuranAudioService service;

  setUp(() {
    player = ControlledPlayer();
    service = QuranAudioService.forTesting(
      player: player,
      sourceResolver: remote,
    );
  });
  tearDown(() async {
    service.dispose();
    await flushOperations();
  });

  test('completion advances exactly once despite duplicate events', () async {
    unawaited(service.playVerse(1, 1));
    await flushOperations();
    player.complete(duplicate: true);
    await flushOperations();
    expect(player.played, ['/1/1', '/1/2']);
  });

  test('repeat once plays twice then advances', () async {
    await service.setRepeatMode(AudioRepeatMode.repeatOnce);
    unawaited(service.playVerse(1, 1));
    await flushOperations();
    player.complete();
    await flushOperations();
    player.complete();
    await flushOperations();
    expect(player.played, ['/1/1', '/1/1', '/1/2']);
  });

  test('infinite repeat survives multiple completions', () async {
    await service.setRepeatMode(AudioRepeatMode.infinite);
    unawaited(service.playVerse(1, 1));
    await flushOperations();
    for (var i = 0; i < 3; i++) {
      player.complete();
      await flushOperations();
    }
    expect(player.played, ['/1/1', '/1/1', '/1/1', '/1/1']);
  });

  test('stop during source resolution cannot restart playback', () async {
    service.dispose();
    await flushOperations();
    player = ControlledPlayer();
    final pending = Completer<AudioSource>();
    service = QuranAudioService.forTesting(
      player: player,
      sourceResolver: (_, _, _) => pending.future,
    );
    unawaited(service.playVerse(1, 1));
    await flushOperations();
    await service.stop();
    pending.complete(await remote(1, 1, QuranAudioService.reciters.first));
    await flushOperations();
    expect(player.played, isEmpty);
    expect(service.activeAyahNotifier.value, isNull);
  });

  test('a delayed older request cannot replace the latest request', () async {
    service.dispose();
    await flushOperations();
    player = ControlledPlayer();
    final pending = Completer<AudioSource>();
    service = QuranAudioService.forTesting(
      player: player,
      sourceResolver: (s, a, r) => a == 1 ? pending.future : remote(s, a, r),
    );
    unawaited(service.playVerse(1, 1));
    unawaited(service.playVerse(1, 2));
    await flushOperations();
    pending.complete(await remote(1, 1, QuranAudioService.reciters.first));
    await flushOperations();
    expect(player.played, ['/1/2']);
    expect(service.activeAyahNotifier.value, 2);
  });

  test('play command finishes loading before playback ends', () async {
    var ready = false;
    unawaited(service.playVerse(1, 1).then((_) => ready = true));
    await flushOperations();
    expect(ready, isTrue);
    expect(player.playback!.isCompleted, isFalse);
  });

  test('single verse stops at completion', () async {
    await service.playVerse(1, 1, singleVerse: true);
    player.complete();
    await flushOperations();
    expect(player.played, ['/1/1']);
    expect(service.activeAyahNotifier.value, isNull);
  });

  test('continuous crosses surahs and stops at the final verse', () async {
    await service.playContinuous(surah: 1, startAyah: 7);
    player.complete();
    await flushOperations();
    expect(player.played, ['/1/7', '/2/1']);
    await service.playContinuous(surah: 114, startAyah: 6);
    player.complete();
    await flushOperations();
    expect(service.activeSurahNotifier.value, isNull);
    expect(player.played.last, '/114/6');
  });

  test('explicit range stops instead of jumping surahs', () async {
    await service.playContinuous(surah: 1, startAyah: 1, endAyah: 2);
    player.complete();
    await flushOperations();
    player.complete();
    await flushOperations();
    expect(player.played, ['/1/1', '/1/2']);
    expect(service.activeAyahNotifier.value, isNull);
  });

  test('pause during load is respected until explicit resume', () async {
    service.dispose();
    await flushOperations();
    player = ControlledPlayer();
    final pending = Completer<AudioSource>();
    service = QuranAudioService.forTesting(
      player: player,
      sourceResolver: (_, _, _) => pending.future,
    );
    unawaited(service.playVerse(1, 1));
    await service.pause();
    pending.complete(await remote(1, 1, QuranAudioService.reciters.first));
    await flushOperations();
    expect(player.played, isEmpty);
    await service.resume();
    expect(player.played, ['/1/1']);
  });

  test('dispose during load prevents playback and notifier writes', () async {
    service.dispose();
    await flushOperations();
    player = ControlledPlayer();
    final pending = Completer<AudioSource>();
    service = QuranAudioService.forTesting(
      player: player,
      sourceResolver: (_, _, _) => pending.future,
    );
    unawaited(service.playVerse(1, 1));
    service.dispose();
    pending.complete(await remote(1, 1, QuranAudioService.reciters.first));
    await flushOperations();
    expect(player.played, isEmpty);
  });

  test('stale playback failure cannot stop a newer verse', () async {
    player.completeOnStop = false;
    await service.playVerse(1, 1);
    final olderPlayback = player.playback!;
    await service.playVerse(1, 2);
    olderPlayback.completeError(StateError('old stream failed'));
    await flushOperations();
    expect(service.errorNotifier.value, isNull);
    expect(player.running, isTrue);
    expect(service.activeAyahNotifier.value, 2);
  });

  test('stop during retry cannot restart the replacement player', () async {
    service.dispose();
    await flushOperations();
    player = ControlledPlayer()..failLoads = true;
    final replacement = ControlledPlayer();
    final retry = Completer<void>();
    service = QuranAudioService.forTesting(
      player: player,
      sourceResolver: remote,
      playerFactory: () => replacement,
      retryDelay: () => retry.future,
    );
    unawaited(service.playVerse(1, 1));
    await flushOperations();
    await service.stop();
    retry.complete();
    await flushOperations();
    expect(replacement.played, isEmpty);
    expect(service.activeAyahNotifier.value, isNull);
  });

  test('explicit reciter persists across automatic verse changes', () async {
    service.dispose();
    await flushOperations();
    player = ControlledPlayer();
    final resolved = <String>[];
    service = QuranAudioService.forTesting(
      player: player,
      sourceResolver: (s, a, r) {
        resolved.add(r.id);
        return remote(s, a, r);
      },
    );
    await service.playVerse(1, 1, reciter: QuranAudioService.reciters[1]);
    player.complete();
    await flushOperations();
    expect(resolved, ['qatami', 'qatami']);
    service.setSelectedReciter(QuranAudioService.reciters[4]);
    await service.playVerse(1, 3);
    expect(resolved.last, 'husary');
  });

  test('manual next across surahs uses the new surah length', () async {
    await service.playContinuous(surah: 1, startAyah: 7);
    await service.nextAyah();
    for (var i = 0; i < 7; i++) {
      player.complete();
      await flushOperations();
    }
    expect(service.activeSurahNotifier.value, 2);
    expect(service.activeAyahNotifier.value, 8);
  });

  test(
    'manual previous across surahs does not overrun the shorter surah',
    () async {
      await service.playContinuous(surah: 2, startAyah: 1);
      await service.previousAyah();
      expect(service.activeSurahNotifier.value, 1);
      expect(service.activeAyahNotifier.value, 7);
      player.complete();
      await flushOperations();
      expect(player.played, ['/2/1', '/1/7', '/2/1']);
    },
  );

  test('manual navigation beyond an explicit end leaves that range', () async {
    await service.playContinuous(surah: 1, startAyah: 2, endAyah: 2);
    await service.nextAyah();
    player.complete();
    await flushOperations();
    expect(service.activeAyahNotifier.value, 4);
  });

  test('manual navigation within an explicit range retains its end', () async {
    await service.playContinuous(surah: 1, startAyah: 1, endAyah: 3);
    await service.nextAyah();
    player.complete();
    await flushOperations();
    player.complete();
    await flushOperations();
    expect(player.played, ['/1/1', '/1/2', '/1/3']);
    expect(service.activeAyahNotifier.value, isNull);
  });

  test('previous at the first verse preserves single-verse mode', () async {
    await service.playVerse(1, 1, singleVerse: true);
    await service.previousAyah();
    player.complete();
    await flushOperations();
    expect(player.played, ['/1/1']);
    expect(service.activeAyahNotifier.value, isNull);
  });

  test('next at the final Quran verse stops playback', () async {
    await service.playContinuous(surah: 114, startAyah: 6);
    await service.nextAyah();
    expect(service.activeAyahNotifier.value, isNull);
    expect(player.running, isFalse);
  });
}
