import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/models/favorite_item.dart';
import 'package:talib_ilm/core/services/adhan_settings_service.dart';
import 'package:talib_ilm/core/services/favorites_service.dart';
import 'package:talib_ilm/core/services/progress_service.dart';
import 'package:talib_ilm/core/services/user_day_tracker.dart';
import 'package:talib_ilm/features/ilm/data/models/progress_models.dart';
import 'package:talib_ilm/features/quran/data/services/bookmark_service.dart';
import 'package:talib_ilm/features/quran/data/services/quran_reader_preferences.dart';
import 'package:talib_ilm/features/quran/data/services/reading_stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ReadingStatsService.resetCacheForTesting();
    BookmarkService.resetCacheForTesting();
    ProgressService.resetCacheForTesting();
    FavoritesService.resetCacheForTesting();
    AdhanSettingsService.resetCacheForTesting();
    UserDayTracker.resetCacheForTesting();
    QuranReaderPreferences.resetCacheForTesting();
  });

  group('R94 / Area F: Performance Profiling & SharedPreferences I/O Batching', () {
    test('ReadingStatsService in-memory memoization and DST streak calculation', () async {
      final baseDate = DateTime(2026, 10, 26, 14, 0);
      final statsService = ReadingStatsService(clock: () => baseDate);

      // Record a valid session
      await statsService.recordSession(
        durationSeconds: 180,
        versesRead: 25,
        surahNumber: 1,
      );

      final daily = await statsService.getDailyStats();
      expect(daily['minutes'], 3);
      expect(daily['verses'], 25);

      final streak = await statsService.getStreak();
      expect(streak, 1);

      // Simulate multi-day reading streak across DST transition boundary
      // Day 1: Oct 24, Day 2: Oct 25 (DST change), Day 3: Oct 26
      final multiDayService = ReadingStatsService(clock: () => DateTime(2026, 10, 26, 12, 0));
      final prefs = await SharedPreferences.getInstance();

      final sessions = [
        jsonEncode({
          'timestamp': DateTime(2026, 10, 24, 10, 0).millisecondsSinceEpoch,
          'duration': 300,
          'verses': 20,
          'surah': 2,
        }),
        jsonEncode({
          'timestamp': DateTime(2026, 10, 25, 10, 0).millisecondsSinceEpoch,
          'duration': 300,
          'verses': 20,
          'surah': 2,
        }),
        jsonEncode({
          'timestamp': DateTime(2026, 10, 26, 10, 0).millisecondsSinceEpoch,
          'duration': 300,
          'verses': 20,
          'surah': 2,
        }),
      ];
      await prefs.setStringList('quran_reading_sessions', sessions);
      ReadingStatsService.resetCacheForTesting();

      final multiStreak = await multiDayService.getStreak();
      expect(multiStreak, 3);
    });

    test('BookmarkService raw string comparison guard and fast cache retrieval', () async {
      await BookmarkService.addBookmark(1, 1, note: 'الفاتحة');
      await BookmarkService.addBookmark(2, 255, note: 'آية الكرسي');

      // First read loads from prefs and caches in memory
      final b1 = await BookmarkService.getBookmarks();
      expect(b1.length, 2);

      // Subsequent read hits in-memory cache directly
      final b2 = await BookmarkService.getBookmarks();
      expect(b2.length, 2);
      expect(b2.first.surah, 2);

      // Mutate bookmark -> updates cache synchronously
      await BookmarkService.removeBookmark(1, 1);
      final b3 = await BookmarkService.getBookmarks();
      expect(b3.length, 1);
      expect(b3.first.surah, 2);
    });

    test('ProgressService in-memory memoization and O(1) book lookup', () async {
      final progressService = ProgressService();
      final p1 = BookProgress(
        bookId: 'book_nahw',
        status: BookProgressStatus.inProgress,
        completedLessons: 12,
        totalLessons: 100,
      );

      await progressService.saveProgress(p1);

      // O(1) in-memory lookup
      final loaded = await progressService.getProgress('book_nahw');
      expect(loaded, isNotNull);
      expect(loaded!.completedLessons, 12);
      expect(loaded.totalLessons, 100);
      expect(loaded.status, BookProgressStatus.inProgress);

      // All progress list
      final all = await progressService.getAllProgress();
      expect(all.length, 1);
      expect(all.first.bookId, 'book_nahw');
    });

    test('FavoritesService memoization and toggle consistency', () async {
      final favService = FavoritesService();
      const item = FavoriteItem(
        id: 'hadith_40_1',
        title: 'إنما الأعمال بالنيات',
        type: FavoriteType.hadith,
        subtitle: 'الأربعون النووية',
      );

      expect(await favService.isFavorite(FavoriteType.hadith, 'hadith_40_1'), isFalse);

      final added = await favService.toggle(item);
      expect(added, isTrue);
      expect(await favService.isFavorite(FavoriteType.hadith, 'hadith_40_1'), isTrue);

      final ids = await favService.getIdsByType(FavoriteType.hadith);
      expect(ids.contains('hadith_40_1'), isTrue);

      final removed = await favService.toggle(item);
      expect(removed, isFalse);
      expect(await favService.isFavorite(FavoriteType.hadith, 'hadith_40_1'), isFalse);
    });

    test('AdhanSettingsService in-memory cache and persistence', () async {
      final adhanService = AdhanSettingsService();
      final initial = await adhanService.getSettings();
      expect(initial.enabled, isTrue);

      final updated = initial.copyWith(
        enabled: true,
        volume: 95.0,
        madhab: 'hanafi',
        sound: AdhanSound.alafasy,
      );

      await adhanService.saveSettings(updated);

      // In-memory instant read
      final cached = await adhanService.getSettings();
      expect(cached.volume, 95.0);
      expect(cached.madhab, 'hanafi');
      expect(cached.sound, AdhanSound.alafasy);

      // Force refresh read from prefs
      final fresh = await adhanService.getSettings(forceRefresh: true);
      expect(fresh.volume, 95.0);
      expect(fresh.madhab, 'hanafi');
      expect(fresh.sound, AdhanSound.alafasy);
    });

    test('UserDayTracker in-memory state and stale key pruning', () async {
      final tracker = UserDayTracker();

      expect(await tracker.hasActedToday(), isFalse);
      await tracker.recordQuranOpened();

      // In-memory query
      expect(await tracker.hasActedToday(), isTrue);
      expect(await tracker.openedQuranToday(), isTrue);
      expect(await tracker.getLastAction(), 'quran');

      // Test stale key pruning (> 30 days)
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime(2026, 10, 26);

      // Plant 2 stale keys (45 days old) and 1 fresh key (5 days old)
      await prefs.setBool('user_day_2026-09-10_opened_quran', true);
      await prefs.setBool('user_day_2026-09-10_opened_adhkar', true);
      await prefs.setBool('user_day_2026-10-21_opened_quran', true);

      final pruned = await UserDayTracker.pruneStaleKeys(prefs, now: now, retentionDays: 30);
      expect(pruned, 2);

      // Check stale keys are deleted
      expect(prefs.containsKey('user_day_2026-09-10_opened_quran'), isFalse);
      expect(prefs.containsKey('user_day_2026-09-10_opened_adhkar'), isFalse);

      // Check fresh key is preserved
      expect(prefs.containsKey('user_day_2026-10-21_opened_quran'), isTrue);
    });

    test('QuranReaderPreferences snapshot caching and copyWith synchronization', () async {
      final initial = await QuranReaderPreferences.load();
      expect(initial.isTajweedEnabled, isTrue);

      // Modify tajweed setting
      await QuranReaderPreferences.saveTajweedEnabled(false);

      // In-memory cached snapshot updated
      final updated = await QuranReaderPreferences.load();
      expect(updated.isTajweedEnabled, isFalse);

      // Modify font size
      await QuranReaderPreferences.saveFontSize(28.0);
      final sizeUpdated = await QuranReaderPreferences.load();
      expect(sizeUpdated.fontSize, 28.0);
      expect(sizeUpdated.isTajweedEnabled, isFalse);
    });
  });
}
