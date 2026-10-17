import 'texts/mutun_texts_level0.dart';
import 'texts/mutun_texts_level1.dart';
import 'texts/mutun_texts_level2.dart';
import 'texts/mutun_texts_level3.dart';
import 'texts/mutun_texts_usul_thalatha.dart';

/// Single scholarly paragraph in the authentic mutun syllabus.
class MutunParagraph {
  final int index;
  final String text;

  const MutunParagraph({
    required this.index,
    required this.text,
  });
}

/// Thematic scholarly section grouping paragraphs (e.g., فضل طلب العلم, الناقض الأول).
class MutunSection {
  final String title;
  final List<MutunParagraph> paragraphs;

  const MutunSection({
    required this.title,
    required this.paragraphs,
  });
}

/// Authentic curriculum edition book representation.
class MutunCurriculumBook {
  final String id;
  final String title;
  final String author;
  final List<MutunSection> sections;

  const MutunCurriculumBook({
    required this.id,
    required this.title,
    required this.author,
    required this.sections,
  });

  int get totalParagraphs =>
      sections.fold(0, (sum, sec) => sum + sec.paragraphs.length);

  List<MutunParagraph> get allParagraphs =>
      sections.expand((sec) => sec.paragraphs).toList();

  MutunParagraph? getParagraph(int index) {
    for (final sec in sections) {
      for (final p in sec.paragraphs) {
        if (p.index == index) return p;
      }
    }
    return null;
  }
}

/// Central catalog linking syllabus mutun to their authentic, verified recitations text.
class MutunCurriculumCatalog {
  const MutunCurriculumCatalog._();

  static final Map<String, MutunCurriculumBook> _books = {
    // ── المستوى التمهيدي ──
    'bk_adhkar_adab': MutunTextsLevel0.adhkarAdab,

    // ── المستوى الأول ──
    'bk_nawaqid_islam': MutunTextsLevel1.nawaqidIslam,
    'bk_qawaid_arba': MutunTextsLevel1.qawaidArba,
    'bk_usul_thalatha': MutunTextsUsulThalatha.usulThalatha,

    // ── المستوى الثاني ──
    'bk_shuroot_salah': MutunTextsLevel2.shurootSalah,
    'bk_shurut_salah': MutunTextsLevel2.shurootSalah,
    'bk_tuhfat_atfal': MutunTextsLevel2.tuhfatAtfal,

    // ── المستوى الثالث ──
    'bk_manzumah_baiquoni': MutunTextsLevel3.baiquoni,
    'bk_manzooma_bayquniyya': MutunTextsLevel3.baiquoni,
  };

  /// Check if authentic digitized matn text is available for a book
  static bool hasBook(String? bookId) {
    if (bookId == null) return false;
    return _books.containsKey(bookId);
  }

  /// Retrieve the authentic curriculum book
  static MutunCurriculumBook? getBook(String? bookId) {
    if (bookId == null) return null;
    return _books[bookId];
  }
}
