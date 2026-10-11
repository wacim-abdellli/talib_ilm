import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/ilm/data/models/mutun_models.dart';
import 'package:talib_ilm/features/ilm/presentation/logic/ilm_search_engine.dart';

void main() {
  group('IlmSearchEngine', () {
    final book1 = IlmBook(
      id: 'bk_kitab_tawheed',
      title: 'كتاب التوحيد',
      author: 'محمد بن عبد الوهاب',
      subject: 'العقيدة',
      description: 'كتاب يجمع أبواب التوحيد وينقض الشرك بأدلته من القرآن والسنة.',
      totalPages: 100,
      pdfPath: 'assets/pdfs/mutun/bk_kitab_tawheed.pdf',
      shuruh: const [],
      level: 'المستوى الثاني',
    );

    final book2 = IlmBook(
      id: 'bk_qawaid_arba',
      title: 'القواعد الأربع',
      author: 'محمد بن عبد الوهاب',
      subject: 'العقيدة',
      description: 'قواعد عظيمة في تمييز التوحيد عن الشرك.',
      totalPages: 16,
      pdfPath: 'assets/pdfs/mutun/bk_qawaid_arba.pdf',
      shuruh: const [],
      level: 'المستوى الأول',
    );

    final book3 = IlmBook(
      id: 'bk_usul_thalatha',
      title: 'الأصول الثلاثة وأدلتها',
      author: 'محمد بن عبد الوهاب',
      subject: 'العقيدة',
      description: 'الأصل الأصيل في تقرير أصول التوحيد والإيمان ومعرفة العبد ربه ودينه ونبيه بالأدلة.',
      totalPages: 30,
      pdfPath: 'assets/pdfs/mutun/bk_usul_thalatha.pdf',
      shuruh: const [],
      level: 'المستوى الأول',
    );

    final book4 = IlmBook(
      id: 'bk_ajrumiyyah',
      title: 'المقدمة الآجرومية',
      author: 'ابن آجروم',
      subject: 'اللغة العربية',
      description: 'المتن الأشهر للمبتدئ في النحو، يقدم القواعد الأساسية.',
      totalPages: 30,
      pdfPath: 'assets/pdfs/mutun/bk_ajrumiyyah.pdf',
      shuruh: const [],
      level: 'المستوى الثالث',
    );

    final allBooks = [book2, book1, book3, book4];

    test('Searching "التوحيد" ranks "كتاب التوحيد" at #1', () {
      final results = IlmSearchEngine.search(
        books: allBooks,
        query: 'التوحيد',
      );

      expect(results.length, 3);
      expect(results[0].book.id, 'bk_kitab_tawheed');
      expect(results[0].score, greaterThan(results[1].score));
      expect(results[0].matchSource, 'title');
    });

    test('Non-title matches provide descriptive snippets', () {
      final results = IlmSearchEngine.search(
        books: allBooks,
        query: 'التوحيد',
      );

      final qawaid = results.firstWhere((r) => r.book.id == 'bk_qawaid_arba');
      expect(qawaid.matchSnippet, contains('في الوصف:'));
      expect(qawaid.matchSnippet, contains('التوحيد'));
    });

    test('Searching by subject ranks related books', () {
      final results = IlmSearchEngine.search(
        books: allBooks,
        query: 'اللغة العربية',
      );

      expect(results.length, 1);
      expect(results[0].book.id, 'bk_ajrumiyyah');
    });

    test('Empty query returns empty list', () {
      final results = IlmSearchEngine.search(
        books: allBooks,
        query: '   ',
      );

      expect(results, isEmpty);
    });
  });
}
