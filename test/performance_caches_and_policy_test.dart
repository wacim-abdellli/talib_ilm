import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/constants/app_policy.dart';
import 'package:talib_ilm/features/quran/data/services/reading_stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T13 / C08, C25 — Core Policy & Retention Budgets', () {
    test('AppPolicy defines bounded domain timeouts and cache budgets', () {
      expect(AppPolicy.networkTimeout, const Duration(seconds: 15));
      expect(AppPolicy.networkMedium, const Duration(seconds: 20));
      expect(AppPolicy.networkLong, const Duration(seconds: 30));
      expect(AppPolicy.networkRetry, const Duration(seconds: 10));
      expect(AppPolicy.oneSecond, const Duration(seconds: 1));
      expect(AppPolicy.pollingActive, const Duration(seconds: 10));
      expect(AppPolicy.pollingStandard, const Duration(seconds: 30));
      expect(AppPolicy.seekStep, const Duration(seconds: 5));

      expect(AppPolicy.maxStoredReadingSessions, 500);
      expect(AppPolicy.maxReadingSessionAgeDays, 90);
      expect(AppPolicy.maxCachedDownloadedBooks, 1000);
    });
  });

  group('T13 / C08 — ReadingStatsService Budget & Clock Injection', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Injected clock enables deterministic streak calculation across dates', () async {
      DateTime simulatedTime = DateTime(2026, 10, 20, 14, 0);
      final service = ReadingStatsService(clock: () => simulatedTime);

      // Record on day 1 (Oct 20)
      await service.recordSession(durationSeconds: 300, versesRead: 20, surahNumber: 1);
      expect(await service.getStreak(), 1);

      // Advance to day 2 (Oct 21)
      simulatedTime = DateTime(2026, 10, 21, 15, 0);
      await service.recordSession(durationSeconds: 400, versesRead: 25, surahNumber: 2);
      expect(await service.getStreak(), 2);

      // Advance to day 3 (Oct 22)
      simulatedTime = DateTime(2026, 10, 22, 10, 0);
      await service.recordSession(durationSeconds: 200, versesRead: 15, surahNumber: 3);
      expect(await service.getStreak(), 3);

      // Skip a day to day 5 (Oct 24) -> streak broken
      simulatedTime = DateTime(2026, 10, 24, 12, 0);
      expect(await service.getStreak(), 0);
    });

    test('Prunes sessions older than 90 days to prevent unbounded storage growth', () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime(2026, 10, 23, 12, 0);

      // Seed 1 session from 120 days ago (older than 90 days), and 1 from 10 days ago
      final oldSession = jsonEncode({
        'timestamp': now.subtract(const Duration(days: 120)).millisecondsSinceEpoch,
        'duration': 600,
        'verses': 50,
        'surah': 2,
      });
      final recentSession = jsonEncode({
        'timestamp': now.subtract(const Duration(days: 10)).millisecondsSinceEpoch,
        'duration': 300,
        'verses': 20,
        'surah': 3,
      });

      await prefs.setStringList('quran_reading_sessions', [oldSession, recentSession]);

      final service = ReadingStatsService(clock: () => now);

      // Record a new session today
      await service.recordSession(durationSeconds: 180, versesRead: 10, surahNumber: 1);

      final stored = prefs.getStringList('quran_reading_sessions') ?? [];
      // The 120-day-old session must be pruned; only recent + today remain (2 total)
      expect(stored.length, 2);

      // Verify the old session timestamp is not in the list
      for (final s in stored) {
        final decoded = jsonDecode(s) as Map<String, dynamic>;
        final ts = decoded['timestamp'] as int;
        final date = DateTime.fromMillisecondsSinceEpoch(ts);
        expect(now.difference(date).inDays, lessThanOrEqualTo(AppPolicy.maxReadingSessionAgeDays));
      }
    });

    test('Enforces maxStoredReadingSessions (500) bound', () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime(2026, 10, 23, 12, 0);

      // Seed 520 sessions from the past 30 days
      final sessions = List.generate(
        520,
        (i) => jsonEncode({
          'timestamp': now.subtract(Duration(hours: 520 - i)).millisecondsSinceEpoch,
          'duration': 60,
          'verses': 5,
          'surah': 1,
        }),
      );
      await prefs.setStringList('quran_reading_sessions', sessions);

      final service = ReadingStatsService(clock: () => now);
      await service.recordSession(durationSeconds: 120, versesRead: 10, surahNumber: 1);

      final stored = prefs.getStringList('quran_reading_sessions') ?? [];
      expect(stored.length, lessThanOrEqualTo(AppPolicy.maxStoredReadingSessions));
      expect(stored.length, equals(AppPolicy.maxStoredReadingSessions));
    });
  });
}
