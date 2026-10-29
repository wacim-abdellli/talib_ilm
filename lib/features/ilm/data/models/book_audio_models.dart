enum MutunRepeatMode {
  none,
  singleParagraph,
  entireMatn,
}

/// Distinguishes full verbatim matn/book readings from abridged, versified,
/// or scholarly majlis editions in the reciter picker UI.
enum BookAudioEdition {
  fullText,
  mukhtasar,
  nadhm,
  sharhMajalis;

  String get label {
    switch (this) {
      case BookAudioEdition.fullText:
        return 'النص الكامل';
      case BookAudioEdition.mukhtasar:
        return 'قراءة المختصر';
      case BookAudioEdition.nadhm:
        return 'نظم المتن';
      case BookAudioEdition.sharhMajalis:
        return 'قراءة وشرح';
    }
  }
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

/// Individual chapter / مجلس / باب in a multi-part audio book or matn.
class BookAudioChapter {
  final int index;
  final String title;
  final String audioUrl;
  final String? fallbackUrl;

  const BookAudioChapter({
    required this.index,
    required this.title,
    required this.audioUrl,
    this.fallbackUrl,
  });

  /// Builds sequential chapter tracks from an ordered list of chapter titles.
  static List<BookAudioChapter> fromTitles({
    required String baseUrl,
    required List<String> titles,
    int startNumber = 1,
    int padWidth = 2,
    String filePrefix = '',
    String fileSuffix = '.mp3',
  }) {
    return List<BookAudioChapter>.unmodifiable([
      for (int i = 0; i < titles.length; i++)
        BookAudioChapter(
          index: i + 1,
          title: titles[i],
          audioUrl:
              '$baseUrl/$filePrefix${(startNumber + i).toString().padLeft(padWidth, '0')}$fileSuffix',
        ),
    ]);
  }

  /// Builds sequential numbered chapter tracks with optional named overrides.
  static List<BookAudioChapter> numbered({
    required String baseUrl,
    required int count,
    required String titlePrefix,
    int startNumber = 1,
    int padWidth = 2,
    String filePrefix = '',
    String fileSuffix = '.mp3',
    Map<int, String>? namedTitles,
  }) {
    return List<BookAudioChapter>.unmodifiable([
      for (int i = 0; i < count; i++)
        BookAudioChapter(
          index: i + 1,
          title: namedTitles?[i + 1] ?? '$titlePrefix ${i + 1}',
          audioUrl:
              '$baseUrl/$filePrefix${(startNumber + i).toString().padLeft(padWidth, '0')}$fileSuffix',
        ),
    ]);
  }
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

  final BookAudioEdition edition;
  final List<BookAudioChapter>? chapters;

  const MatnAudioSource({
    required this.reciter,
    required this.audioUrl,
    this.fallbackUrl,
    this.totalParagraphs = 1,
    this.paragraphTimestamps,
    this.edition = BookAudioEdition.fullText,
    this.chapters,
  });

  bool get isMultiChapter => chapters != null && chapters!.length > 1;
  int get chapterCount => chapters?.length ?? 1;
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
