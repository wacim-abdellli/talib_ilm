import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/turath_catalog.dart';

void main() {
  group('Maktaba Heritage Treasury Enrichment & Multi-Level Tests', () {
    test('All newly added classical and foundational gems exist with verified metadata', () {
      final catalogIds = TurathCatalog.books.map((b) => b.id).toSet();

      final expectedNewIds = [
        22665, // العقيدة الواسطية (متن)
        22934, // شرح العقيدة الواسطية للهراس
        8195,  // الموقظة للذهبي
        23632, // المحرر الوجيز (تفسير ابن عطية)
        11376, // متن قطر الندى
        10695, // الدرر في اختصار المغازي والسير
        6848,  // كتاب الكبائر للذهبي
        21536, // التذكرة للقرطبي
        9942,  // الأصول من علم الأصول
      ];

      for (final id in expectedNewIds) {
        expect(catalogIds.contains(id), isTrue, reason: 'Book ID $id should be present in TurathCatalog');
      }
    });

    test('Al-Aqidah Al-Wasitiyyah and commentaries are hierarchically linked', () {
      final wasitiyyah = TurathCatalog.books.firstWhere((b) => b.id == 22665);
      expect(wasitiyyah.title, contains('العقيدة الواسطية'));
      expect(wasitiyyah.totalPages, 72);
      expect(wasitiyyah.level, 2);

      final shuruh = TurathCatalog.getShuruh(22665);
      expect(shuruh.length, greaterThanOrEqualTo(2));
      expect(shuruh.any((b) => b.id == 22934), isTrue); // الهراس
      expect(shuruh.any((b) => b.id == 11250), isTrue); // ابن عثيمين
    });

    test('Matn Qatr al-Nada and Sharh Qatr al-Nada are properly linked', () {
      final matn = TurathCatalog.books.firstWhere((b) => b.id == 11376);
      expect(matn.title, contains('متن قطر الندى'));
      expect(matn.totalPages, 34);

      final shuruh = TurathCatalog.getShuruh(11376);
      expect(shuruh.any((b) => b.id == 6970), isTrue);
      final sharh = shuruh.firstWhere((b) => b.id == 6970);
      expect(sharh.title, contains('شرح قطر الندى'));
      expect(sharh.parentBookId, 11376);
    });

    test('Al-Mawqizah by Al-Dhahabi is classified as Level 1 in Hadith sciences', () {
      final mawqizah = TurathCatalog.books.firstWhere((b) => b.id == 8195);
      expect(mawqizah.title, contains('الموقظة'));
      expect(mawqizah.author, contains('الذهبي'));
      expect(mawqizah.categoryId, 10);
      expect(mawqizah.level, 1);
      expect(mawqizah.totalPages, 72);
    });

    test('Tafsir Ibn Atiyyah (Al-Muharrar Al-Wajiz) is in Tafsir catalog with Level 3', () {
      final ibnAtiyyah = TurathCatalog.books.firstWhere((b) => b.id == 23632);
      expect(ibnAtiyyah.title, contains('المحرر الوجيز'));
      expect(ibnAtiyyah.author, contains('ابن عطية'));
      expect(ibnAtiyyah.categoryId, 3);
      expect(ibnAtiyyah.level, 3);
      expect(ibnAtiyyah.totalPages, 3012);
    });

    test('Al-Durar by Ibn Abd al-Barr is in Seerah catalog with Level 1', () {
      final durar = TurathCatalog.books.firstWhere((b) => b.id == 10695);
      expect(durar.title, contains('الدرر'));
      expect(durar.author, contains('ابن عبد البر'));
      expect(durar.categoryId, 24);
      expect(durar.level, 1);
      expect(durar.totalPages, 343);
    });

    test('Kitab al-Kaba\'ir and Al-Tadhkirah enrich Raqaeq catalog across levels', () {
      final kabair = TurathCatalog.books.firstWhere((b) => b.id == 6848);
      expect(kabair.title, contains('الكبائر'));
      expect(kabair.author, contains('الذهبي'));
      expect(kabair.categoryId, 23);
      expect(kabair.level, 1);
      expect(kabair.totalPages, 234);

      final tadhkirah = TurathCatalog.books.firstWhere((b) => b.id == 21536);
      expect(tadhkirah.title, contains('التذكرة'));
      expect(tadhkirah.author, contains('القرطبي'));
      expect(tadhkirah.categoryId, 23);
      expect(tadhkirah.level, 3);
      expect(tadhkirah.totalPages, 1348);
    });

    test('Al-Usul min Ilm al-Usul is in Usul catalog with Level 1', () {
      final usul = TurathCatalog.books.firstWhere((b) => b.id == 9942);
      expect(usul.title, contains('الأصول من علم الأصول'));
      expect(usul.author, contains('العثيمين'));
      expect(usul.categoryId, 11);
      expect(usul.level, 1);
      expect(usul.totalPages, 93);
    });

    test('Every single discipline has books in Level 1 (Easy), Level 2 (Medium), and Level 3 (Hard)', () {
      final disciplines = TurathCatalog.disciplines.where((d) => d.id > 0).toList();
      expect(disciplines.length, 12);

      for (final discipline in disciplines) {
        final booksInCat = TurathCatalog.books.where((b) => b.categoryId == discipline.id).toList();

        final l1 = booksInCat.where((b) => b.level == 1).toList();
        final l2 = booksInCat.where((b) => b.level == 2).toList();
        final l3 = booksInCat.where((b) => b.level == 3).toList();

        expect(l1.isNotEmpty, isTrue, reason: 'Discipline ${discipline.name} must have Level 1 books');
        expect(l2.isNotEmpty, isTrue, reason: 'Discipline ${discipline.name} must have Level 2 books');
        expect(l3.isNotEmpty, isTrue, reason: 'Discipline ${discipline.name} must have Level 3 books');
      }
    });
  });
}
