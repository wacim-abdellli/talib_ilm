import '../../../../core/utils/arabic_search_utils.dart';
import '../models/shamela_models.dart';
import 'raqaeq_adab_catalog.dart';
import 'aqidah_catalog.dart';
import 'arabic_catalog.dart';
import 'fiqh_catalog.dart';
import 'hadith_catalog.dart';
import 'seerah_tarikh_catalog.dart';
import 'tafsir_catalog.dart';
import 'usul_catalog.dart';

/// The Great Heritage Treasury (خزانة التراث الإسلامي)
/// Comprehensive curated library of foundational classical masterworks across all disciplines ("الفنون").
/// Every book ID is authenticated and verified directly against Maktaba Shamela (shamela.ws).
class TurathCatalog {
  /// Comprehensive list of verified foundational classical Islamic books
  static final List<ShamelaBook> books = [
    ...AqidahCatalog.books,
    ...HadithCatalog.sunnahBooks,
    ...HadithCatalog.ulumBooks,
    ...TafsirCatalog.books,
    ...FiqhCatalog.hanbaliBooks,
    ...FiqhCatalog.shafiiBooks,
    ...FiqhCatalog.malikiBooks,
    ...FiqhCatalog.hanafiBooks,
    ...UsulCatalog.books,
    ...ArabicCatalog.books,
    ...SeerahTarikhCatalog.books,
    ...RaqaeqAdabCatalog.books,
  ];

  /// Disciplines / Sciences (الفنون والعلوم الشرعية)
  static List<ShamelaCategory> get disciplines => [
        ShamelaCategory(id: 0, name: 'الكل', count: books.length),
        ShamelaCategory(
          id: 1,
          name: 'العقيدة والتوحيد',
          count: AqidahCatalog.books.length,
        ),
        ShamelaCategory(
          id: 6,
          name: 'كتب السنة والحديث',
          count: HadithCatalog.sunnahBooks.length,
        ),
        ShamelaCategory(
          id: 10,
          name: 'علوم الحديث والمصطلح',
          count: HadithCatalog.ulumBooks.length,
        ),
        ShamelaCategory(
          id: 3,
          name: 'التفسير وعلوم القرآن',
          count: TafsirCatalog.books.length,
        ),
        ShamelaCategory(
          id: 17,
          name: 'الفقه الحنبلي',
          count: FiqhCatalog.hanbaliBooks.length,
        ),
        ShamelaCategory(
          id: 16,
          name: 'الفقه الشافعي',
          count: FiqhCatalog.shafiiBooks.length,
        ),
        ShamelaCategory(
          id: 15,
          name: 'الفقه المالكي',
          count: FiqhCatalog.malikiBooks.length,
        ),
        ShamelaCategory(
          id: 14,
          name: 'الفقه الحنفي',
          count: FiqhCatalog.hanafiBooks.length,
        ),
        ShamelaCategory(
          id: 11,
          name: 'أصول الفقه والقواعد',
          count: UsulCatalog.books.length,
        ),
        ShamelaCategory(
          id: 31,
          name: 'النحو واللغة العربية',
          count: ArabicCatalog.books.length,
        ),
        ShamelaCategory(
          id: 24,
          name: 'السيرة النبوية والتاريخ',
          count: SeerahTarikhCatalog.books.length,
        ),
        ShamelaCategory(
          id: 23,
          name: 'الرقائق والآداب والأذكار',
          count: RaqaeqAdabCatalog.books.length,
        ),
      ];

  /// Search and filter catalog with normalized Arabic query matching
  static List<ShamelaBook> search({
    String query = '',
    int categoryId = 0,
  }) {
    var filtered = books;

    if (categoryId > 0) {
      filtered = filtered.where((b) => b.categoryId == categoryId).toList();
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) return filtered;

    return filtered.where((b) {
      final inTitle = ArabicSearchUtils.matches(b.title, trimmed);
      final inAuthor = ArabicSearchUtils.matches(b.author, trimmed);
      final inDesc = ArabicSearchUtils.matches(b.description, trimmed);

      return inTitle || inAuthor || inDesc;
    }).toList();
  }
}
