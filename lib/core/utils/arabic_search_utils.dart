/// Utility for resilient, diacritic-agnostic Arabic search and normalization.
class ArabicSearchUtils {
  ArabicSearchUtils._();

  static final RegExp _tashkeelRegex = RegExp(r'[\u064B-\u065F\u0670]');
  static final RegExp _alefRegex = RegExp(r'[أإآٱ]');

  /// Normalizes Arabic text by removing diacritics/tashkeel, unifying letter variants,
  /// and converting Eastern Arabic / Persian numerals to standard digits (0-9).
  static String normalize(String text) {
    if (text.isEmpty) return '';
    var result = text
        .replaceAll(_tashkeelRegex, '')
        .replaceAll('\u0640', '') // Tatweel / Kashida (ـ)
        .replaceAll(_alefRegex, 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');

    // Eastern Arabic numerals (٠-٩) and Persian numerals (۰-۹)
    const easternNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const persianNumerals = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(easternNumerals[i], i.toString());
      result = result.replaceAll(persianNumerals[i], i.toString());
    }

    return result.trim().toLowerCase();
  }

  /// Returns true if [target] contains [query] using normalized matching.
  /// Also checks without whitespace to handle attached queries like "100من".
  static bool matches(String target, String query) {
    if (query.isEmpty) return true;
    final normalizedTarget = normalize(target);
    final normalizedQuery = normalize(query);
    if (normalizedTarget.contains(normalizedQuery)) return true;

    // Resilient check removing all spaces (e.g. "100من عظماء" vs "100 من عظماء")
    final compactTarget = normalizedTarget.replaceAll(' ', '');
    final compactQuery = normalizedQuery.replaceAll(' ', '');
    return compactTarget.contains(compactQuery);
  }
}
