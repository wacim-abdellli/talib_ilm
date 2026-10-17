import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/models/favorite_item.dart';
import 'package:talib_ilm/core/services/favorites_service.dart';
import 'package:talib_ilm/features/ilm/data/services/book_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Book Favorite Synchronization Tests', () {
    test('FavoritesService add and toggle work correctly for books', () async {
      final favService = FavoritesService();
      final bookItem = FavoriteItem(
        id: 'book_1',
        title: 'الآداب والأذكار',
        type: FavoriteType.book,
        subtitle: 'د. سعيد القحطاني',
      );

      expect(await favService.isFavorite(FavoriteType.book, 'book_1'), isFalse);

      await favService.add(bookItem);
      expect(await favService.isFavorite(FavoriteType.book, 'book_1'), isTrue);

      final bookIds = await favService.getIdsByType(FavoriteType.book);
      expect(bookIds.contains('book_1'), isTrue);

      // Toggling should remove it
      final isStillFav = await favService.toggle(bookItem);
      expect(isStillFav, isFalse);
      expect(await favService.isFavorite(FavoriteType.book, 'book_1'), isFalse);
    });

    test('BookProgressService setFavorite sets and updates favorite state correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      final progressService = BookProgressService(prefs);

      // Setting favorite for a book with no prior progress
      await progressService.setFavorite('book_adhkar', true, title: 'الآداب والأذكار');
      final progress = await progressService.getBookProgress('book_adhkar');
      expect(progress, isNotNull);
      expect(progress!.isFavorite, isTrue);
      expect(progress.bookTitle, 'الآداب والأذكار');

      // Setting favorite to false updates existing record
      await progressService.setFavorite('book_adhkar', false);
      final updated = await progressService.getBookProgress('book_adhkar');
      expect(updated, isNotNull);
      expect(updated!.isFavorite, isFalse);
    });
  });
}
