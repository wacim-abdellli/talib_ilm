import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:talib_ilm/app/theme/app_theme.dart';
import 'package:talib_ilm/features/quran/data/services/hifdh_audio_range_helper.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_service.dart';
import 'package:talib_ilm/features/quran/presentation/widgets/hifdh_repeat_options_sheet.dart';

class _FakePlayer implements AudioPlayer {
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  ProcessingState get processingState => ProcessingState.idle;
  @override
  Duration? get duration => null;
  @override
  bool get playing => false;
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> seek(Duration? position, {int? index}) async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<Duration?> setAudioSource(AudioSource source, {bool preload = true, int? initialIndex, Duration? initialPosition}) async => null;
  @override
  Future<Duration?> setUrl(String url, {Map<String, String>? headers, Duration? initialPosition, bool preload = true, dynamic tag}) async => null;
  @override
  Future<void> dispose() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranAudioService service;

  setUp(() {
    service = QuranAudioService();
  });

  group('HifdhRangeConfig & Repetition Models', () {
    test('HifdhRangeConfig calculates boundaries and iterations correctly', () {
      final config = HifdhRangeConfig(
        surah: 2,
        startAyah: 1,
        endAyah: 5,
        repeatCount: 3,
        currentIteration: 0,
      );

      expect(config.surah, 2);
      expect(config.startAyah, 1);
      expect(config.endAyah, 5);
      expect(config.repeatCount, 3);
      expect(config.currentIteration, 0);
      expect(config.isInfinite, isFalse);
      expect(config.isCompleted, isFalse);

      final next = config.nextIteration();
      expect(next.currentIteration, 1);
      expect(next.isCompleted, isFalse);

      final completed = next.nextIteration().nextIteration();
      expect(completed.currentIteration, 3);
      expect(completed.isCompleted, isTrue);
    });

    test('HifdhRangeConfig supports infinite repetition mode', () {
      final infiniteConfig = HifdhRangeConfig(
        surah: 1,
        startAyah: 1,
        endAyah: 7,
        repeatCount: 0,
      );

      expect(infiniteConfig.isInfinite, isTrue);
      expect(infiniteConfig.isCompleted, isFalse);
    });
  });

  group('QuranAudioService Hifdh Repetitions', () {
    test('setVerseRepeatCount updates targets and repeat modes predictably', () {
      service.setVerseRepeatCount(1);
      expect(service.verseRepeatTarget, 1);
      expect(service.repeatModeNotifier.value, AudioRepeatMode.none);

      service.setVerseRepeatCount(2);
      expect(service.verseRepeatTarget, 2);
      expect(service.repeatModeNotifier.value, AudioRepeatMode.repeatOnce);

      service.setVerseRepeatCount(3);
      expect(service.verseRepeatTarget, 3);
      expect(service.repeatModeNotifier.value, AudioRepeatMode.repeatOnce);

      service.setVerseRepeatCount(5);
      expect(service.verseRepeatTarget, 5);
      expect(service.repeatModeNotifier.value, AudioRepeatMode.repeatOnce);

      service.setVerseRepeatCount(10);
      expect(service.verseRepeatTarget, 10);
      expect(service.repeatModeNotifier.value, AudioRepeatMode.repeatOnce);

      service.setVerseRepeatCount(0);
      expect(service.verseRepeatTarget, 0);
      expect(service.repeatModeNotifier.value, AudioRepeatMode.infinite);
    });

    test('clearHifdhRange resets the active range config', () {
      service.hifdhRangeNotifier.value = HifdhRangeConfig(
        surah: 1,
        startAyah: 1,
        endAyah: 4,
        repeatCount: 3,
      );

      expect(service.hifdhRangeNotifier.value, isNotNull);
      service.clearHifdhRange();
      expect(service.hifdhRangeNotifier.value, isNull);
    });

    test('playHifdhRange preserves surah-based reciter (e.g. Ahmad Talib) and loops inside full surah', () async {
      final fakePlayer = _FakePlayer();
      final testService = QuranAudioService.forTesting(
        player: fakePlayer,
        sourceResolver: (s, a, r) async => AudioSource.uri(Uri.parse('https://audio.test/$s/$a')),
      );

      final surahBasedReciter = QuranReciter.defaultReciters.firstWhere((r) => r.isSurahBased);
      testService.setSelectedReciter(surahBasedReciter);
      testService.isFullSurahModeNotifier.value = true;

      await testService.playHifdhRange(
        surah: 1,
        startAyah: 3,
        endAyah: 4,
        repeatCount: 3,
      );

      expect(testService.selectedReciter.id, surahBasedReciter.id);
      expect(testService.selectedReciter.isSurahBased, isTrue);
      expect(testService.isFullSurahMode, isTrue);
      expect(testService.hifdhRangeNotifier.value?.startAyah, 3);
      expect(testService.hifdhRangeNotifier.value?.endAyah, 4);
      expect(testService.hifdhRangeNotifier.value?.repeatCount, 3);
      testService.dispose();
    });

    test('setVerseRepeatCount preserves surah-based reciter and disables full surah only for verse-by-verse reciters', () {
      final surahBasedReciter = QuranReciter.defaultReciters.firstWhere((r) => r.isSurahBased);
      service.setSelectedReciter(surahBasedReciter);
      service.isFullSurahModeNotifier.value = true;

      service.setVerseRepeatCount(3);

      expect(service.selectedReciter.id, surahBasedReciter.id);
      expect(service.selectedReciter.isSurahBased, isTrue);
      expect(service.isFullSurahMode, isTrue);
      expect(service.verseRepeatTarget, 3);
    });

    test('HifdhAudioRangeHelper computes monotonic verse boundaries for full-surah audio', () {
      const totalMs = 45000;
      final start1 = HifdhAudioRangeHelper.ayahStartMs(1, 1, totalMs);
      final end1 = HifdhAudioRangeHelper.ayahEndMs(1, 1, totalMs);
      final start4 = HifdhAudioRangeHelper.ayahStartMs(1, 4, totalMs);
      final end5 = HifdhAudioRangeHelper.ayahEndMs(1, 5, totalMs);
      final end7 = HifdhAudioRangeHelper.ayahEndMs(1, 7, totalMs);

      expect(start1, 0);
      expect(end1, greaterThan(start1));
      expect(end5, greaterThan(start4));
      expect(end7, totalMs);
      expect(
        HifdhAudioRangeHelper.ayahAtPosition(
          1,
          start4 + 200,
          totalMs,
        ),
        4,
      );
    });
  });

