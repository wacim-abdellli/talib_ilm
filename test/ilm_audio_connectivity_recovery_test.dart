import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/core/services/offline_connectivity_service.dart';
import 'package:talib_ilm/features/ilm/data/services/mutun_audio_service.dart';
import 'package:talib_ilm/features/ilm/data/services/mutun_audio_source_loader.dart';
import 'package:talib_ilm/features/ilm/presentation/widgets/offline_status_banner.dart';

class _ControllableMutunPlayer implements AudioPlayer {
  final states = StreamController<PlayerState>.broadcast(sync: true);
  final events = StreamController<PlaybackEvent>.broadcast(sync: true);
  final positions = StreamController<Duration>.broadcast(sync: true);
  final durations = StreamController<Duration?>.broadcast(sync: true);
  final indices = StreamController<int?>.broadcast(sync: true);

  bool failOnLoad = false;
  Object? customLoadError;
  bool disposed = false;
  bool playingFlag = false;
  ProcessingState stateFlag = ProcessingState.idle;
  AudioSource? loadedSource;
  final List<String> attemptedUrls = [];

  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  @override
  Stream<PlaybackEvent> get playbackEventStream => events.stream;
  @override
  Stream<Duration> get positionStream => positions.stream;
  @override
  Stream<Duration?> get durationStream => durations.stream;
  @override
  Stream<int?> get currentIndexStream => indices.stream;
  @override
  Duration get position => Duration.zero;
  @override
  ProcessingState get processingState => stateFlag;
  @override
  bool get playing => playingFlag;
  @override
  AudioSource? get audioSource => loadedSource;

  @override
  Future<Duration?> setAudioSource(
    AudioSource audioSource, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    if (audioSource is UriAudioSource) {
      attemptedUrls.add(audioSource.uri.toString());
    }
    if (failOnLoad) {
      throw customLoadError ?? TimeoutException('Simulated offline failure');
    }
    loadedSource = audioSource;
    stateFlag = ProcessingState.ready;
    const d = Duration(minutes: 12);
    durations.add(d);
    states.add(PlayerState(false, ProcessingState.ready));
    return d;
  }

