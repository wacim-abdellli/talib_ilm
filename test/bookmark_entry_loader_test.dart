import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/ilm/data/services/book_progress_service.dart';
import 'package:talib_ilm/features/ilm/data/services/bookmark_entry_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BookmarkEntryLoader & Title Healing Tests', () {
    test('BookmarkEntryLoader resolves raw bk_qawaid_arba to Arabic canonical title', () {
      final resolved = BookmarkEntryLoader.resolveBookTitle(
        bookId: 'bk_qawaid_arba',
        storedTitle: 'bk_qawaid_arba',
        bookById: const {},
      );

      expect(resolved, equals('القواعد الأربع'));
    });

    test('BookmarkEntryLoader resolves raw bk_usul_thalatha to Arabic canonical title', () {
      final resolved = BookmarkEntryLoader.resolveBookTitle(
        bookId: 'bk_usul_thalatha',
        storedTitle: '',
        bookById: const {},
      );

      expect(resolved, contains('الأصول'));
    });

    test('BookProgressService automatically heals stored raw book titles on getAllProgress', () async {
      SharedPreferences.setMockInitialValues({
        'book_progress_data': json.encode([
          {
            'bookId': 'bk_qawaid_arba',
            'bookTitle': 'bk_qawaid_arba',
            'level': 'المستوى الأول',
            'totalPages': 8,
            'currentPage': 1,
            'lastReadDate': DateTime.now().toIso8601String(),
            'startedDate': DateTime.now().toIso8601String(),
            'bookmarkedPages': [1],
            'notes': <String, dynamic>{},
          }
        ]),
      });

      final prefs = await SharedPreferences.getInstance();
      final progressService = BookProgressService(prefs);

      final all = await progressService.getAllProgress();
      expect(all.length, equals(1));
      expect(all.first.bookTitle, equals('القواعد الأربع'));

      final entries = await BookmarkEntryLoader.loadAll(progressService);
      expect(entries.length, equals(1));
      expect(entries.first.title, equals('القواعد الأربع'));
      expect(entries.first.page, equals(1));
      expect(entries.first.subtitle, contains('مقدمة'));
    });
  });
}
