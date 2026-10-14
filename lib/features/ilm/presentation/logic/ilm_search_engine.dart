import '../../data/models/mutun_models.dart';

/// Minimalist, high-accuracy title search engine for mutun and Islamic books.
///
/// Restricts searches strictly to book titles/names, ensuring no spurious matches
/// from descriptions, commentary, or extraneous metadata.
class IlmSearchEngine {
  IlmSearchEngine._();

  static final RegExp _tashkeelRegex = RegExp(r'[\u064B-\u0652]');
  static final RegExp _alefRegex = RegExp(r'[أإآ]');

  static final Map<String, String> _normalizedTitleCache = {};

  /// Normalizes Arabic text by removing tashkeel and unifying letter variants.
  static String normalizeArabic(String text) {
    if (text.isEmpty) return '';
    return text
        .replaceAll(_tashkeelRegex, '') // remove tashkeel
        .replaceAll(_alefRegex, 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .toLowerCase()
        .trim();
  }

  /// Searches and ranks [books] strictly by their title/name matching [query].
  static List<IlmBook> search({
    required List<IlmBook> books,
    required String query,
  }) {
    final q = normalizeArabic(query);
    if (q.isEmpty) return const [];

    final matched = <(int score, IlmBook book)>[];

    for (final book in books) {
      final tNorm = _normalizedTitleCache.putIfAbsent(
        book.id,
        () => normalizeArabic(book.title),
      );

      int score = 0;
      if (tNorm == q) {
        score = 1000;
      } else if (tNorm.startsWith(q)) {
        score = 500;
      } else if (tNorm.contains(q)) {
        score = 300;
      }

      if (score > 0) {
        matched.add((score, book));
      }
    }

    matched.sort((a, b) {
      final cmp = b.$1.compareTo(a.$1);
      if (cmp != 0) return cmp;
      return a.$2.title.compareTo(b.$2.title);
    });

    return matched.map((m) => m.$2).toList();
  }
}