  @override
  Future<Duration?> setUrl(
    String url, {
    Map<String, String>? headers,
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async {
    attemptedUrls.add(url);
    if (failOnLoad) {
      throw customLoadError ?? TimeoutException('Simulated offline failure');
    }
    stateFlag = ProcessingState.ready;
    const d = Duration(minutes: 12);
    durations.add(d);
    return d;
  }

  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> setLoopMode(LoopMode mode) async {}

  @override
  Future<void> play() async {
    playingFlag = true;
    stateFlag = ProcessingState.ready;
    states.add(PlayerState(true, ProcessingState.ready));
  }

  @override
  Future<void> pause() async {
    playingFlag = false;
    states.add(PlayerState(false, stateFlag));
  }

  @override
  Future<void> stop() async {
    playingFlag = false;
    stateFlag = ProcessingState.idle;
    loadedSource = null;
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {}

  @override
  Future<void> dispose() async {
    disposed = true;
    await states.close();
    await events.close();
    await positions.close();
    await durations.close();
    await indices.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    OfflineConnectivityService.setOverrideForTesting(false);
  });

  tearDown(() {
    OfflineConnectivityService.setOverrideForTesting(null);
  });

  group('OfflineConnectivityService & OfflineStatusBanner Recovery', () {
    testWidgets('Banner shows when offline and auto-hides & resets when network returns', (tester) async {
      OfflineConnectivityService.setOverrideForTesting(true);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: OfflineStatusBanner(onOpenDownloadsHub: () {}),
          ),
        ),
      );
      expect(find.text('وضع عدم الاتصال بالإنترنت'), findsOneWidget);

      // Network returns -> banner must disappear immediately without closing/reopening
      OfflineConnectivityService.setOverrideForTesting(false);
      await tester.pump();
      expect(find.text('وضع عدم الاتصال بالإنترنت'), findsNothing);

      // Disconnect again later -> should appear again (dismiss state reset cleanly)
      OfflineConnectivityService.setOverrideForTesting(true);
      await tester.pump();
      expect(find.text('وضع عدم الاتصال بالإنترنت'), findsOneWidget);
    });
  });

  group('MutunAudioSourceLoader & MutunAudioService Recovery', () {
    test('Timeout on primary files.a-alqasim.com does NOT permanently blacklist host once online', () async {
      final failingPlayer = _ControllableMutunPlayer()..failOnLoad = true;
      final healthyPlayer = _ControllableMutunPlayer()..failOnLoad = false;
      final loader = MutunAudioSourceLoader();
      const primaryUrl =
          'https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini/0101AlAthkaar_AbdulAzizAsSini.mp3';

      // Fail initially (e.g., timeout when offline)
      final failRes = await loader.loadIntoPlayer(
        player: failingPlayer,
        bookId: 'bk_adhkar_adab',
        requestedUrl: primaryUrl,
        reciter: MutunReciterDefaults.sini,
      );
      expect(failRes.loaded, isFalse);

      // Try again on healthy player -> MUST still use primaryUrl (files.a-alqasim.com), NOT skip to archive.org!
      final okRes = await loader.loadIntoPlayer(
        player: healthyPlayer,
        bookId: 'bk_adhkar_adab',
        requestedUrl: primaryUrl,
        reciter: MutunReciterDefaults.sini,
      );
      expect(okRes.loaded, isTrue);
      expect(okRes.effectiveUrl, equals(primaryUrl));
      expect(healthyPlayer.attemptedUrls.first, equals(primaryUrl));
    });

    test('MutunAudioService resets stale duration, recovers cleanly when net returns, and plays on next tap without app restart', () async {
      final players = <_ControllableMutunPlayer>[];
      bool simulateNetworkDown = true;

      final service = MutunAudioService.forTesting(
        playerFactory: () {
          final p = _ControllableMutunPlayer()..failOnLoad = simulateNetworkDown;
          players.add(p);
          return p;
        },
        player: (() {
          final p = _ControllableMutunPlayer()..failOnLoad = true;
          players.add(p);
          return p;
        })(),
      );

      // Simulate stale duration left from a previous track (e.g. 04:13)
      service.durationNotifier.value = const Duration(minutes: 4, seconds: 13);

      // 1. User taps play while offline
      OfflineConnectivityService.setOverrideForTesting(true);
      await service.togglePlayPause(bookId: 'bk_adhkar_adab');

      expect(service.isPlayingNotifier.value, isFalse);
      expect(service.playbackErrorNotifier.value, isNotNull);
      // Stale duration from previous track must NOT linger when failing on new book!
      expect(service.durationNotifier.value, equals(Duration.zero));

      // 2. Network comes back!
      simulateNetworkDown = false;
      OfflineConnectivityService.setOverrideForTesting(false);
      await Future<void>.delayed(Duration.zero);

      // Connectivity returning clears stale error automatically
      expect(service.playbackErrorNotifier.value, isNull);

      // 3. User taps play again WITHOUT exiting & reopening app -> plays primary Sini audio immediately!
      await service.togglePlayPause(bookId: 'bk_adhkar_adab');

      expect(service.isPlayingNotifier.value, isTrue);
      expect(service.playbackErrorNotifier.value, isNull);
      expect(service.durationNotifier.value, equals(const Duration(minutes: 12)));
      expect(
        players.last.attemptedUrls.first,
        contains('0101AlAthkaar_AbdulAzizAsSini.mp3'),
      );
    });

    test('TLS HandshakeException short-circuits duplicate setUrl and switches immediately to HTTPS fallback', () async {
      final failingTlsPlayer = _ControllableMutunPlayer()
        ..failOnLoad = true
        ..customLoadError = const HandshakeException('TLS certificate error');
      final fallbackPlayer = _ControllableMutunPlayer()..failOnLoad = false;
      final loader = MutunAudioSourceLoader();
      const primaryUrl =
          'https://files.a-alqasim.com/audio/Mutoon/AbdulAzizAsSini/0101AlAthkaar_AbdulAzizAsSini.mp3';

      final res = await loader.loadWithFallback(
        getPlayer: () =>
            failingTlsPlayer.attemptedUrls.isEmpty ? failingTlsPlayer : fallbackPlayer,
        recreatePlayer: () async {},
        bookId: 'bk_adhkar_adab',
        requestedUrl: primaryUrl,
        reciter: MutunReciterDefaults.sini,
      );

      // Must skip redundant setUrl() retry on the same TLS-failing host (1 attempt, not 2)
      expect(failingTlsPlayer.attemptedUrls, hasLength(1));
      expect(res.loaded, isTrue);
      expect(res.usedFallback, isTrue);
      expect(res.effectiveUrl, contains('archive.org'));

      // Next call during TLS cooldown skips primary TLS host immediately
      final fastFallbackPlayer = _ControllableMutunPlayer()..failOnLoad = false;
      final cachedRes = await loader.loadIntoPlayer(
        player: fastFallbackPlayer,
        bookId: 'bk_adhkar_adab',
        requestedUrl: primaryUrl,
        reciter: MutunReciterDefaults.sini,
      );
      expect(cachedRes.usedFallback, isTrue);
      expect(fastFallbackPlayer.attemptedUrls.first, contains('archive.org'));

      // Reset clears temporary bypass so healthy primary host is attempted again
      loader.resetTransientFailures();
      final resetPlayer = _ControllableMutunPlayer()..failOnLoad = false;
      final restoredRes = await loader.loadIntoPlayer(
        player: resetPlayer,
        bookId: 'bk_adhkar_adab',
        requestedUrl: primaryUrl,
        reciter: MutunReciterDefaults.sini,
      );
      expect(restoredRes.usedFallback, isFalse);
      expect(resetPlayer.attemptedUrls.first, equals(primaryUrl));
    });
  });
}