  group('HifdhRepeatOptionsSheet Widget Tests', () {
    testWidgets('renders verse repeat pills and range loop steppers cleanly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: HifdhRepeatOptionsSheet(
              audioService: service,
              surahNumber: 1,
              currentAyah: 2,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      // Check Header
      expect(find.text('تكرار الحفظ والمراجعة'), findsOneWidget);
      expect(find.textContaining('سورة الفاتحة'), findsOneWidget);

      // Check Verse Repetition Section
      expect(find.text('تكرار الآية الواحدة'), findsOneWidget);
      expect(find.text('معطل (1×)'), findsOneWidget);
      expect(find.text('3 مرات (سنة)'), findsOneWidget);
      expect(find.text('مستمر (∞)'), findsNWidgets(2)); // in verse & range

      // Check Range Loop Section
      expect(find.textContaining('تكرار مقطع كامل للحفظ'), findsOneWidget);
      expect(find.text('من الآية'), findsOneWidget);
      expect(find.text('إلى الآية'), findsOneWidget);

      // Tap on 3x verse repeat pill
      await tester.tap(find.text('3 مرات (سنة)'));
      await tester.pump();

      expect(service.verseRepeatTarget, 3);
      expect(service.repeatModeNotifier.value, AudioRepeatMode.repeatOnce);
    });

    testWidgets('renders dark mode cleanly without layout overflows',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: HifdhRepeatOptionsSheet(
              audioService: service,
              surahNumber: 2,
              currentAyah: 10,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.text('تكرار الحفظ والمراجعة'), findsOneWidget);
      expect(find.textContaining('سورة البقرة'), findsOneWidget);
    });

    testWidgets('keeps start/apply button visible alongside stop button when range loop is active',
        (tester) async {
      service.hifdhRangeNotifier.value = const HifdhRangeConfig(
        surah: 1,
        startAyah: 1,
        endAyah: 5,
        repeatCount: 3,
        currentIteration: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: HifdhRepeatOptionsSheet(
              audioService: service,
              surahNumber: 1,
              currentAyah: 1,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.textContaining('المقطع قيد التكرار الآن'), findsOneWidget);
      expect(find.textContaining('بدء تكرار المقطع'), findsOneWidget);
      expect(find.text('إيقاف تكرار المقطع'), findsOneWidget);
    });
  });
}
