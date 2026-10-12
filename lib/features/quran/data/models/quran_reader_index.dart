import 'package:quran/quran.dart' as quran;

/// Sealed hierarchy of items in the full-Quran continuous index.
sealed class QuranReaderIndexItem {
  const QuranReaderIndexItem();
}

/// Banner introducing a Surah.
class QuranReaderSurahHeaderItem extends QuranReaderIndexItem {
  final int surahNumber;
  const QuranReaderSurahHeaderItem(this.surahNumber);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuranReaderSurahHeaderItem && other.surahNumber == surahNumber;

  @override
  int get hashCode => surahNumber.hashCode;
}

/// Calligraphic Basmalah preceding a Surah's verses.
class QuranReaderBasmalahItem extends QuranReaderIndexItem {
  final int surahNumber;
  const QuranReaderBasmalahItem(this.surahNumber);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuranReaderBasmalahItem && other.surahNumber == surahNumber;

  @override
  int get hashCode => surahNumber.hashCode;
}

/// Section divider signaling the entry into a new Juz (30 parts).
class QuranReaderJuzHeaderItem extends QuranReaderIndexItem {
  final int juzNumber;
  final int surahNumber;
  final int ayahNumber;

  const QuranReaderJuzHeaderItem({
    required this.juzNumber,
    required this.surahNumber,
    required this.ayahNumber,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuranReaderJuzHeaderItem &&
          other.juzNumber == juzNumber &&
          other.surahNumber == surahNumber &&
          other.ayahNumber == ayahNumber;

  @override
  int get hashCode => Object.hash(juzNumber, surahNumber, ayahNumber);
}

/// Individual verse row in the continuous stream.
class QuranReaderAyahItem extends QuranReaderIndexItem {
  final int surahNumber;
  final int ayahNumber;
  final int pageNumber;
  final int juzNumber;

  const QuranReaderAyahItem({
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageNumber,
    required this.juzNumber,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuranReaderAyahItem &&
          other.surahNumber == surahNumber &&
          other.ayahNumber == ayahNumber;

  @override
  int get hashCode => Object.hash(surahNumber, ayahNumber);
}

/// Result of querying the reading position at an index.
class QuranPosition {
  final int surah;
  final int ayah;
  final int page;
  final int juz;

  const QuranPosition({
    required this.surah,
    required this.ayah,
    required this.page,
    required this.juz,
  });
}

/// Flattened, high-performance index spanning all 6,236 verses across 114 Surahs.
class QuranReaderIndex {
  final List<QuranReaderIndexItem> items;
  final Map<int, int> _surahHeaderIndices;
  final Map<int, Map<int, int>> _ayahIndices;
  final List<QuranReaderAyahItem> ayahItems;
  final List<double> _cumulativeOffsets;

  const QuranReaderIndex._({
    required this.items,
    required Map<int, int> surahHeaderIndices,
    required Map<int, Map<int, int>> ayahIndices,
    required this.ayahItems,
    required List<double> cumulativeOffsets,
  })  : _surahHeaderIndices = surahHeaderIndices,
        _ayahIndices = ayahIndices,
        _cumulativeOffsets = cumulativeOffsets;

  static QuranReaderIndex? _instance;

  /// Singleton cached instance for instant access throughout the app.
  static QuranReaderIndex get instance => _instance ??= build();

  /// Total count of elements (Surah headers, Basmalahs, Juz headers, Ayahs).
  int get length => items.length;

  /// Retrieves item at flat index.
  QuranReaderIndexItem operator [](int index) => items[index];

  /// Find flat list index for a specific verse.
  int? indexOfAyah(int surah, int ayah) {
    return _ayahIndices[surah]?[ayah];
  }

  /// Find flat list index for a Surah header.
  int? indexOfSurah(int surah) {
    return _surahHeaderIndices[surah];
  }

  /// Estimated cumulative scroll offset for item at [index].
  double offsetForIndex(int index) {
    if (index <= 0 || _cumulativeOffsets.isEmpty) return 0.0;
    if (index >= _cumulativeOffsets.length) {
      return _cumulativeOffsets.last;
    }
    return _cumulativeOffsets[index];
  }

  /// Estimated cumulative scroll offset for verse [surah]:[ayah].
  double? offsetForAyah(int surah, int ayah) {
    final idx = indexOfAyah(surah, ayah);
    if (idx == null) return null;
    return offsetForIndex(idx);
  }

  /// Estimated cumulative scroll offset for Surah [surah] header.
  double? offsetForSurah(int surah) {
    final idx = indexOfSurah(surah);
    if (idx == null) return null;
    return offsetForIndex(idx);
  }

  /// Binary search finding the item index visible at [offset].
  int indexForOffset(double offset) {
    if (offset <= 0 || _cumulativeOffsets.isEmpty) return 0;
    int low = 0;
    int high = _cumulativeOffsets.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (_cumulativeOffsets[mid] <= offset) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return high.clamp(0, _cumulativeOffsets.length - 1);
  }

  /// Resolve current reading position (surah, ayah, page, juz) at any given index.
  QuranPosition positionAt(int index) {
    if (index < 0 || index >= items.length) {
      return const QuranPosition(surah: 1, ayah: 1, page: 1, juz: 1);
    }

    final item = items[index];
    switch (item) {
      case QuranReaderAyahItem ayahItem:
        return QuranPosition(
          surah: ayahItem.surahNumber,
          ayah: ayahItem.ayahNumber,
          page: ayahItem.pageNumber,
          juz: ayahItem.juzNumber,
        );
      case QuranReaderSurahHeaderItem header:
        final page = quran.getPageNumber(header.surahNumber, 1);
        final juz = quran.getJuzNumber(header.surahNumber, 1);
        return QuranPosition(
          surah: header.surahNumber,
          ayah: 1,
          page: page,
          juz: juz,
        );
      case QuranReaderBasmalahItem basmalah:
        final page = quran.getPageNumber(basmalah.surahNumber, 1);
        final juz = quran.getJuzNumber(basmalah.surahNumber, 1);
        return QuranPosition(
          surah: basmalah.surahNumber,
          ayah: 1,
          page: page,
          juz: juz,
        );
      case QuranReaderJuzHeaderItem juzHeader:
        final page = quran.getPageNumber(juzHeader.surahNumber, juzHeader.ayahNumber);
        return QuranPosition(
          surah: juzHeader.surahNumber,
          ayah: juzHeader.ayahNumber,
          page: page,
          juz: juzHeader.juzNumber,
        );
    }
  }

  /// Construct the complete 604-page, 114-surah index.
  static QuranReaderIndex build() {
    final items = <QuranReaderIndexItem>[];
    final surahHeaderIndices = <int, int>{};
    final ayahIndices = <int, Map<int, int>>{};
    final ayahItems = <QuranReaderAyahItem>[];

    int currentJuz = 0;

    for (int surah = 1; surah <= quran.totalSurahCount; surah++) {
      final verseCount = quran.getVerseCount(surah);
      ayahIndices[surah] = <int, int>{};

      // Check if Juz starts at verse 1 of this surah
      final firstAyahJuz = quran.getJuzNumber(surah, 1);
      if (firstAyahJuz != currentJuz) {
        currentJuz = firstAyahJuz;
        items.add(QuranReaderJuzHeaderItem(
          juzNumber: currentJuz,
          surahNumber: surah,
          ayahNumber: 1,
        ));
      }

      // Surah Header
      surahHeaderIndices[surah] = items.length;
      items.add(QuranReaderSurahHeaderItem(surah));

      // Basmalah (all except Al-Fatihah (1) and At-Tawbah (9))
      if (surah != 1 && surah != 9) {
        items.add(QuranReaderBasmalahItem(surah));
      }

      // Verses
      for (int ayah = 1; ayah <= verseCount; ayah++) {
        // If mid-surah Juz boundary occurs (e.g. 2:142, 2:253)
        if (ayah > 1) {
          final ayahJuz = quran.getJuzNumber(surah, ayah);
          if (ayahJuz != currentJuz) {
            currentJuz = ayahJuz;
            items.add(QuranReaderJuzHeaderItem(
              juzNumber: currentJuz,
              surahNumber: surah,
              ayahNumber: ayah,
            ));
          }
        }

        final page = quran.getPageNumber(surah, ayah);
        final juz = quran.getJuzNumber(surah, ayah);
        final ayahItem = QuranReaderAyahItem(
          surahNumber: surah,
          ayahNumber: ayah,
          pageNumber: page,
          juzNumber: juz,
        );

        ayahIndices[surah]![ayah] = items.length;
        items.add(ayahItem);
        ayahItems.add(ayahItem);
      }
    }

    // Precompute cumulative estimated offsets for instant scrolling & position tracking
    final cumulativeOffsets = <double>[];
    double runningOffset = 0.0;
    for (final item in items) {
      cumulativeOffsets.add(runningOffset);
      switch (item) {
        case QuranReaderSurahHeaderItem():
          runningOffset += 130.0;
          break;
        case QuranReaderBasmalahItem():
          runningOffset += 64.0;
          break;
        case QuranReaderJuzHeaderItem():
          runningOffset += 60.0;
          break;
        case QuranReaderAyahItem ayahItem:
          final textLen = quran.getVerse(
            ayahItem.surahNumber,
            ayahItem.ayahNumber,
            verseEndSymbol: false,
          ).length;
          final lines = (textLen / 34.1).ceil().clamp(1, 50);
          runningOffset += 90.0 + lines * 32.9;
          break;
      }
    }

    return QuranReaderIndex._(
      items: List.unmodifiable(items),
      surahHeaderIndices: Map.unmodifiable(surahHeaderIndices),
      ayahIndices: Map.unmodifiable(ayahIndices),
      ayahItems: List.unmodifiable(ayahItems),
      cumulativeOffsets: List.unmodifiable(cumulativeOffsets),
    );
  }
}
