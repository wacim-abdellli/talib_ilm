import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/services/progress_service.dart';
import 'package:talib_ilm/features/ilm/data/models/book_progress_model.dart';
import 'package:talib_ilm/features/ilm/data/models/progress_models.dart' as legacy;
import 'package:talib_ilm/features/ilm/data/services/book_progress_service.dart';
import 'package:talib_ilm/features/quran/data/services/bookmark_service.dart';
import 'package:talib_ilm/features/quran/data/services/reading_stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('T03 - Batch A: BookmarkService Concurrency & Recovery (C06)', () {
    test('concurrent addBookmark calls via Future.wait retain all entries without loss', () async {
      await Future.wait([
        BookmarkService.addBookmark(1, 1),
        BookmarkService.addBookmark(2, 1),
        BookmarkService.addBookmark(3, 1),
      ]);

      final bookmarks = await BookmarkService.getBookmarks();
      expect(bookmarks.length, equals(3));
      expect(bookmarks.any((b) => b.surah == 1 && b.ayah == 1), isTrue);
      expect(bookmarks.any((b) => b.surah == 2 && b.ayah == 1), isTrue);
      expect(bookmarks.any((b) => b.surah == 3 && b.ayah == 1), isTrue);
    });

    test('recovers valid bookmarks when corrupted entries exist in storage', () async {
      final prefs = await SharedPreferences.getInstance();
      final corruptedJson = jsonEncode([
        {'surah': 1, 'ayah': 1, 'page': 1},
        {'surah': 'corrupted_string', 'ayah': -5},
        {'surah': 999, 'ayah': 1}, // invalid surah
        {'surah': 114, 'ayah': 1, 'page': 604},
      ]);
      await prefs.setString('bookmarks_v2', corruptedJson);

      final bookmarks = await BookmarkService.getBookmarks();
      expect(bookmarks.length, equals(2));
      expect(bookmarks[0].surah, equals(1));
      expect(bookmarks[1].surah, equals(114));
    });

    test('concurrent saveLastRead calls serialize cleanly', () async {
      await Future.wait([
        BookmarkService.saveLastRead(surah: 1, ayah: 1),
        BookmarkService.saveLastRead(surah: 2, ayah: 5),
      ]);

      final lastRead = await BookmarkService.getLastRead();
      expect(lastRead.surah, isIn([1, 2]));
    });
  });

  group('T03 - Batch B: ProgressService & BookProgressService Recovery (C07)', () {
    test('ProgressService survives malformed JSON and recovers valid entries', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('book_progress', '{malformed_json:');

      final service = ProgressService();
      // Should not throw FormatException
      final all = await service.getAllProgress();
      expect(all, isEmpty);

      final single = await service.getProgress('bk_1');
      expect(single, isNull);

      // Now with one valid and one corrupted book entry
      final mixedJson = jsonEncode({
        'bk_valid': {
          'bookId': 'bk_valid',
          'currentPage': 10,
          'totalPages': 100,
          'lastRead': DateTime.now().toIso8601String(),
        },
        'bk_corrupt': 'not_a_map',
      });
      await prefs.setString('book_progress', mixedJson);

      final recovered = await service.getAllProgress();
      expect(recovered.length, equals(1));
      expect(recovered.first.bookId, equals('bk_valid'));
    });

    test('ProgressService concurrent saveProgress retains all books', () async {
      final service = ProgressService();
      final b1 = legacy.BookProgress(
        bookId: 'bk_1',
        status: legacy.BookProgressStatus.inProgress,
        completedLessons: 5,
        totalLessons: 50,
      );
      final b2 = legacy.BookProgress(
        bookId: 'bk_2',
        status: legacy.BookProgressStatus.completed,
        completedLessons: 60,
        totalLessons: 60,
      );

      await Future.wait([
        service.saveProgress(b1),
        service.saveProgress(b2),
      ]);

      final all = await service.getAllProgress();
      expect(all.length, equals(2));
      expect(all.any((b) => b.bookId == 'bk_1'), isTrue);
      expect(all.any((b) => b.bookId == 'bk_2'), isTrue);
    });

    test('BookProgressService survives corrupted JSON and retains valid books', () async {
      final prefs = await SharedPreferences.getInstance();
      final corruptedJson = jsonEncode([
        {
          'bookId': 'bk_adhkar_adab',
          'bookTitle': 'الآداب والأذكار',
          'level': '1',
          'totalPages': 60,
          'currentPage': 10,
          'lastReadDate': DateTime.now().toIso8601String(),
          'startedDate': DateTime.now().toIso8601String(),
        },
        {'invalid': 'entry_missing_keys'},
      ]);
      await prefs.setString('book_progress_data', corruptedJson);

      final service = BookProgressService(prefs);
      final all = await service.getAllProgress();
      expect(all.length, equals(1));
      expect(all.first.bookId, equals('bk_adhkar_adab'));
    });

    test('BookProgressService concurrent saveBookProgress preserves all items', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = BookProgressService(prefs);

      final p1 = BookProgress(
        bookId: 'bk_1',
        bookTitle: 'كتاب 1',
        level: '1',
        totalPages: 50,
        currentPage: 5,
        lastReadDate: DateTime.now(),
        startedDate: DateTime.now(),
      );
      final p2 = BookProgress(
        bookId: 'bk_2',
        bookTitle: 'كتاب 2',
        level: '1',
        totalPages: 80,
        currentPage: 10,
        lastReadDate: DateTime.now(),
        startedDate: DateTime.now(),
      );

      await Future.wait([
        service.saveBookProgress(p1),
        service.saveBookProgress(p2),
      ]);

      final all = await service.getAllProgress();
      expect(all.length, equals(2));
      expect(all.any((b) => b.bookId == 'bk_1'), isTrue);
      expect(all.any((b) => b.bookId == 'bk_2'), isTrue);
    });
  });

  group('T03 - Batch C: ReadingStatsService Recovery & Bounds (C08)', () {
    test('getDailyStats and getStreak do not throw when malformed sessions exist', () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final validSessionToday = jsonEncode({
        'timestamp': now.millisecondsSinceEpoch,
        'duration': 120, // 2 mins
        'verses': 10,
        'surah': 1,
      });

      final sessions = [
        validSessionToday,
        'malformed_json_string{',
        jsonEncode({'timestamp': 'not_an_int'}),
        jsonEncode({'timestamp': now.millisecondsSinceEpoch, 'duration': null, 'verses': 'invalid'}),
      ];
      await prefs.setStringList('quran_reading_sessions', sessions);

      final statsService = ReadingStatsService();
      final dailyStats = await statsService.getDailyStats();
      expect(dailyStats['minutes'], equals(2));
      expect(dailyStats['verses'], equals(10));

      final streak = await statsService.getStreak();
      expect(streak, equals(1));
    });

    test('recordSession bounds storage to 500 recent sessions', () async {
      final statsService = ReadingStatsService();
      final prefs = await SharedPreferences.getInstance();

      // Preload 505 sessions
      final List<String> oldSessions = List.generate(
        505,
        (i) => jsonEncode({
          'timestamp': DateTime.now().subtract(Duration(days: i + 1)).millisecondsSinceEpoch,
          'duration': 60,
          'verses': 5,
          'surah': 1,
        }),
      );
      await prefs.setStringList('quran_reading_sessions', oldSessions);

      // Record a new session
      await statsService.recordSession(
        durationSeconds: 120,
        versesRead: 10,
        surahNumber: 2,
      );

      final stored = prefs.getStringList('quran_reading_sessions')!;
      expect(stored.length, lessThanOrEqualTo(500));
    });

    test('concurrent recordSession calls do not overwrite each other', () async {
      final statsService = ReadingStatsService();
      await Future.wait([
        statsService.recordSession(durationSeconds: 30, versesRead: 5, surahNumber: 1),
        statsService.recordSession(durationSeconds: 45, versesRead: 8, surahNumber: 2),
        statsService.recordSession(durationSeconds: 60, versesRead: 12, surahNumber: 3),
      ]);

      final daily = await statsService.getDailyStats();
      expect(daily['verses'], equals(25)); // 5 + 8 + 12
    });
  });
}
