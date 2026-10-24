import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/constants/verified_cities.dart';
import 'package:talib_ilm/core/services/audio_coordinator.dart';
import 'package:talib_ilm/core/services/location_service.dart';
import 'package:talib_ilm/core/services/prayer_time_service.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_curriculum_catalog.dart';
import 'package:talib_ilm/features/quran/data/services/reading_stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task R69 — Runtime Performance & Memory Benchmarks', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PrayerTimeService.clearCache();
    });

    test('Benchmark 1: Core Startup Initialization Sequence', () async {
      const iterations = 30;
      final durations = <int>[];

      for (var i = 0; i < iterations; i++) {
        final sw = Stopwatch()..start();
        SharedPreferences.setMockInitialValues({'test_seed': 'true'});
        final prefs = await SharedPreferences.getInstance();
        final statsService = ReadingStatsService();
        final prayerService = PrayerTimeService(now: () => DateTime(2026, 10, 24, 12, 0));
        await AudioCoordinator.acquireFocus(AudioStreamType.quran);
        final initialToday = prayerService.getCachedOrFallbackPrayerTimesDay();

        sw.stop();
        expect(prefs.getString('test_seed'), 'true');
        expect(statsService, isNotNull);
        expect(initialToday, isNotNull);
        durations.add(sw.elapsedMicroseconds);
      }

      durations.sort();
      final minUs = durations.first;
      final maxUs = durations.last;
      final meanUs = durations.reduce((a, b) => a + b) ~/ durations.length;
      final p95Us = durations[(durations.length * 0.95).floor()];

      debugPrint('BENCHMARK_STARTUP: min=${minUs}us, mean=${meanUs}us, p95=${p95Us}us, max=${maxUs}us');
      expect(meanUs, lessThan(50000), reason: 'Core startup initialization must be < 50ms');
    });

    test('Benchmark 2: Quran Page Retrieval & Search Latency', () async {
      // 1. Page data retrieval across pages 1..604
      final pageSw = Stopwatch()..start();
      for (var p = 1; p <= 604; p++) {
        final pageData = quran.getPageData(p);
        expect(pageData, isNotEmpty);
      }
      pageSw.stop();
      final totalPageMs = pageSw.elapsedMilliseconds;
      final avgPerPageUs = (pageSw.elapsedMicroseconds / 604).round();

      debugPrint('BENCHMARK_QURAN_PAGES: 604 pages total=${totalPageMs}ms, avg=${avgPerPageUs}us/page');
      expect(avgPerPageUs, lessThan(2000), reason: 'Average page indexing should be < 2ms');

      // 2. Quran Ayah Search Latency across search queries
      final searchQueries = ['الله', 'الرحمن', 'الصلاة', 'الجنة', 'الصبر'];
      final searchDurations = <String, int>{};

      for (final q in searchQueries) {
        final sw = Stopwatch()..start();
        final res = searchWords(q, limit: 50);
        sw.stop();
        final results = res['result'] as List? ?? [];
        expect(results, isNotEmpty, reason: 'Search for $q should yield matches');
        searchDurations[q] = sw.elapsedMilliseconds;
      }

      debugPrint('BENCHMARK_QURAN_SEARCH: ${jsonEncode(searchDurations)}');
      for (final entry in searchDurations.entries) {
        expect(entry.value, lessThan(250), reason: 'Query ${entry.key} search took ${entry.value}ms (> 250ms)');
      }
    });

    test('Benchmark 3: Offline Shamela Syllabus & Text Processing', () async {
      final sw = Stopwatch()..start();
      final book = MutunCurriculumCatalog.getBook('bk_usul_thalatha');
      sw.stop();
      expect(book, isNotNull);
      debugPrint('BENCHMARK_MUTUN_CATALOG: loaded usul thalatha with ${book!.sections.length} sections in ${sw.elapsedMicroseconds}us');

      // Paragraph splitting and token processing
      const classicalText = '''
بسم الله الرحمن الرحيم. الحمد لله رب العالمين والصلاة والسلام على نبينا محمد وعلى آله وصحبه أجمعين.
أما بعد: فهذه رسالة مختصرة في أصول الإيمان والعقيدة الإسلامية، تجب معرفتها على كل مكلف.
الأصل الأول: معرفة العبد ربه، ودينه، ونبيه محمداً صلى الله عليه وسلم.
فإذا قيل لك: من ربك؟ فقل: ربي الله الذي رباني وربى جميع العالمين بنعمه، وهو معبودي ليس لي معبود سواه.
''';

      final parseSw = Stopwatch()..start();
      const parseRuns = 100;
      for (var i = 0; i < parseRuns; i++) {
        final lines = classicalText.split('\n').where((l) => l.trim().isNotEmpty).toList();
        expect(lines.length, 4);
      }
      parseSw.stop();
      final avgParseUs = parseSw.elapsedMicroseconds ~/ parseRuns;
      debugPrint('BENCHMARK_MUTUN_TEXT_PARSE: avg=${avgParseUs}us over $parseRuns runs');
      expect(avgParseUs, lessThan(500), reason: 'Text parsing should be < 0.5ms');
    });

    test('Benchmark 4: Centralized Audio Coordinator Switching Latency', () async {
      const switches = 200;
      final sw = Stopwatch()..start();

      for (var i = 0; i < switches; i++) {
        final target = AudioStreamType.values[i % AudioStreamType.values.length];
        await AudioCoordinator.acquireFocus(target);
        expect(AudioCoordinator.currentActiveStream, target);
      }

      sw.stop();
      final totalUs = sw.elapsedMicroseconds;
      final avgUs = totalUs ~/ switches;
      debugPrint('BENCHMARK_AUDIO_SWITCH: total=${totalUs}us, avg=${avgUs}us/switch across $switches switches');
      expect(avgUs, lessThan(500), reason: 'Audio focus arbitration must take < 0.5ms');
    });

    test('Benchmark 5: Prayer Calculation & Algerian Wilayas Timetable Generation', () async {
      final prayerService = PrayerTimeService(now: () => DateTime(2026, 10, 24, 12, 0));
      final locationService = LocationService();
      final sampleCities = VerifiedCitiesCatalog.all.take(15).toList();

      final sw = Stopwatch()..start();
      final wilayaTimings = <String, int>{};

      for (final city in sampleCities) {
        final citySw = Stopwatch()..start();
        await locationService.setVerifiedCity(city);
        final day = await prayerService.getPrayerTimesDay(forceRefresh: true);
        citySw.stop();
        expect(day.prayers.length, 5);
        expect(day.city, city.name);
        wilayaTimings[city.name] = citySw.elapsedMicroseconds;
      }

      sw.stop();
      final totalMs = sw.elapsedMilliseconds;
      final avgCityUs = sw.elapsedMicroseconds ~/ sampleCities.length;

      debugPrint('BENCHMARK_PRAYER_WILAYAS: computed ${sampleCities.length} wilayas in ${totalMs}ms, avg=${avgCityUs}us/city');
      expect(avgCityUs, lessThan(10000), reason: 'City prayer calculation & pref sync must be < 10ms per city');
    });

    test('Benchmark 6: Prolonged Use Memory Footprint & Storage Retention Bounds', () async {
      final initialRss = ProcessInfo.currentRss;
      final statsService = ReadingStatsService(clock: () => DateTime(2026, 10, 24, 12, 0));

      // Simulate prolonged reading activity with 150 session recordings
      const sessionCount = 150;
      final sw = Stopwatch()..start();

      for (var i = 0; i < sessionCount; i++) {
        await statsService.recordSession(
          durationSeconds: 120 + (i % 60),
          versesRead: 10 + (i % 20),
          surahNumber: (i % 114) + 1,
        );
      }

      sw.stop();
      final streak = await statsService.getStreak();
      final daily = await statsService.getDailyStats();
      final afterRss = ProcessInfo.currentRss;
      final rssDeltaMb = (afterRss - initialRss) / (1024 * 1024);

      debugPrint('BENCHMARK_PROLONGED_MEMORY: initial=${(initialRss / (1024 * 1024)).toStringAsFixed(1)}MB, '
          'after=${(afterRss / (1024 * 1024)).toStringAsFixed(1)}MB, delta=${rssDeltaMb.toStringAsFixed(2)}MB, '
          'time=${sw.elapsedMilliseconds}ms for $sessionCount sessions');

      expect(streak, greaterThanOrEqualTo(1));
      expect(daily['minutes'], greaterThan(0));
      expect(rssDeltaMb, lessThan(50.0), reason: 'Prolonged session recording should not cause > 50MB RSS spike');
    });

    test('Benchmark 7: Background to Foreground Transition & State Refresh', () async {
      final locationService = LocationService();
      final algiers = VerifiedCitiesCatalog.search('الجزائر').first;
      await locationService.setVerifiedCity(algiers);

      var simulatedNow = DateTime(2026, 10, 24, 12, 0);
      var prayerService = PrayerTimeService(now: () => simulatedNow);

      // Foreground baseline
      final t1 = await prayerService.getPrayerTimesDay(forceRefresh: true);

      // Simulate app backgrounded for 6 hours
      simulatedNow = simulatedNow.add(const Duration(hours: 6));
      final resumeSw = Stopwatch()..start();

      // Foreground resume: clear cache and re-evaluate active state
      PrayerTimeService.clearCache();
      prayerService = PrayerTimeService(now: () => simulatedNow);
      final t2 = await prayerService.getPrayerTimesDay(forceRefresh: true);

      resumeSw.stop();
      expect(t1.nextPrayer, isNot(equals(t2.nextPrayer)));
      debugPrint('BENCHMARK_RESUME_REFRESH: resume and re-evaluation completed in ${resumeSw.elapsedMicroseconds}us');
      expect(resumeSw.elapsedMilliseconds, lessThan(20), reason: 'Resume state refresh must be < 20ms');
    });
  });
}
