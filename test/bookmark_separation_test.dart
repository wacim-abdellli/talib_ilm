import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/quran/data/services/bookmark_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Surah vs Ayah/Note Bookmark Separation Tests', () {
    test('Adding a note on an ayah does NOT mark the surah as bookmarked', () async {
      // 1. User writes a note/tadabbur on Surah 2 Ayah 255
      await BookmarkService.updateNote(2, 255, 'آية الكرسي العظيمة وتأملاتها');

      // 2. Surah 2 must NOT be marked as bookmarked!
      final isSurahSaved = await BookmarkService.isSurahBookmarked(2);
      expect(isSurahSaved, isFalse);

      // 3. Ayah 2:255 IS bookmarked
      final isAyahSaved = await BookmarkService.isAyahBookmarked(2, 255);
      expect(isAyahSaved, isTrue);

      // 4. In all bookmarks (al-mahfoudhat), the note exists with isSurah == false
      final bookmarks = await BookmarkService.getBookmarks();
      expect(bookmarks.length, equals(1));
      expect(bookmarks.first.surah, equals(2));
      expect(bookmarks.first.ayah, equals(255));
      expect(bookmarks.first.isSurah, isFalse);
      expect(bookmarks.first.note, equals('آية الكرسي العظيمة وتأملاتها'));
    });

    test('Bookmarking a Surah marks only the Surah, not individual verses', () async {
      // 1. User taps bookmark on Surah 18 (Al-Kahf)
      final toggled = await BookmarkService.toggleSurahBookmark(18);
      expect(toggled, isTrue);

      // 2. Surah 18 is marked as bookmarked
      final isSurahSaved = await BookmarkService.isSurahBookmarked(18);
      expect(isSurahSaved, isTrue);

      // 3. Ayah 18:1 is NOT an ayah bookmark
      final isAyahSaved = await BookmarkService.isAyahBookmarked(18, 1);
      expect(isAyahSaved, isFalse);

      // 4. In all bookmarks, it exists with isSurah == true
      final bookmarks = await BookmarkService.getBookmarks();
      expect(bookmarks.length, equals(1));
      expect(bookmarks.first.surah, equals(18));
      expect(bookmarks.first.isSurah, isTrue);
    });

    test('Both Surah and Ayah notes appear together in al-mahfoudhat without interfering', () async {
      // Save Surah 36 (Ya-Sin)
      await BookmarkService.toggleSurahBookmark(36);

      // Save an Ayah note on Surah 36 Ayah 82
      await BookmarkService.updateNote(36, 82, 'إنما أمره إذا أراد شيئا');

      final bookmarks = await BookmarkService.getBookmarks();
      expect(bookmarks.length, equals(2));

      // Surah is marked as bookmarked
      expect(await BookmarkService.isSurahBookmarked(36), isTrue);

      // Ayah note is marked as bookmarked
      expect(await BookmarkService.isAyahBookmarked(36, 82), isTrue);

      // Removing Surah leaves Ayah note intact
      await BookmarkService.removeBookmark(36, 1, isSurah: true);
      expect(await BookmarkService.isSurahBookmarked(36), isFalse);
      expect(await BookmarkService.isAyahBookmarked(36, 82), isTrue);

      final remaining = await BookmarkService.getBookmarks();
      expect(remaining.length, equals(1));
      expect(remaining.first.ayah, equals(82));
      expect(remaining.first.note, contains('إنما أمره'));
    });
  });
}
