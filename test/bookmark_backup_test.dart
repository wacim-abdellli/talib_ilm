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
      expect(current2.length, equals(2));
      final item2 = current2.firstWhere((b) => b.surah == 1 && b.ayah == 1);
      expect(item2.note, equals('ملاحظة جديدة مستوردة')); // Overwritten
    });

    test('UTF-8 preserves Arabic text, diacritics, and notes without corruption (C03)', () {
      const arabicSample = 'قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ - مَلِكِ ٱلنَّاسِ (ملاحظة إيمانية شاملة)';
      final bytes = utf8.encode(arabicSample);

      // Verify that utf8.decode restores the exact string byte-for-byte
      final restored = utf8.decode(bytes, allowMalformed: false);
      expect(restored, equals(arabicSample));

      // Malformed UTF-8 must fail cleanly with FormatException
      final invalidBytes = [0xC0, 0xAF, 0xFF];
      expect(
        () => utf8.decode(invalidBytes, allowMalformed: false),
        throwsA(isA<FormatException>()),
      );
    });

    test('validateAndParse safely handles non-string app and invalid types without TypeError (C04)', () {
      // app is an integer (e.g. 42)
      final numericAppJson = json.encode({
        'app': 42,
        'version': 1,
        'bookmarks': [
          {'surah': 1, 'ayah': 1, 'page': 1},
        ],
      });
      final resNumApp = BookmarkBackupService.validateAndParse(numericAppJson);
      expect(resNumApp.isValid, isFalse);
      expect(resNumApp.errorMessage, contains('لا ينتمي لتطبيق طالب علم'));

      // app is boolean
      final boolAppJson = json.encode({
        'app': true,
        'version': 1,
        'bookmarks': [],
      });
      final resBoolApp = BookmarkBackupService.validateAndParse(boolAppJson);
      expect(resBoolApp.isValid, isFalse);
      expect(resBoolApp.errorMessage, contains('لا ينتمي لتطبيق طالب علم'));

      // version is a string instead of an int
      final strVerJson = json.encode({
        'app': 'talib_ilm',
        'version': '1',
        'bookmarks': [
          {'surah': 1, 'ayah': 1, 'page': 1},
        ],
      });
      final resStrVer = BookmarkBackupService.validateAndParse(strVerJson);
      expect(resStrVer.isValid, isFalse);
      expect(resStrVer.errorMessage, contains('رقم إصدار'));

      // top-level is a JSON list instead of a JSON object
      final listJson = json.encode([1, 2, 3]);
      final resList = BookmarkBackupService.validateAndParse(listJson);
      expect(resList.isValid, isFalse);
      expect(resList.errorMessage, contains('بنية البيانات في الملف غير صالحة'));
    });

    test('Coordinate validation strictly enforces Quran bounds (C05)', () {
      // Valid coordinates
      expect(Bookmark.isValidCoordinates(1, 1), isTrue);
      expect(Bookmark.isValidCoordinates(1, 7), isTrue);
      expect(Bookmark.isValidCoordinates(114, 6), isTrue);

      // Out of bounds: surah
      expect(Bookmark.isValidCoordinates(0, 1), isFalse);
      expect(Bookmark.isValidCoordinates(115, 1), isFalse);
      expect(Bookmark.isValidCoordinates(999, 1), isFalse);

      // Out of bounds: ayah (Surah 1 has 7 verses, Surah 114 has 6 verses)
      expect(Bookmark.isValidCoordinates(1, 0), isFalse);
      expect(Bookmark.isValidCoordinates(1, 8), isFalse);
      expect(Bookmark.isValidCoordinates(114, 7), isFalse);

      // Out of bounds: page
      expect(Bookmark.isValidCoordinates(1, 1, 0), isFalse);
      expect(Bookmark.isValidCoordinates(1, 1, 605), isFalse);
      expect(Bookmark.isValidCoordinates(1, 1, 300), isTrue);

      // Bookmark.fromJson throws FormatException on invalid coordinates
      expect(
        () => Bookmark.fromJson({'surah': 999, 'ayah': 1}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => Bookmark.fromJson({'surah': 1, 'ayah': 50}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => LastRead.fromJson({'surah': 0, 'ayah': 1}),
        throwsA(isA<FormatException>()),
      );

      // BookmarkService enforces bounds on addBookmark and saveLastRead
      expect(
        () => BookmarkService.addBookmark(999, 1),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => BookmarkService.saveLastRead(surah: 1, ayah: 99),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validateAndParse filters corrupted coordinates and rejects empty result (C05)', () {
      // Backup with 1 valid and 2 corrupted entries
      final mixedJson = json.encode({
        'app': 'talib_ilm',
        'version': 1,
        'bookmarks': [
          {'surah': 1, 'ayah': 1, 'page': 1, 'note': 'صالح'},
          {'surah': 999, 'ayah': 1, 'page': 1, 'note': 'سورة وهمية'},
          {'surah': 1, 'ayah': 500, 'page': 1, 'note': 'آية وهمية'},
        ],
      });

      final mixedResult = BookmarkBackupService.validateAndParse(mixedJson);
      expect(mixedResult.isValid, isTrue);
      expect(mixedResult.bookmarks.length, equals(1));
      expect(mixedResult.bookmarks.first.surah, equals(1));
      expect(mixedResult.bookmarks.first.ayah, equals(1));

      // Backup with ONLY corrupted entries and no lastRead
      final allCorruptJson = json.encode({
        'app': 'talib_ilm',
        'version': 1,
        'bookmarks': [
          {'surah': 999, 'ayah': 1},
        ],
      });

      final allCorruptResult = BookmarkBackupService.validateAndParse(allCorruptJson);
      expect(allCorruptResult.isValid, isFalse);
      expect(allCorruptResult.errorMessage, contains('لا توجد أي بيانات صالحة'));
    });
  });
}
