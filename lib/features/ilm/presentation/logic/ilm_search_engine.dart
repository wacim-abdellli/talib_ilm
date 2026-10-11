import '../../data/models/mutun_models.dart';

/// Represents a ranked search result item in the Ilm library.
class IlmSearchResult {
  final IlmBook book;
  final int score;
  final String? matchSnippet;
  final String matchSource;

  const IlmSearchResult({
    required this.book,
    required this.score,
    this.matchSnippet,
    this.matchSource = 'all',
  });
}

/// High-craft, relevance-based search engine for mutun and Islamic books.
///
/// Ensures exact and title matches rank strictly before description/sharh matches,
/// and produces contextual snippets explaining why a book matched.
class IlmSearchEngine {
  IlmSearchEngine._();

  /// Normalizes Arabic text by removing tashkeel and unifying letter variants.
  static String normalizeArabic(String text) {
    if (text.isEmpty) return '';
    return text
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '') // remove tashkeel
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .toLowerCase()
        .trim();
  }

  /// Searches and ranks [books] according to [query].
  static List<IlmSearchResult> search({
    required List<IlmBook> books,
    required String query,
  }) {
    final q = normalizeArabic(query);
    if (q.isEmpty) return const [];

    final results = <IlmSearchResult>[];

    for (final book in books) {
      final tNorm = normalizeArabic(book.title);
      final sNorm = normalizeArabic(book.subject);
      final aNorm = normalizeArabic(book.author);
      final dNorm = normalizeArabic(book.description);

      int score = 0;
      String? source;
      String? snippet;

      // 1. Title matching (Highest priority)
      if (tNorm == q) {
        score += 1000;
        source = 'title';
      } else if (tNorm.startsWith(q)) {
        score += 500;
        source = 'title';
      } else if (tNorm.contains(q)) {
        score += 300;
        source = 'title';
      }

      // 2. Subject / Discipline matching
      if (sNorm.contains(q)) {
        score += 150;
        if (source == null) {
          source = 'subject';
          snippet = 'في التصنيف: ${book.subject.trim()}';
        }
      }

      // 3. Author matching
      if (aNorm.contains(q)) {
        score += 80;
        if (source == null) {
          source = 'author';
          snippet = 'المؤلف: ${book.author.trim()}';
        }
      }

      // 4. Description matching
      if (dNorm.contains(q)) {
        score += 40;
        if (source == null) {
          source = 'description';
          snippet = _extractSnippet(book.description, q);
        }
      }

      // 5. Shuruh & Scholars matching
      for (final sh in book.shuruh) {
        final stNorm = normalizeArabic(sh.title);
        final scNorm = normalizeArabic(sh.scholar);
        if (stNorm.contains(q) || scNorm.contains(q)) {
          score += 20;
          if (source == null) {
            source = 'sharh';
            snippet = 'في الشرح: ${sh.title.trim()}';
          }
          break;
        }
      }

      if (score > 0) {
        results.add(
          IlmSearchResult(
            book: book,
            score: score,
            matchSnippet: snippet,
            matchSource: source ?? 'general',
          ),
        );
      }
    }

    results.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      return a.book.title.compareTo(b.book.title);
    });

    return results;
  }

  static String _extractSnippet(String desc, String normQuery) {
    if (desc.isEmpty) return '';
    final dNorm = normalizeArabic(desc);
    final idx = dNorm.indexOf(normQuery);
    if (idx < 0) {
      return desc.length > 45 ? '${desc.substring(0, 45)}...' : desc;
    }

    final start = (idx - 12).clamp(0, desc.length);
    final end = (idx + normQuery.length + 18).clamp(0, desc.length);

    final prefix = start > 0 ? '...' : '';
    final suffix = end < desc.length ? '...' : '';
    final slice = desc.substring(start, end).trim();

    return 'في الوصف: $prefix$slice$suffix';
  }
}
