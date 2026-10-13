import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/ilm/data/models/shamela_models.dart';
import 'package:talib_ilm/features/ilm/data/services/shamela_service.dart';

void main() {
  group('Shamela Models & Catalog Tests', () {
    test('Curated classics list is populated with valid masterworks', () {
      final classics = ShamelaService.curatedClassics;
      expect(classics.isNotEmpty, isTrue);
      expect(classics.length, greaterThanOrEqualTo(15));

      for (final book in classics) {
        expect(book.id, greaterThan(0));
        expect(book.title.trim().isNotEmpty, isTrue);
        expect(book.author.trim().isNotEmpty, isTrue);
        expect(book.totalPages, greaterThan(0));
        expect(book.category.trim().isNotEmpty, isTrue);
      }
    });

    test('Categories list contains all essential Islamic knowledge disciplines', () {
      final categories = ShamelaService.categories;
      expect(categories.isNotEmpty, isTrue);
      final names = categories.map((c) => c.name).toList();

      expect(names, contains('الكل'));
      expect(names.any((n) => n.contains('العقيدة')), isTrue);
      expect(names.any((n) => n.contains('السنة')), isTrue);
      expect(names.any((n) => n.contains('أصول الفقه')), isTrue);
    });

    test('Search catalog by book title', () {
      final results = ShamelaService.searchCatalog(query: 'التوحيد');
      expect(results.isNotEmpty, isTrue);
      for (final b in results) {
        final matches = b.title.contains('التوحيد') ||
            b.author.contains('التوحيد') ||
            b.description.contains('التوحيد');
        expect(matches, isTrue);
      }
    });

    test('Search catalog by author name', () {
      final results = ShamelaService.searchCatalog(query: 'النووي');
      expect(results.isNotEmpty, isTrue);
      expect(results.any((b) => b.author.contains('النووي')), isTrue);
    });

    test('Filter catalog by category ID', () {
      // Category 1 is العقيدة
      final aqeedahBooks = ShamelaService.searchCatalog(categoryId: 1);
      expect(aqeedahBooks.isNotEmpty, isTrue);
      for (final b in aqeedahBooks) {
        expect(b.categoryId, equals(1));
      }
    });

    test('ShamelaBook JSON serialization roundtrip', () {
      const original = ShamelaBook(
        id: 30198,
        title: 'ثلاثة الأصول',
        author: 'محمد بن عبد الوهاب',
        authorDeath: '1206',
        categoryId: 1,
        category: 'العقيدة',
        totalPages: 24,
        description: 'رسالة نافعة في توحيد الربوبية والألوهية',
      );

      final json = original.toJson();
      final revived = ShamelaBook.fromJson(json);

      expect(revived.id, equals(original.id));
      expect(revived.title, equals(original.title));
      expect(revived.author, equals(original.author));
      expect(revived.authorDeath, equals(original.authorDeath));
      expect(revived.categoryId, equals(original.categoryId));
      expect(revived.category, equals(original.category));
      expect(revived.totalPages, equals(original.totalPages));
      expect(revived.description, equals(original.description));
    });

    test('ShamelaPage JSON serialization roundtrip', () {
      const original = ShamelaPage(
        bookId: 30198,
        pageNumber: 3,
        content: 'اعلم رحمك الله أنه يجب علينا تعلم أربع مسائل',
        partNumber: 1,
        chapterTitle: 'المقدمة الأولى',
        hamesh: 'حاشية ابن قاسم رحمه الله',
      );

      final json = original.toJson();
      final revived = ShamelaPage.fromJson(json);

      expect(revived.bookId, equals(original.bookId));
      expect(revived.pageNumber, equals(original.pageNumber));
      expect(revived.content, equals(original.content));
      expect(revived.partNumber, equals(original.partNumber));
      expect(revived.chapterTitle, equals(original.chapterTitle));
      expect(revived.hamesh, equals(original.hamesh));
    });

    test('ShamelaChapter JSON serialization roundtrip', () {
      const original = ShamelaChapter(
        title: 'باب في فضل العلم',
        pageNumber: 12,
      );

      final json = original.toJson();
      final revived = ShamelaChapter.fromJson(json);

      expect(revived.title, equals(original.title));
      expect(revived.pageNumber, equals(original.pageNumber));
    });
  });
}
