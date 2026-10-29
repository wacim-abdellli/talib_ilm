enum MutunRepeatMode {
  none,
  singleParagraph,
  entireMatn,
}

/// Scholarly audio reciter profile linking syllabus mutun and classical
/// heritage books to verified high-quality streaming sources.
class MutunReciter {
  final String id;
  final String name;
  final String description;

  const MutunReciter({
    required this.id,
    required this.name,
    required this.description,
  });
}

class MatnAudioSource {
  final MutunReciter reciter;
  final String audioUrl;
  final String? fallbackUrl;
  final int totalParagraphs;

  /// Paragraph start times in milliseconds from the beginning of the audio.
  /// Index 0 = paragraph 1 start, index 1 = paragraph 2 start, etc.
  /// If null, falls back to proportional estimation.
  final List<int>? paragraphTimestamps;

  const MatnAudioSource({
    required this.reciter,
    required this.audioUrl,
    this.fallbackUrl,
    this.totalParagraphs = 1,
    this.paragraphTimestamps,
  });
}

class MutunAudioEntry {
  final String bookId;
  final String title;
  final List<MatnAudioSource> sources;

  const MutunAudioEntry({
    required this.bookId,
    required this.title,
    required this.sources,
  });

  MatnAudioSource? getSource([String? reciterId]) {
    if (sources.isEmpty) return null;
    if (reciterId == null) return sources.first;
    return sources.firstWhere(
      (s) => s.reciter.id == reciterId,
      orElse: () => sources.first,
    );
  }

  MutunAudioEntry withBookId(String aliasId) {
    if (aliasId == bookId) return this;
    return MutunAudioEntry(
      bookId: aliasId,
      title: title,
      sources: sources,
    );
  }

  // Backwards compatibility properties
  String get siniAudioFileName => sources.first.audioUrl;
  String? get archiveFileName => null;
  String? get directUrl => sources.first.audioUrl;
  String? get fallbackUrl => sources.first.fallbackUrl;
  int get totalParagraphs => sources.first.totalParagraphs;
}
