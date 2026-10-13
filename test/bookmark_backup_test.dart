import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/quran/data/services/bookmark_backup_service.dart';
import 'package:talib_ilm/features/quran/data/services/bookmark_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('BookmarkBackupService Tests', () {
    test('createBackupJson generates valid payload with app signature and version', () async {
      await BookmarkService.addBookmark(2, 255, note: 'آية الكرسي');

      final jsonStr = await BookmarkBackupService.createBackupJson();
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;

      expect(decoded['app'], equals('talib_ilm'));
      expect(decoded['version'], equals(1));
      expect(decoded['bookmarks'], isA<List>());
      expect((decoded['bookmarks'] as List).length, equals(1));
      expect(decoded['bookmarks'][0]['surah'], equals(2));
      expect(decoded['bookmarks'][0]['ayah'], equals(255));
      expect(decoded['bookmarks'][0]['note'], equals('آية الكرسي'));
    });

    test('validateAndParse succeeds on authentic payload', () {
      final validJson = json.encode({
        'app': 'talib_ilm',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'bookmarks': [
          {'surah': 1, 'ayah': 1, 'page': 1, 'note': 'الفاتحة'},
          {'surah': 114, 'ayah': 6, 'page': 604, 'note': 'الناس'},
        ],
        'lastRead': {'surah': 1, 'ayah': 1, 'page': 1},
      });

      final result = BookmarkBackupService.validateAndParse(validJson);
      expect(result.isValid, isTrue);
      expect(result.version, equals(1));
      expect(result.bookmarks.length, equals(2));
      expect(result.bookmarks[0].surah, equals(1));
      expect(result.lastRead?.surah, equals(1));
    });

    test('validateAndParse rejects corrupted or malformed JSON', () {
      final result1 = BookmarkBackupService.validateAndParse('');
      expect(result1.isValid, isFalse);
      expect(result1.errorMessage, contains('فارغ'));

      final result2 = BookmarkBackupService.validateAndParse('{invalid_json,');
      expect(result2.isValid, isFalse);
      expect(result2.errorMessage, contains('تالف'));
    });

    test('validateAndParse rejects mismatched app signature and missing/future version', () {
      final wrongApp = json.encode({
        'app': 'another_app',
        'version': 1,
        'bookmarks': [],
      });
      final resWrongApp = BookmarkBackupService.validateAndParse(wrongApp);
      expect(resWrongApp.isValid, isFalse);
      expect(resWrongApp.errorMessage, contains('لا ينتمي لتطبيق طالب علم'));

      final futureVer = json.encode({
        'app': 'talib_ilm',
        'version': 99,
        'bookmarks': [],
      });
      final resFutureVer = BookmarkBackupService.validateAndParse(futureVer);
      expect(resFutureVer.isValid, isFalse);
      expect(resFutureVer.errorMessage, contains('غير مدعوم'));
    });

    test('mergeBookmarks merges without duplicates and respects overwriteExistingNotes', () async {
      await BookmarkService.addBookmark(1, 1, note: 'ملاحظة محلية سابقة');

      final imported = [
        Bookmark(
          surah: 1,
          ayah: 1,
          page: 1,
          note: 'ملاحظة جديدة مستوردة',
          timestamp: DateTime.now(),
        ),
        Bookmark(
          surah: 2,
          ayah: 1,
          page: 2,
          note: 'البقرة آية 1',
          timestamp: DateTime.now(),
        ),
      ];

      // 1. Merge with overwrite = false
      final merge1 = await BookmarkBackupService.mergeBookmarks(
        importedBookmarks: imported,
        overwriteExistingNotes: false,
      );

      expect(merge1.addedCount, equals(1)); // Surah 2:1 is new
      expect(merge1.skippedCount, equals(1)); // Surah 1:1 skipped
      expect(merge1.updatedCount, equals(0));

      final current1 = await BookmarkService.getBookmarks();
      expect(current1.length, equals(2));
      final item1 = current1.firstWhere((b) => b.surah == 1 && b.ayah == 1);
      expect(item1.note, equals('ملاحظة محلية سابقة')); // Kept original

      // 2. Merge with overwrite = true (now both 1:1 and 2:1 exist, so both get updated)
      final merge2 = await BookmarkBackupService.mergeBookmarks(
        importedBookmarks: imported,
        overwriteExistingNotes: true,
      );

      expect(merge2.updatedCount, equals(2)); // Both existing items updated
      expect(merge2.addedCount, equals(0));
      expect(merge2.skippedCount, equals(0));

      final current2 = await BookmarkService.getBookmarks();
      final item2 = current2.firstWhere((b) => b.surah == 1 && b.ayah == 1);
      expect(item2.note, equals('ملاحظة جديدة مستوردة')); // Overwritten
    });
  });
}
