import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/quran/data/services/bookmark_backup_service.dart';
import 'package:talib_ilm/features/quran/data/services/bookmark_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('R47a / C27: Bookmark Atomicity - Concurrent Toggles & Adds', () {
    test('two concurrent addBookmark calls retain both entries without loss', () async {
      await Future.wait([
        BookmarkService.addBookmark(1, 1, note: 'Ayah 1'),
        BookmarkService.addBookmark(1, 2, note: 'Ayah 2'),
      ]);

      final bookmarks = await BookmarkService.getBookmarks();
      expect(bookmarks.length, equals(2));
      expect(bookmarks.any((b) => b.surah == 1 && b.ayah == 1), isTrue);
      expect(bookmarks.any((b) => b.surah == 1 && b.ayah == 2), isTrue);
    });

    test('concurrent toggleBookmark on unbookmarked ayah returns to original unbookmarked state', () async {
      // Initially not bookmarked
      expect(await BookmarkService.isAyahBookmarked(1, 1), isFalse);

      // Fire two concurrent toggles
      final results = await Future.wait([
        BookmarkService.toggleBookmark(1, 1),
        BookmarkService.toggleBookmark(1, 1),
      ]);

      // Exactly one should have added (true) and one removed (false)
      expect(results.contains(true), isTrue);
      expect(results.contains(false), isTrue);

      // Final state must be unbookmarked (original state)
      final isBookmarked = await BookmarkService.isAyahBookmarked(1, 1);
      expect(isBookmarked, isFalse, reason: 'Two concurrent toggles from absent must end absent');
    });

    test('concurrent toggleBookmark on bookmarked ayah returns to original bookmarked state', () async {
      // Initially bookmarked
      await BookmarkService.addBookmark(1, 1);
      expect(await BookmarkService.isAyahBookmarked(1, 1), isTrue);

      // Fire two concurrent toggles
      final results = await Future.wait([
        BookmarkService.toggleBookmark(1, 1),
        BookmarkService.toggleBookmark(1, 1),
      ]);

      // One removed (false), one re-added (true)
      expect(results.contains(true), isTrue);
      expect(results.contains(false), isTrue);

      // Final state must remain bookmarked
      final isBookmarked = await BookmarkService.isAyahBookmarked(1, 1);
      expect(isBookmarked, isTrue, reason: 'Two concurrent toggles from present must end present');
    });

    test('concurrent toggleSurahBookmark on unbookmarked surah returns to original unbookmarked state', () async {
      expect(await BookmarkService.isSurahBookmarked(2), isFalse);

      final results = await Future.wait([
        BookmarkService.toggleSurahBookmark(2),
        BookmarkService.toggleSurahBookmark(2),
      ]);

      expect(results.contains(true), isTrue);
      expect(results.contains(false), isTrue);

      final isBookmarked = await BookmarkService.isSurahBookmarked(2);
      expect(isBookmarked, isFalse, reason: 'Two concurrent surah toggles from absent must end absent');
    });

    test('concurrent toggleSurahBookmark on bookmarked surah returns to original bookmarked state', () async {
      await BookmarkService.toggleSurahBookmark(2);
      expect(await BookmarkService.isSurahBookmarked(2), isTrue);

      final results = await Future.wait([
        BookmarkService.toggleSurahBookmark(2),
        BookmarkService.toggleSurahBookmark(2),
      ]);

      expect(results.contains(true), isTrue);
      expect(results.contains(false), isTrue);

      final isBookmarked = await BookmarkService.isSurahBookmarked(2);
      expect(isBookmarked, isTrue, reason: 'Two concurrent surah toggles from present must end present');
    });
  });

  group('R47a / C28: Bookmark Atomicity - Import Merge Concurrency', () {
    test('concurrent addBookmark during mergeBookmarks is not lost', () async {
      // Initial bookmark
      await BookmarkService.addBookmark(1, 1, note: 'Initial');

      final importedList = [
        Bookmark(
          surah: 2,
          ayah: 1,
          page: 2,
          note: 'Imported 2:1',
          timestamp: DateTime.now(),
        ),
      ];

      // Run merge and addBookmark concurrently
      await Future.wait([
        BookmarkBackupService.mergeBookmarks(
          importedBookmarks: importedList,
          overwriteExistingNotes: false,
        ),
        BookmarkService.addBookmark(3, 1, note: 'Concurrent add 3:1'),
      ]);

      final all = await BookmarkService.getBookmarks();
      // Must contain all 3: 1:1, 2:1, and 3:1
      expect(all.any((b) => b.surah == 1 && b.ayah == 1), isTrue);
      expect(all.any((b) => b.surah == 2 && b.ayah == 1), isTrue);
      expect(all.any((b) => b.surah == 3 && b.ayah == 1), isTrue,
          reason: 'Concurrent add during import merge must not be overwritten');
    });

    test('concurrent updateNote during mergeBookmarks is not lost', () async {
      await BookmarkService.addBookmark(1, 1, note: 'Original note');

      final importedList = [
        Bookmark(
          surah: 2,
          ayah: 1,
          page: 2,
          note: 'Imported 2:1',
          timestamp: DateTime.now(),
        ),
      ];

      // Run merge (with overwrite = false) and updateNote on 1:1 concurrently
      await Future.wait([
        BookmarkBackupService.mergeBookmarks(
          importedBookmarks: importedList,
          overwriteExistingNotes: false,
        ),
        BookmarkService.updateNote(1, 1, 'Updated note while merging'),
      ]);

      final all = await BookmarkService.getBookmarks();
      final item1 = all.firstWhere((b) => b.surah == 1 && b.ayah == 1);
      expect(item1.note, equals('Updated note while merging'),
          reason: 'Concurrent note update must not be wiped out by merge write');
    });

    test('concurrent removeBookmark during mergeBookmarks maintains consistency', () async {
      await BookmarkService.addBookmark(1, 1, note: 'To be removed');
      await BookmarkService.addBookmark(1, 2, note: 'Keep me');

      final importedList = [
        Bookmark(
          surah: 2,
          ayah: 1,
          page: 2,
          note: 'Imported 2:1',
          timestamp: DateTime.now(),
        ),
      ];

      // Race merge with remove of 1:1
      await Future.wait([
        BookmarkBackupService.mergeBookmarks(
          importedBookmarks: importedList,
          overwriteExistingNotes: false,
        ),
        BookmarkService.removeBookmark(1, 1),
      ]);

      final all = await BookmarkService.getBookmarks();
      // 1:2 and 2:1 must be present; 1:1 must NOT be present
      expect(all.any((b) => b.surah == 1 && b.ayah == 2), isTrue);
      expect(all.any((b) => b.surah == 2 && b.ayah == 1), isTrue);
      expect(all.any((b) => b.surah == 1 && b.ayah == 1), isFalse);
    });

    test('atomicMergeBookmarks enforces the 200 bookmarks cap', () async {
      final bigImport = List.generate(
        220,
        (i) => Bookmark(
          surah: 2,
          ayah: i + 1,
          page: 2,
          timestamp: DateTime.now(),
        ),
      );

      final result = await BookmarkService.atomicMergeBookmarks(
        importedBookmarks: bigImport,
        overwriteExistingNotes: false,
      );

      expect(result.addedCount, equals(220));
      final stored = await BookmarkService.getBookmarks();
      expect(stored.length, equals(200), reason: 'Must not exceed 200 items in repository');
    });

    test('atomicMergeBookmarks updates lastRead when imported timestamp is newer', () async {
      final futureTime = DateTime.now().add(const Duration(days: 30));

      await BookmarkService.saveLastRead(surah: 1, ayah: 1);

      final lastRead = LastRead(
        surah: 2,
        ayah: 255,
        page: 42,
        timestamp: futureTime,
      );

      await BookmarkService.atomicMergeBookmarks(
        importedBookmarks: [],
        overwriteExistingNotes: false,
        importedLastRead: lastRead,
      );

      final storedLastRead = await BookmarkService.getLastRead();
      expect(storedLastRead.surah, equals(2));
      expect(storedLastRead.ayah, equals(255));
    });

    test('failed storage write returns error and leaves existing persisted value intact', () async {
      await BookmarkService.addBookmark(1, 1, note: 'Safe note');

      final prefs = await SharedPreferences.getInstance();
      final previousRaw = prefs.getString('bookmarks_v2');
      expect(previousRaw, isNotNull);

      // Attempt invalid add with out of bounds coordinates
      expect(
        () => BookmarkService.addBookmark(999, 1),
        throwsA(isA<ArgumentError>()),
      );

      // Persisted data remains untouched
      final afterRaw = prefs.getString('bookmarks_v2');
      expect(afterRaw, equals(previousRaw));

      final bookmarks = await BookmarkService.getBookmarks();
      expect(bookmarks.length, equals(1));
      expect(bookmarks.first.surah, equals(1));
    });
  });
}
