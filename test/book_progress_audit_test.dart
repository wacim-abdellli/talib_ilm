import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/ilm/data/models/book_progress_model.dart';
import 'package:talib_ilm/features/ilm/data/services/book_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BookProgress Model Tests', () {
    test('isCompleted is false when totalPages is 0 or 1', () {
      final p1 = BookProgress(
        bookId: 'bk_1',
        bookTitle: 'Test',
        level: '1',
        totalPages: 1,
        currentPage: 2,
        lastReadDate: DateTime.now(),
        startedDate: DateTime.now(),
      );
      expect(p1.isCompleted, isFalse);

      final p0 = BookProgress(
        bookId: 'bk_1',
        bookTitle: 'Test',
        level: '1',
        totalPages: 0,
        currentPage: 4,
        lastReadDate: DateTime.now(),
        startedDate: DateTime.now(),
      );
      expect(p0.isCompleted, isFalse);
    });

    test('isCompleted is false when reading 2 pages out of 60', () {
      final p = BookProgress(
        bookId: 'bk_adhkar_adab',
        bookTitle: 'الآداب والأذكار',
        level: 'المستوى التمهيدي',
        totalPages: 60,
        currentPage: 2,
        lastReadDate: DateTime.now(),
        startedDate: DateTime.now(),
      );
      expect(p.isCompleted, isFalse);
      expect(p.progressPercentage, closeTo(3.33, 0.1));
    });

    test('isCompleted is true only when currentPage >= totalPages', () {
      final p = BookProgress(
        bookId: 'bk_adhkar_adab',
        bookTitle: 'الآداب والأذكار',
        level: 'المستوى التمهيدي',
        totalPages: 60,
        currentPage: 60,
        lastReadDate: DateTime.now(),
        startedDate: DateTime.now(),
      );
      expect(p.isCompleted, isTrue);
      expect(p.progressPercentage, 100.0);
    });
  });

  group('BookProgressService Audit & Healing Tests', () {
    late SharedPreferences prefs;
    late BookProgressService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = BookProgressService(prefs);
    });

    test('auditAndHealCatalogProgress repairs corrupted totalPages and clears false completion', () async {
      // Simulate the exact bug: book was saved with totalPages = 1 and currentPage = 4, marked completed
      final corrupted = BookProgress(
        bookId: 'bk_adhkar_adab',
        bookTitle: 'الآداب والأذكار',
        level: 'المستوى التمهيدي',
        totalPages: 1,
        currentPage: 4,
        completedDate: DateTime.now(),
        lastReadDate: DateTime.now(),
        startedDate: DateTime.now(),
      );
      await service.saveBookProgress(corrupted);

      // Verify it was in corrupted state
      var saved = await service.getBookProgress('bk_adhkar_adab');
      expect(saved?.totalPages, 1);

      // Run audit and healing with canonical catalog totals
      final catalogTotals = {'bk_adhkar_adab': 60};
      await service.auditAndHealCatalogProgress(catalogTotals);

      // Verify healed state
      final healed = await service.getBookProgress('bk_adhkar_adab');
      expect(healed, isNotNull);
      expect(healed!.totalPages, 60);
      expect(healed.currentPage, 4);
      expect(healed.completedDate, isNull);
      expect(healed.isCompleted, isFalse);
      expect(healed.progressPercentage, closeTo(6.66, 0.1));
    });

    test('updateCurrentPage preserves higher totalPages and clears completion if page < totalPages', () async {
      await service.initializeBook(
        bookId: 'bk_adhkar_adab',
        bookTitle: 'الآداب والأذكار',
        level: 'المستوى التمهيدي',
        totalPages: 60,
      );

      // Update to page 4
      await service.updateCurrentPage('bk_adhkar_adab', 4, totalPages: 60);

      final progress = await service.getBookProgress('bk_adhkar_adab');
      expect(progress!.currentPage, 4);
      expect(progress.totalPages, 60);
      expect(progress.isCompleted, isFalse);
      expect(progress.completedDate, isNull);
    });
  });
}
