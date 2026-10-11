import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/ilm/data/models/mutun_models.dart';
import 'package:talib_ilm/features/ilm/presentation/logic/ilm_search_engine.dart';

void main() {
  group('IlmSearchEngine (Title-only search)', () {
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

    test('Searching "التوحيد" matches ONLY books with "التوحيد" in the title', () {
      final results = IlmSearchEngine.search(
        books: allBooks,
        query: 'التوحيد',
      );

      // Only book1 ("كتاب التوحيد") has "التوحيد" in its title
      expect(results.length, 1);
      expect(results[0].id, 'bk_kitab_tawheed');
    });

    test('Words in description do NOT match', () {
      // "تمييز" appears only in the description of bk_qawaid_arba
      final results = IlmSearchEngine.search(
        books: allBooks,
        query: 'تمييز',
      );

      expect(results, isEmpty);
    });

    test('Searching "الأصول" matches "الأصول الثلاثة وأدلتها"', () {
      final results = IlmSearchEngine.search(
        books: allBooks,
        query: 'الأصول',
      );

      expect(results.length, 1);
      expect(results[0].id, 'bk_usul_thalatha');
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
