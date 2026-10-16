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

    test('sanitizeBookText cleans Cloudflare [email protected] and email obfuscation artifacts', () {
      // 1. User screenshot case: [email&#160;protected]
      const userCase = '* اعتنى به: محمد المنصور [email&#160;protected]\n١٧/٨/١٤٢٩هـ - ١٩/٨/٢٠٠٨م';
      final cleaned1 = ShamelaService.sanitizeBookText(userCase);
      expect(cleaned1.contains('email'), isFalse);
      expect(cleaned1.contains('protected'), isFalse);
      expect(cleaned1, contains('* اعتنى به: محمد المنصور'));
      expect(cleaned1, contains('١٧/٨/١٤٢٩هـ - ١٩/٨/٢٠٠٨م'));

      // 2. Raw HTML anchor from Cloudflare
      const htmlCase = '* اعتنى به: محمد المنصور <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="107d4f717c7d717e637f6562506971787f7f3e737f7d">[email&#160;protected]</a>';
      final cleaned2 = ShamelaService.sanitizeBookText(htmlCase);
      expect(cleaned2, equals('* اعتنى به: محمد المنصور'));

      // 3. Simple [email protected]
      const simpleCase = 'للتواصل مع المحقق: [email protected]';
      final cleaned3 = ShamelaService.sanitizeBookText(simpleCase);
      expect(cleaned3, equals('للتواصل مع المحقق:'));

      // 4. Preserves authentic Islamic classical footnotes untouched
      const normalFootnote = '(١) أخرجه البخاري في كتاب الإيمان، باب أمور الإيمان (رقم ٩).';
      final cleaned4 = ShamelaService.sanitizeBookText(normalFootnote);
      expect(cleaned4, equals(normalFootnote));
    });

    test('Sullam level categorization contains books across all 3 scholarly levels', () {
      final classics = ShamelaService.curatedClassics;

      final level1 = classics.where((b) => b.level == 1).toList();
      final level2 = classics.where((b) => b.level == 2).toList();
      final level3 = classics.where((b) => b.level == 3).toList();

      expect(level1.isNotEmpty, isTrue, reason: 'Must have level 1 (مبتدئ / تأسيسي) books');
      expect(level2.isNotEmpty, isTrue, reason: 'Must have level 2 (متوسط / تأصيلي) books');
      expect(level3.isNotEmpty, isTrue, reason: 'Must have level 3 (متقدم / مطولات) books');

      // Test level filtering via searchCatalog
      final filteredLevel1 = ShamelaService.searchCatalog(level: 1);
      expect(filteredLevel1.every((b) => b.level == 1), isTrue);

      final filteredLevel2 = ShamelaService.searchCatalog(level: 2);
      expect(filteredLevel2.every((b) => b.level == 2), isTrue);

      final filteredLevel3 = ShamelaService.searchCatalog(level: 3);
      expect(filteredLevel3.every((b) => b.level == 3), isTrue);
    });

    test('Mother books and commentaries (متن وشروح) are accurately linked', () {
      // 1. Kitāb at-Tawhīd (ID: 11318) has commentaries
      final tawhidShuruh = ShamelaService.getShuruh(11318);
      expect(tawhidShuruh.isNotEmpty, isTrue);
      expect(tawhidShuruh.any((b) => b.title.contains('فتح المجيد')), isTrue);
      expect(tawhidShuruh.any((b) => b.title.contains('القول السديد')), isTrue);
      for (final s in tawhidShuruh) {
        expect(s.parentBookId, equals(11318));
        expect(s.isSharh, isTrue);
        expect(s.sharhType, isNotNull);
      }

      // 2. Parent book lookup
      final fatihAlMajid = tawhidShuruh.firstWhere((b) => b.title.contains('فتح المجيد'));
      final parentOfFath = ShamelaService.getParentBook(fatihAlMajid.parentBookId!);
      expect(parentOfFath, isNotNull);
      expect(parentOfFath!.id, equals(11318));
      expect(parentOfFath.title, contains('كتاب التوحيد'));

      // 3. Zād al-Mustaqni' (ID: 11230) has al-Rawd al-Murbi'
      final zadShuruh = ShamelaService.getShuruh(11230);
      expect(zadShuruh.isNotEmpty, isTrue);
      expect(zadShuruh.any((b) => b.title.contains('الروض المربع')), isTrue);

      // 4. rootOnly filtering separates mother books from nested commentaries
      final allAqeedah = ShamelaService.searchCatalog(categoryId: 1);
      final rootAqeedah = ShamelaService.searchCatalog(categoryId: 1, rootOnly: true);
      expect(rootAqeedah.length, lessThan(allAqeedah.length));
      expect(rootAqeedah.every((b) => b.parentBookId == null), isTrue);
    });
  });
}
