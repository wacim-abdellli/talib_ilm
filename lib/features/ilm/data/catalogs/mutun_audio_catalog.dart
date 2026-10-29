import '../models/book_audio_models.dart';
import 'audio/ilm_audio_reciters.dart';
import 'audio/mutun_syllabus_audio_entries.dart';

export '../models/book_audio_models.dart';
export 'audio/ilm_audio_reciters.dart';

class MutunAudioCatalog {
  const MutunAudioCatalog._();

  static const String archiveBaseUrl = MutunSyllabusAudioEntries.archiveBaseUrl;
  static const String siniBaseUrl = MutunSyllabusAudioEntries.siniBaseUrl;

  static final Map<String, MutunAudioEntry> _allEntries = _buildAllEntries();

  static Map<String, MutunAudioEntry> _buildAllEntries() {
    final map = <String, MutunAudioEntry>{
      ...MutunSyllabusAudioEntries.canonicalEntries,
    };
    MutunSyllabusAudioEntries.aliases.forEach((aliasId, canonicalId) {
      final canonical = MutunSyllabusAudioEntries.canonicalEntries[canonicalId];
      if (canonical != null) {
        map[aliasId] = canonical.withBookId(aliasId);
      }
    });
    return Map<String, MutunAudioEntry>.unmodifiable(map);
  }

  /// All available audio recitation entries (including aliases).
  static Map<String, MutunAudioEntry> get entries => _allEntries;

  /// Resolve alias IDs to their canonical entry if available.
  static String resolveBookId(String bookId) =>
      MutunSyllabusAudioEntries.aliases[bookId] ?? bookId;

  /// Check whether authentic audio recitation is available for this matn ID.
  static bool hasAudio(String bookId) =>
      _allEntries.containsKey(bookId) ||
      _allEntries.containsKey(resolveBookId(bookId));

  /// Get audio recitation entry.
  static MutunAudioEntry? getEntry(String bookId) =>
      _allEntries[bookId] ?? _allEntries[resolveBookId(bookId)];

  /// Get list of available reciters for a given book ID.
  static List<MutunReciter> getRecitersForBook(String? bookId) {
    if (bookId == null) {
      return const [
        MutunReciterDefaults.sini,
        MutunReciterDefaults.fahad,
        MutunReciterDefaults.faqeeh,
        MutunReciterDefaults.shaydzmi,
      ];
    }
    final entry = getEntry(bookId);
    if (entry == null || entry.sources.isEmpty) {
      return const [MutunReciterDefaults.sini];
    }
    return entry.sources.map((s) => s.reciter).toList();
  }

  /// Get primary streaming audio URL for the specified matn and reciter.
  static String? getAudioUrl(String bookId, {String? reciterId}) {
    final entry = getEntry(bookId);
    if (entry == null) return null;
    return entry.getSource(reciterId)?.audioUrl;
  }

  /// Get backup fallback URL in case of network or mirror failure.
  static String? getFallbackAudioUrl(String bookId, {String? reciterId}) {
    final entry = getEntry(bookId);
    if (entry == null) return null;
    return entry.getSource(reciterId)?.fallbackUrl;
  }

  /// Get total paragraphs / lines for reader synchronization.
  static int getTotalParagraphs(String bookId, {String? reciterId}) {
    final entry = getEntry(bookId);
    if (entry == null) return 1;
    return entry.getSource(reciterId)?.totalParagraphs ?? 1;
  }

  /// Get precise paragraph timestamps in milliseconds if available.
  static List<int>? getParagraphTimestamps(String bookId, {String? reciterId}) {
    final entry = getEntry(bookId);
    if (entry == null) return null;
    return entry.getSource(reciterId)?.paragraphTimestamps;
  }
}
