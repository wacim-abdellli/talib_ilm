import '../database/quran_pack_database.dart';

/// A logical row in the source edition's 15-line Mushaf page map.
class QuranPackPageLine {
  final List<QuranPackPageRun> runs;
  final int? surahHeaderNumber;
  final bool showBasmala;

  const QuranPackPageLine({
    this.runs = const [],
    this.surahHeaderNumber,
    this.showBasmala = false,
  });

  bool get isEmpty => runs.isEmpty && surahHeaderNumber == null && !showBasmala;
}

/// One continuous piece of source text, ending with its ayah marker if needed.
class QuranPackPageRun {
  final String text;
  final int ayahNumber;
  final bool endsAyah;

  const QuranPackPageRun({
    required this.text,
    required this.ayahNumber,
    required this.endsAyah,
  });
}

/// Maps complete source ayah strings onto their recorded 15-line page spans.
/// A verse that crosses a page break is split across the corresponding line
/// slots; its Arabic characters are retained and only line-boundary spacing is
/// normalized by the renderer.
class QuranPackPageLayout {
  QuranPackPageLayout._();

  static const int linesPerPage = 15;

  static List<QuranPackPageLine> build({
    required int pageNumber,
    required List<QuranPackAyah> ayahs,
  }) {
    final runsByLine = List<List<QuranPackPageRun>>.generate(
      linesPerPage,
      (_) => <QuranPackPageRun>[],
    );
    final surahHeaders = <int, int>{};
    final basmalas = <int>{};

    for (final ayah in ayahs) {
      if (pageNumber < ayah.firstPage || pageNumber > ayah.lastPage) continue;

      final pageFirstLine = pageNumber == ayah.firstPage ? ayah.firstLine : 1;
      final pageLastLine = pageNumber == ayah.lastPage
          ? ayah.lastLine
          : linesPerPage;
      if (pageFirstLine < 1 ||
          pageLastLine > linesPerPage ||
          pageLastLine < pageFirstLine) {
        continue;
      }

      final totalLineSlots =
          (ayah.lastPage - ayah.firstPage) * linesPerPage +
          ayah.lastLine -
          ayah.firstLine +
          1;
      final pageSlotOffset =
          (pageNumber - ayah.firstPage) * linesPerPage +
          pageFirstLine -
          ayah.firstLine;
      final matches = RegExp(r'\S+').allMatches(ayah.displayText).toList();
      if (matches.isEmpty || totalLineSlots <= 0) continue;

      for (var slot = 0; slot < pageLastLine - pageFirstLine + 1; slot++) {
        final globalSlot = pageSlotOffset + slot;
        final wordStart = globalSlot * matches.length ~/ totalLineSlots;
        final wordEnd = (globalSlot + 1) * matches.length ~/ totalLineSlots;
        final lineIndex = pageFirstLine + slot - 1;
        final lineText = wordEnd > wordStart
            ? ayah.displayText.substring(
                matches[wordStart].start,
                matches[wordEnd - 1].end,
              )
            : '';
        final isAyahEnd = globalSlot == totalLineSlots - 1;
        if (lineText.isNotEmpty || isAyahEnd) {
          runsByLine[lineIndex].add(
            QuranPackPageRun(
              text: lineText,
              ayahNumber: ayah.ayahNumber,
              endsAyah: isAyahEnd,
            ),
          );
        }
      }

      if (ayah.ayahNumber == 1 &&
          ayah.firstPage == pageNumber &&
          ayah.firstLine >= 3) {
        final headerIndex = ayah.firstLine - 3;
        final basmalaIndex = ayah.firstLine - 2;
        surahHeaders.putIfAbsent(headerIndex, () => ayah.surahNumber);
        if (ayah.surahNumber != 9) basmalas.add(basmalaIndex);
      }
    }

    return List.unmodifiable([
      for (var lineIndex = 0; lineIndex < linesPerPage; lineIndex++)
        QuranPackPageLine(
          runs: List.unmodifiable(runsByLine[lineIndex]),
          surahHeaderNumber: surahHeaders[lineIndex],
          showBasmala: basmalas.contains(lineIndex),
        ),
    ]);
  }
}
