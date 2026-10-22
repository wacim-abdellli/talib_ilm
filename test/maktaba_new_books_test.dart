import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/turath_catalog.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/aqidah_catalog.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/seerah_tarikh_catalog.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/raqaeq_adab_catalog.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/fiqh_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Maktaba 5 New Books Verification Tests', () {
    test('All 5 requested books are present in TurathCatalog.books with correct IDs', () {
      final bookIds = TurathCatalog.books.map((b) => b.id).toSet();

      expect(bookIds.contains(14132), isTrue, reason: '100 من عظماء الإسلام must be present');
      expect(bookIds.contains(22726), isTrue, reason: 'الفقه الميسر must be present');
      expect(bookIds.contains(30847), isTrue, reason: 'أصول الإيمان must be present');
      expect(bookIds.contains(13136), isTrue, reason: 'فضائل الصحابة must be present');
      expect(bookIds.contains(50001), isTrue, reason: 'منهاج المسلم must be present');
    });

    test('100 من عظماء الإسلام metadata and classification', () {
      final book = TurathCatalog.books.firstWhere((b) => b.id == 14132);
      expect(book.author, 'جهاد الترباني');
      expect(book.categoryId, 24);
      expect(book.totalPages, 458);
      expect(SeerahTarikhCatalog.books.any((b) => b.id == 14132), isTrue);
    });

    test('الفقه الميسر metadata and classification', () {
      final book = TurathCatalog.books.firstWhere((b) => b.id == 22726);
      expect(book.title, contains('الفقه الميسر'));
      expect(book.categoryId, 17);
      expect(book.totalPages, 439);
      expect(FiqhCatalog.hanbaliBooks.any((b) => b.id == 22726), isTrue);
    });

    test('أصول الإيمان metadata and classification', () {
      final book = TurathCatalog.books.firstWhere((b) => b.id == 30847);
      expect(book.title, contains('أصول الإيمان'));
      expect(book.categoryId, 1);
      expect(book.totalPages, 272);
      expect(AqidahCatalog.books.any((b) => b.id == 30847), isTrue);
    });

    test('فضائل الصحابة metadata and classification', () {
      final book = TurathCatalog.books.firstWhere((b) => b.id == 13136);
      expect(book.title, contains('فضائل الصحابة'));
      expect(book.author, contains('بن حنبل'));
      expect(book.categoryId, 24);
      expect(book.totalPages, 1947);
      expect(SeerahTarikhCatalog.books.any((b) => b.id == 13136), isTrue);
    });

    test('منهاج المسلم metadata and classification', () {
      final book = TurathCatalog.books.firstWhere((b) => b.id == 50001);
      expect(book.title, contains('منهاج المسلم'));
      expect(book.author, contains('أبو بكر جابر الجزائري'));
      expect(book.categoryId, 23);
      expect(book.totalPages, 455);
      expect(RaqaeqAdabCatalog.books.any((b) => b.id == 50001), isTrue);
    });

    test('Search catalog finds all 5 books by requested Arabic query variations', () {
      // 1. 100من عظماء الاسلام (attached and eastern numerals)
      final res1 = TurathCatalog.search(query: '100من عظماء الاسلام');
      expect(res1.any((b) => b.id == 14132), isTrue);

      final res1Eastern = TurathCatalog.search(query: '١٠٠');
      expect(res1Eastern.any((b) => b.id == 14132), isTrue);

      // 2. الفقه الميسر
      final res2 = TurathCatalog.search(query: 'الفقه الميسر');
      expect(res2.any((b) => b.id == 22726), isTrue);

      // 3. اصول الايمان (without hamza)
      final res3 = TurathCatalog.search(query: 'اصول الايمان');
      expect(res3.any((b) => b.id == 30847), isTrue);

      // 4. فضائل الصحابة
      final res4 = TurathCatalog.search(query: 'فضائل الصحابة');
      expect(res4.any((b) => b.id == 13136), isTrue);

      // 5. منهاج المسلم
      final res5 = TurathCatalog.search(query: 'منهاج المسلم');
      expect(res5.any((b) => b.id == 50001), isTrue);
    });

    test('Bundled assets/data/minhaj_al_muslim.json is valid and structured', () {
      final file = File('assets/data/minhaj_al_muslim.json');
      expect(file.existsSync(), isTrue);

      final jsonMap = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(jsonMap['bookId'], 50001);
      expect(jsonMap['title'], contains('منهاج المسلم'));
      expect(jsonMap['author'], contains('أبو بكر جابر الجزائري'));

      final pages = jsonMap['pages'] as List<dynamic>;
      expect(pages.length, greaterThanOrEqualTo(450));
      expect(pages.first['content'], isNotEmpty);

      final chapters = jsonMap['chapters'] as List<dynamic>;
      expect(chapters.length, greaterThanOrEqualTo(20));
    });
  });
}
