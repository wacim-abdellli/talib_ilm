import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/ilm/data/models/shamela_models.dart';
import 'package:talib_ilm/features/ilm/data/services/shamela_service.dart';

void main() {
  group('Shamela Models & Catalog Tests', () {
    test('Curated classics list is populated with 180+ valid masterworks across all disciplines', () {
      final classics = ShamelaService.curatedClassics;
      expect(classics.isNotEmpty, isTrue);
      expect(classics.length, greaterThanOrEqualTo(180));

      final ids = <int>{};
      for (final book in classics) {
        expect(book.id, greaterThan(0), reason: 'Book ${book.title} must have positive ID');
        expect(book.title.trim().isNotEmpty, isTrue);
        expect(book.author.trim().isNotEmpty, isTrue);
        expect(book.authorDeath?.trim().isNotEmpty, isTrue);
        expect(book.description.trim().isNotEmpty, isTrue);
        expect(book.totalPages, greaterThan(0));
        expect(book.categoryId, greaterThan(0));
        expect(book.category.trim().isNotEmpty, isTrue);
        ids.add(book.id);
      }
      // Ensure unique IDs or acceptable duplicates
      expect(ids.length, greaterThanOrEqualTo(170));
    });

    test('Categories list contains all 12 essential Islamic knowledge disciplines with correct counts', () {
      final categories = ShamelaService.categories;
      expect(categories.length, equals(13)); // 0: الكل + 12 disciplines
      final names = categories.map((c) => c.name).toList();

      expect(names, contains('الكل'));
      expect(names, contains('العقيدة والتوحيد'));
      expect(names, contains('كتب السنة والحديث'));
      expect(names, contains('علوم الحديث والمصطلح'));
      expect(names, contains('التفسير وعلوم القرآن'));
      expect(names, contains('الفقه الحنبلي'));
      expect(names, contains('الفقه الشافعي'));
      expect(names, contains('الفقه المالكي'));
      expect(names, contains('الفقه الحنفي'));
      expect(names, contains('أصول الفقه والقواعد'));
      expect(names, contains('النحو واللغة العربية'));
      expect(names, contains('السيرة النبوية والتاريخ'));
      expect(names, contains('الرقائق والآداب والأذكار'));

      // Ensure every discipline category has books
      for (final cat in categories) {
        expect(cat.count, greaterThan(0), reason: 'Category ${cat.name} must have books');
      }
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
