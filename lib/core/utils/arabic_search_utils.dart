/// Utility for resilient, diacritic-agnostic Arabic search and normalization.
class ArabicSearchUtils {
  ArabicSearchUtils._();

  static final RegExp _tashkeelRegex = RegExp(r'[\u064B-\u065F\u0670]');
  static final RegExp _alefRegex = RegExp(r'[أإآٱ]');

  /// Normalizes Arabic text by removing diacritics/tashkeel and unifying letter variants.
  static String normalize(String text) {
    if (text.isEmpty) return '';
    return text
        .replaceAll(_tashkeelRegex, '')
        .replaceAll(_alefRegex, 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .trim()
        .toLowerCase();
  }

  /// Returns true if [target] contains [query] using normalized matching.
  static bool matches(String target, String query) {
    if (query.isEmpty) return true;
    final normalizedTarget = normalize(target);
    final normalizedQuery = normalize(query);
    return normalizedTarget.contains(normalizedQuery);
  }
}
