import '../models/book_audio_models.dart';
import 'audio/ilm_audio_reciters.dart';
import 'audio/mutun_sharh_audio_entries.dart';
import 'audio/mutun_syllabus_audio_entries.dart';
import 'audio/turath_books_audio_entries.dart';
import 'audio/turath_fiqh_nahw_seerah_audio_entries.dart';
import 'audio/turath_sunnah_tafsir_audio_entries.dart';

export '../models/book_audio_models.dart';
export 'audio/haliba_audiobooks_catalog.dart'
    show HalibaAudiobookItem, HalibaAudiobooksCatalog;
export 'audio/ilm_audio_reciters.dart';

class MutunAudioCatalog {
  const MutunAudioCatalog._();

  static const String archiveBaseUrl = MutunSyllabusAudioEntries.archiveBaseUrl;
  static const String siniBaseUrl = MutunSyllabusAudioEntries.siniBaseUrl;

  static final Map<String, MutunAudioEntry> _allEntries = _buildAllEntries();

  static Map<String, MutunAudioEntry> _buildAllEntries() {
    final map = <String, MutunAudioEntry>{
      ...MutunSyllabusAudioEntries.canonicalEntries,
      ...TurathBooksAudioEntries.entries,
      ...TurathSunnahTafsirAudioEntries.entries,
      ...TurathFiqhNahwSeerahAudioEntries.entries,
    };
    MutunSharhAudioEntries.extraSharhSources.forEach((bookId, extraSources) {
      final existing = map[bookId];
      if (existing != null) {
        map[bookId] = existing.withExtraSources(extraSources);
      }
    });
    MutunSyllabusAudioEntries.aliases.forEach((aliasId, canonicalId) {
      final canonical = map[canonicalId];
      if (canonical != null) {
        map[aliasId] = canonical.withBookId(aliasId);
      }
    });
    TurathBooksAudioEntries.shamelaToSyllabusAliases.forEach((
      shamelaId,
      syllabusId,
    ) {
      final canonical = map[syllabusId];
      if (canonical != null) {
        final key = shamelaBookId(shamelaId);
        map[key] = canonical.withBookId(key);
      }
    });
    return Map<String, MutunAudioEntry>.unmodifiable(map);
  }

  /// All available audio recitation entries (syllabus mutun + Shamela heritage).
  static Map<String, MutunAudioEntry> get entries => _allEntries;

  /// Canonical audio catalog key for a Shamela heritage book ID.
  static String shamelaBookId(int shamelaId) =>
      TurathBooksAudioEntries.shamelaKey(shamelaId);

  /// Resolve alias IDs to their canonical entry if available.
  static String resolveBookId(String bookId) =>
      MutunSyllabusAudioEntries.aliases[bookId] ?? bookId;

  /// Resolve a Shamela book ID to its audio catalog key, or null if unavailable.
  static String? resolveShamelaAudioKey(int shamelaId) {
    final key = shamelaBookId(shamelaId);
    if (_allEntries.containsKey(key)) return key;
    return null;
  }

  /// Check whether authentic audio recitation is available for this Shamela book.
  static bool hasShamelaAudio(int shamelaId) =>
      resolveShamelaAudioKey(shamelaId) != null;

  /// Get audio recitation entry for a Shamela book ID.
  static MutunAudioEntry? getShamelaEntry(int shamelaId) {
    final key = resolveShamelaAudioKey(shamelaId);
    return key != null ? _allEntries[key] : null;
  }

  /// Check whether authentic audio recitation is available for this matn/book ID.
  static bool hasAudio(String bookId) =>
      _allEntries.containsKey(bookId) ||
      _allEntries.containsKey(resolveBookId(bookId));

  /// Get audio recitation entry.
  static MutunAudioEntry? getEntry(String bookId) =>
      _allEntries[bookId] ?? _allEntries[resolveBookId(bookId)];

  /// Get full audio source metadata for the specified book and reciter.
  static MatnAudioSource? getSource(String bookId, {String? reciterId}) =>
      getEntry(bookId)?.getSource(reciterId);

  /// Get chapter playlist for a multi-chapter audio source if available.
  static List<BookAudioChapter>? getChapters(
    String bookId, {
    String? reciterId,
  }) =>
      getSource(bookId, reciterId: reciterId)?.chapters;

  /// Get list of available reciters for a given book ID.
  static List<MutunReciter> getRecitersForBook(String? bookId) {
    if (bookId == null) {
      return const [
        MutunReciterDefaults.sini,
        MutunReciterDefaults.haliba,
        MutunReciterDefaults.shaydzmi,
        MutunReciterDefaults.fahad,
        MutunReciterDefaults.suwaid,
      ];
    }
    final entry = getEntry(bookId);
    if (entry == null || entry.sources.isEmpty) {
      return const [MutunReciterDefaults.sini];
    }
    return entry.sources.map((s) => s.reciter).toList();
  }

  /// Get primary streaming audio URL for the specified matn and reciter.
  static String? getAudioUrl(String bookId, {String? reciterId}) =>
      getSource(bookId, reciterId: reciterId)?.audioUrl;

  /// Get backup fallback URL in case of network or mirror failure.
  static String? getFallbackAudioUrl(String bookId, {String? reciterId}) =>
      getSource(bookId, reciterId: reciterId)?.fallbackUrl;

  /// Get total paragraphs / lines for reader synchronization.
  static int getTotalParagraphs(String bookId, {String? reciterId}) =>
      getSource(bookId, reciterId: reciterId)?.totalParagraphs ?? 1;

  /// Get precise paragraph timestamps in milliseconds if available.
  static List<int>? getParagraphTimestamps(String bookId, {String? reciterId}) =>
      getSource(bookId, reciterId: reciterId)?.paragraphTimestamps;
}
