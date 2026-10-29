enum MutunRepeatMode {
  none,
  singleParagraph,
  entireMatn,
}

/// Distinguishes full verbatim matn/book readings from abridged, versified,
/// or scholarly commentary editions in the reciter picker UI.
enum BookAudioEdition {
  fullText,
  mukhtasar,
  nadhm,
  sharhMajalis,
  sharh;

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
      case BookAudioEdition.sharh:
        return 'شرح علمي';
    }
  }

  bool get isSharh =>
      this == BookAudioEdition.sharh || this == BookAudioEdition.sharhMajalis;

  bool get isReading => !isSharh;
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
              '$baseUrl/${Uri.encodeComponent('$filePrefix${(startNumber + i).toString().padLeft(padWidth, '0')}$fileSuffix')}',
        ),
    ]);
  }

  /// Builds sequential tracks formatted as `<leadPad>-<middleToken>_<trailPad>.mp3`.
  static List<BookAudioChapter> dualNumbered({
    required String baseUrl,
    required int count,
    required String titlePrefix,
    required String middleToken,
    int leadPad = 4,
    int trailPad = 2,
    String fileSuffix = '.mp3',
  }) {
    return List<BookAudioChapter>.unmodifiable([
      for (int i = 1; i <= count; i++)
        BookAudioChapter(
          index: i,
          title: '$titlePrefix $i',
          audioUrl:
              '$baseUrl/${i.toString().padLeft(leadPad, '0')}-${middleToken}_${i.toString().padLeft(trailPad, '0')}$fileSuffix',
        ),
    ]);
  }

  /// Builds sequential chapter tracks from explicit exact filenames, safely
  /// encoding non-ASCII characters and `#`/`?` delimiters per segment.
  static List<BookAudioChapter> fromFiles({
    required String baseUrl,
    required List<({String file, String title})> items,
  }) {
    return List<BookAudioChapter>.unmodifiable([
      for (int i = 0; i < items.length; i++)
        BookAudioChapter(
          index: i + 1,
          title: items[i].title,
          audioUrl: '$baseUrl/${Uri.encodeComponent(items[i].file)}',
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
  /// If null, falls back to proportional scaling or estimation.
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
  bool get isSharh => edition.isSharh;
  bool get isReading => edition.isReading;
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

  List<MatnAudioSource> get readingSources =>
      sources.where((s) => s.isReading).toList(growable: false);

  List<MatnAudioSource> get sharhSources =>
      sources.where((s) => s.isSharh).toList(growable: false);

  bool get hasReading => sources.any((s) => s.isReading);
  bool get hasSharh => sources.any((s) => s.isSharh);

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

  MutunAudioEntry withExtraSources(List<MatnAudioSource> extra) {
    if (extra.isEmpty) return this;
    final merged = <MatnAudioSource>[...sources];
    for (final candidate in extra) {
      final exists = merged.any(
        (s) =>
            s.reciter.id == candidate.reciter.id &&
            s.audioUrl == candidate.audioUrl,
      );
      if (!exists) {
        merged.add(candidate);
      }
    }
    return MutunAudioEntry(
      bookId: bookId,
      title: title,
      sources: List<MatnAudioSource>.unmodifiable(merged),
    );
  }

  // Backwards compatibility properties
  String get siniAudioFileName => sources.first.audioUrl;
  String? get archiveFileName => null;
  String? get directUrl => sources.first.audioUrl;
  String? get fallbackUrl => sources.first.fallbackUrl;
  int get totalParagraphs => sources.first.totalParagraphs;
}
