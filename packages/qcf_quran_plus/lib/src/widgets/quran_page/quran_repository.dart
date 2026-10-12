import 'package:flutter/foundation.dart';
import '../../../qcf_quran_plus.dart';
import '../../services/get_page.dart';

/// Repository responsible for loading Quran page models and precomputing
/// the word offsets used to map ayahs across page and line layouts.
class QuranRepository {
  /// Private constructor to enforce singleton access.
  QuranRepository._();

  /// Shared singleton instance used across the application.
  static final QuranRepository instance = QuranRepository._();

  /// Cached Quran pages after the initialization completes.
  List<QuranPage>? _pages;

  /// Mapping structure keyed by page index, line index, and ayah identifier.
  Map<int, Map<int, Map<String, int>>>? _wordOffsets;

  /// Tracks an in-flight load so repeated initialization requests reuse the same work.
  Future<void>? _loadingFuture;

  /// Returns true once both the page collection and offset metadata are ready.
  bool get isReady => true;

  /// Exposes the loaded Quran pages.
  List<QuranPage> get pages {
    if (_pages == null) {
      final result = _loadAndComputeOffsets(604);
      _pages = result.pages;
      _wordOffsets = result.offsets;
    }
    return _pages!;
  }

  /// Exposes the computed word-offset metadata.
  Map<int, Map<int, Map<String, int>>> get wordOffsets {
    if (_wordOffsets == null) {
      final result = _loadAndComputeOffsets(604);
      _pages = result.pages;
      _wordOffsets = result.offsets;
    }
    return _wordOffsets!;
  }

  /// Ensures the repository has completed initialization.
  Future<void> ensureLoaded(int quranPagesCount) {
    if (_pages != null && _wordOffsets != null) return Future.value();
    return _loadingFuture ??= _load(quranPagesCount);
  }

  /// Loads the Quran data and stores the resulting page and offset maps.
  Future<void> _load(int quranPagesCount) async {
    final result = _loadAndComputeOffsets(quranPagesCount);
    _pages = result.pages;
    _wordOffsets = result.offsets;
  }

  /// Clears the repository state for tests and explicit reinitialization.
  @visibleForTesting
  void debugReset() {
    _pages = null;
    _wordOffsets = null;
    _loadingFuture = null;
  }
}

/// Represents the result produced by the background processing step.
class _LoadResult {
  /// The loaded Quran page models.
  final List<QuranPage> pages;

  /// Offset metadata keyed by page and line index.
  final Map<int, Map<int, Map<String, int>>> offsets;

  _LoadResult(this.pages, this.offsets);
}

/// Parses the Quran page dataset and computes the cumulative word offsets for each ayah.
///
/// The generated map enables precise tracking of where each ayah begins inside a
/// page and line, which supports accurate layout and text selection behavior.
_LoadResult _loadAndComputeOffsets(int count) {
  final processor = GetPage();
  processor.getQuran(count);
  final pages = processor.staticPages;

  final offsets = <int, Map<int, Map<String, int>>>{};
  final runningCounts = <String, int>{};
  final wordSplitRegex = RegExp(r'\s+');
  final digitsRegex = RegExp(r'^[\d٠-٩]+$');

  for (int p = 0; p < pages.length; p++) {
    final page = pages[p];
    final pageMap = <int, Map<String, int>>{};
    offsets[p] = pageMap;
    for (int l = 0; l < page.lines.length; l++) {
      final line = page.lines[l];
      final lineMap = <String, int>{};
      pageMap[l] = lineMap;
      for (final ayah in line.ayahs) {
        final key = '${ayah.surahNumber}-${ayah.ayahNumber}';
        final currentOffset = runningCounts[key] ?? 0;
        lineMap[key] = currentOffset;

        final ayaText = ayah.ayah.replaceAll('\n', ' ').trim();
        final wordCount = ayaText
            .split(wordSplitRegex)
            .where((w) => w.isNotEmpty && !digitsRegex.hasMatch(w))
            .length;

        runningCounts[key] = currentOffset + wordCount;
      }
    }
  }
  return _LoadResult(pages, offsets);
}
