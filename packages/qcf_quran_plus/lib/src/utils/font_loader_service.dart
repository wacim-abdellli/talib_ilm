import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

enum FontStorageMode { permanentDisk, memoryOnly }

/// Manages lazy loading, registration, and variant generation for the Quran font set.
///
/// Each page is stored under a canonical family name and then cloned into alternate
/// variants such as dark mode, no-tajweed, and red-highlight styles. Fonts can be
/// cached on disk or kept in memory depending on the configured storage mode.
class QcfFontLoader {
  QcfFontLoader._();

  static final Map<int, Future<void>> _loadingTasks = {};
  static final Set<int> _loadedPages = {};
  static final Map<int, Future<Map<int, Uint8List>>> _chunkTasks = {};
  static final Map<int, Map<int, Uint8List>> _memoryChunkCache = {};

  static FontStorageMode _currentMode = FontStorageMode.permanentDisk;

  static const int totalPages = 604;
  static const int chunkSize = 20;
  static const int _chunkMagic = 0x51434631; // "QCF1"
  static const int _maxMemoryChunks = 2;

  static Directory? _fontDirCache;
  static int _generation = 0;

  /// Returns the base family name for the given Quran page.
  static String getBaseFontFamily(int pageNumber) {
    return 'QCF4${pageNumber.toString().padLeft(3, '0')}_COLOR-Regular';
  }

  /// Returns the light tajweed variant for the specified page.
  static String getTajweedLightFamily(int pageNumber) {
    return getBaseFontFamily(pageNumber);
  }

  /// Returns the dark tajweed variant for the specified page.
  static String getTajweedDarkFamily(int pageNumber) {
    return '${getBaseFontFamily(pageNumber)}-d';
  }

  /// Returns the light no-tajweed variant for the specified page.
  static String getNoTajweedLightFamily(int pageNumber) {
    return '${getBaseFontFamily(pageNumber)}-n';
  }

  /// Returns the dark no-tajweed variant for the specified page.
  static String getNoTajweedDarkFamily(int pageNumber) {
    return '${getBaseFontFamily(pageNumber)}-nd';
  }

  /// Returns the red-highlight variant for the specified page.
  static String getRedFamily(int pageNumber) {
    return '${getBaseFontFamily(pageNumber)}-nr';
  }

  /// Loads the configured font set during startup while reporting progress.
  ///
  /// If all pages already exist in the persistent font directory, the loader reuses
  /// them instead of re-extracting and writing them again. Otherwise, it loads the
  /// entire set sequentially so the UI can observe a meaningful progress callback.
  static Future<void> setupFontsAtStartup({
    required Function(double progress) onProgress,
    FontStorageMode mode = FontStorageMode.permanentDisk,
  }) async {
    _currentMode = mode;

    Directory? fontDir;

    if (_currentMode == FontStorageMode.permanentDisk) {
      fontDir = await _getFontDirectory();
    }

    int existingFontsCount = 0;

    if (fontDir != null) {
      const probeBatch = 64;

      for (int start = 1; start <= totalPages; start += probeBatch) {
        final end = (start + probeBatch - 1).clamp(1, totalPages);

        final checks = <Future<bool>>[];

        for (int page = start; page <= end; page++) {
          final file = File('${fontDir.path}/${getBaseFontFamily(page)}.ttf');

          checks.add(() async {
            if (!await file.exists()) {
              return false;
            }
            return await file.length() > 1000;
          }());
        }

        final results = await Future.wait(checks);

        existingFontsCount += results.where((e) => e).length;
      }
    }

    if (existingFontsCount == totalPages) {
      const batchSize = 25;

      for (int start = 1; start <= totalPages; start += batchSize) {
        final end = (start + batchSize - 1).clamp(1, totalPages);

        final tasks = <Future<void>>[];

        for (int page = start; page <= end; page++) {
          tasks.add(ensureFontLoaded(page));
        }

        await Future.wait(tasks);

        onProgress(end / totalPages);
      }
    } else {
      for (int page = 1; page <= totalPages; page++) {
        await ensureFontLoaded(page);
        onProgress(page / totalPages);
      }
    }
  }

  /// Returns the directory used for cached font files.
  static Future<Directory> _getFontDirectory() async {
    final cached = _fontDirCache;

    if (cached != null) {
      return cached;
    }

    final appDir = await getApplicationDocumentsDirectory();

    final fontDir = Directory('${appDir.path}/qcf_fonts');

    if (!await fontDir.exists()) {
      await fontDir.create(recursive: true);
    }

    _fontDirCache = fontDir;

    return fontDir;
  }

  /// Ensures a Quran page font is fully loaded and registered.
  ///
  /// If the page is already loaded or a task is already in progress, the existing
  /// future is reused to avoid duplicate registration work.
  static Future<void> ensureFontLoaded(int pageNumber) {
    if (pageNumber < 1 || pageNumber > totalPages) {
      return Future.error(RangeError('Invalid Quran page: $pageNumber'));
    }

    if (_loadedPages.contains(pageNumber)) {
      return Future.value();
    }

    final existingTask = _loadingTasks[pageNumber];

    if (existingTask != null) {
      return existingTask;
    }

    final task = _loadFontInternal(pageNumber);

    _loadingTasks[pageNumber] = task;

    task
        .then((_) {
          _loadedPages.add(pageNumber);
        })
        .catchError((_) {
          _loadedPages.add(pageNumber);
        })
        .whenComplete(() {
          _loadingTasks.remove(pageNumber);
        });

    return task;
  }

  /// Returns true when the requested Quran page font has already been registered.
  static bool isFontLoaded(int pageNumber) {
    return _loadedPages.contains(pageNumber);
  }

  /// Prefetches the current page and nearby pages for a smoother reading experience.
  ///
  /// The generation token guards against stale preloading calls when the user moves
  /// to another page while asynchronous loads are still running.
  static Future<void> preloadPages(int currentPage, {int radius = 5}) async {
    if (currentPage < 1) {
      currentPage = 1;
    }

    if (currentPage > totalPages) {
      currentPage = totalPages;
    }

    final myGeneration = ++_generation;

    await ensureFontLoaded(currentPage);

    if (myGeneration != _generation) {
      return;
    }

    final neighbors = <int>[];

    for (int i = 1; i <= radius; i++) {
      final next = currentPage + i;
      final previous = currentPage - i;

      if (next <= totalPages) {
        neighbors.add(next);
      }

      if (previous >= 1) {
        neighbors.add(previous);
      }
    }

    for (final page in neighbors) {
      if (myGeneration != _generation) {
        return;
      }

      if (_loadedPages.contains(page) || _loadingTasks.containsKey(page)) {
        continue;
      }

      await Future<void>.delayed(Duration.zero);

      if (myGeneration != _generation) {
        return;
      }

      await ensureFontLoaded(page);
    }
  }

  static final Set<String> _registeredFamilies = {};

  /// Loads and registers the authentic Medina Mushaf fonts for a single page.
  static Future<void> _loadFontInternal(int pageNumber) async {
    Uint8List? fontBytes;
    try {
      fontBytes = await _loadRawFontForPage(pageNumber);
    } catch (_) {
      fontBytes = null;
    }

    final rawBytes = fontBytes;
    if (rawBytes == null) return;

    // 1. Register authentic Light/Sepia Tajweed Medina font
    await _registerFont(rawBytes, getTajweedLightFamily(pageNumber));

    // 2. Register Dark Mode Tajweed Medina font
    final darkBytes = _modifyCpalBaseColor(
      Uint8List.fromList(rawBytes),
      const Color(0xFFFFFFFF),
    );
    await _registerFont(darkBytes, getTajweedDarkFamily(pageNumber));

    // 3. Register Non-Tajweed Light variant
    final noTajweedLightBytes = _modifyCpalAllColors(
      Uint8List.fromList(rawBytes),
      const Color(0xFF000000),
    );
    await _registerFont(
      noTajweedLightBytes,
      getNoTajweedLightFamily(pageNumber),
    );

    // 4. Register Non-Tajweed Dark Mode variant
    final noTajweedDarkBytes = _modifyCpalAllColors(
      Uint8List.fromList(rawBytes),
      const Color(0xFFFFFFFF),
    );
    await _registerFont(
      noTajweedDarkBytes,
      getNoTajweedDarkFamily(pageNumber),
    );

    // 5. Register Red highlight variant
    final redBytes = _modifyCpalAllColors(
      Uint8List.fromList(rawBytes),
      const Color(0xFFFF0000),
    );
    await _registerFont(redBytes, getRedFamily(pageNumber));
  }

  /// Registers non-tajweed font variants on demand when the user disables Tajweed.
  static Future<void> ensureNonTajweedLoaded(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > totalPages) return;
    final lightFam = getNoTajweedLightFamily(pageNumber);
    final darkFam = getNoTajweedDarkFamily(pageNumber);
    if (_registeredFamilies.contains(lightFam) &&
        _registeredFamilies.contains(darkFam)) {
      return;
    }

    final fontBytes = await _loadRawFontForPage(pageNumber);
    if (fontBytes == null) return;

    final noTajweedLightBytes = _modifyCpalAllColors(
      Uint8List.fromList(fontBytes),
      const Color(0xFF000000),
    );
    await _registerFont(noTajweedLightBytes, lightFam);

    final noTajweedDarkBytes = _modifyCpalAllColors(
      Uint8List.fromList(fontBytes),
      const Color(0xFFFFFFFF),
    );
    await _registerFont(noTajweedDarkBytes, darkFam);
  }

  /// Registers a font blob under the provided family name for Flutter text rendering.
  static Future<void> _registerFont(Uint8List fontBytes, String family) async {
    if (_registeredFamilies.contains(family)) return;
    try {
      final loader = FontLoader(family);
      final byteData = ByteData.view(
        fontBytes.buffer,
        fontBytes.offsetInBytes,
        fontBytes.lengthInBytes,
      );
      loader.addFont(Future<ByteData>.value(byteData));
      await loader.load();
      _registeredFamilies.add(family);
    } catch (_) {
      _registeredFamilies.add(family);
    }
  }

  /// Loads raw TrueType font bytes for [pageNumber] via disk cache, XZ chunk bundle,
  /// or legacy `.ttf.gz` fallback.
  static Future<Uint8List?> _loadRawFontForPage(int pageNumber) async {
    final fontName = getBaseFontFamily(pageNumber);
    Directory? diskDir;

    if (_currentMode == FontStorageMode.permanentDisk) {
      try {
        diskDir = await _getFontDirectory();
        final file = File('${diskDir.path}/$fontName.ttf');
        if (await file.exists() && await file.length() > 1000) {
          return await file.readAsBytes();
        }
      } catch (_) {
        diskDir = null;
      }
    }

    final chunkIdx = (pageNumber - 1) ~/ chunkSize;
    final cachedChunk = _memoryChunkCache[chunkIdx];
    if (cachedChunk != null && cachedChunk.containsKey(pageNumber)) {
      return cachedChunk[pageNumber];
    }

    try {
      final existingTask = _chunkTasks[chunkIdx];
      final Map<int, Uint8List> pagesMap;
      if (existingTask != null) {
        pagesMap = await existingTask;
      } else {
        final task = _extractChunkToMap(chunkIdx, diskDir?.path);
        _chunkTasks[chunkIdx] = task;
        try {
          pagesMap = await task;
        } finally {
          _chunkTasks.remove(chunkIdx);
        }
      }
      final bytes = pagesMap[pageNumber];
      if (bytes != null) {
        return bytes;
      }
    } catch (_) {
      // Fallback below to legacy single-page `.ttf.gz` if chunk asset is absent.
    }

    try {
      final gzipBytes = await _loadCompressedFont(fontName);
      final fontBytes = await Isolate.run(() {
        final extracted = _extractFont(gzipBytes);
        if (diskDir != null) {
          try {
            final file = File('${diskDir.path}/$fontName.ttf');
            file.parent.createSync(recursive: true);
            file.writeAsBytesSync(extracted, flush: true);
          } catch (_) {}
        }
        return extracted;
      });
      return fontBytes;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<int, Uint8List>> _extractChunkToMap(
    int chunkIdx,
    String? diskDirPath,
  ) async {
    final chunkId = chunkIdx.toString().padLeft(2, '0');
    final data = await rootBundle.load(
      'packages/qcf_quran_plus/assets/fonts/qcf_tajweed/qcf_chunk_$chunkId.bin.xz',
    );
    final xzBytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final pagesMap = await Isolate.run(
      () => _unpackChunkArchive(xzBytes, diskDirPath),
    );
    if (diskDirPath == null || _currentMode == FontStorageMode.memoryOnly) {
      if (_memoryChunkCache.length >= _maxMemoryChunks) {
        _memoryChunkCache.remove(_memoryChunkCache.keys.first);
      }
      _memoryChunkCache[chunkIdx] = pagesMap;
    }
    return pagesMap;
  }

  static Map<int, Uint8List> _unpackChunkArchive(
    Uint8List xzBytes,
    String? diskDirPath,
  ) {
    final raw = Uint8List.fromList(XZDecoder().decodeBytes(xzBytes));
    final bd = ByteData.sublistView(raw);
    if (raw.length < 8) {
      throw const FormatException('Corrupt QCF chunk header');
    }
    final magic = bd.getUint32(0, Endian.little);
    if (magic != _chunkMagic) {
      throw FormatException('Invalid QCF chunk magic: $magic');
    }
    final count = bd.getUint32(4, Endian.little);
    var offset = 8;
    final out = <int, Uint8List>{};

    if (diskDirPath != null) {
      try {
        Directory(diskDirPath).createSync(recursive: true);
      } catch (_) {}
    }

    for (int i = 0; i < count; i++) {
      if (offset + 8 > raw.length) {
        throw const FormatException('Truncated QCF chunk entry header');
      }
      final pageNum = bd.getUint32(offset, Endian.little);
      final byteLen = bd.getUint32(offset + 4, Endian.little);
      offset += 8;
      if (offset + byteLen > raw.length) {
        throw const FormatException('Truncated QCF chunk entry payload');
      }
      final fontData = raw.sublist(offset, offset + byteLen);
      offset += byteLen;
      out[pageNum] = fontData;

      if (diskDirPath != null) {
        try {
          final fontName =
              'QCF4${pageNum.toString().padLeft(3, '0')}_COLOR-Regular';
          final outFile = File('$diskDirPath/$fontName.ttf');
          if (!outFile.existsSync() || outFile.lengthSync() != byteLen) {
            outFile.writeAsBytesSync(fontData, flush: true);
          }
        } catch (_) {}
      }
    }
    return out;
  }

  /// Loads a legacy compressed font asset from the package bundle.
  static Future<Uint8List> _loadCompressedFont(String fontName) async {
    final data = await rootBundle.load(
      'packages/qcf_quran_plus/assets/fonts/qcf_tajweed/$fontName.ttf.gz',
    );
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  /// Decompresses a legacy GZip-compressed font payload to raw TrueType bytes.
  static Uint8List _extractFont(Uint8List gzipBytes) {
    final decompressed = const GZipDecoder().decodeBytes(gzipBytes);
    return Uint8List.fromList(decompressed);
  }

  /// Replaces dark base palette entries with the provided color while preserving the
  /// rest of the font data intact.
  static Uint8List _modifyCpalBaseColor(
    Uint8List fontBytes,
    Color newBaseColor,
  ) {
    if (fontBytes.length < 12) return fontBytes;

    final bd = ByteData.view(
      fontBytes.buffer,
      fontBytes.offsetInBytes,
      fontBytes.lengthInBytes,
    );
    final numTables = bd.getUint16(4);
    int? cpalOffset;
    int? cpalLength;
    const cpalTag = 0x4350414C;

    for (int i = 0; i < numTables; i++) {
      final recordOffset = 12 + i * 16;
      if (recordOffset + 16 > fontBytes.length) break;
      final tag = bd.getUint32(recordOffset);
      if (tag == cpalTag) {
        cpalOffset = bd.getUint32(recordOffset + 8);
        cpalLength = bd.getUint32(recordOffset + 12);
        break;
      }
    }

    if (cpalOffset == null || cpalLength == null) return fontBytes;
    if (cpalOffset + cpalLength > fontBytes.length) return fontBytes;
    if (cpalOffset + 12 > fontBytes.length) return fontBytes;

    final numColorRecords = bd.getUint16(cpalOffset + 6);
    final colorRecordsArrayOffset = bd.getUint32(cpalOffset + 8);
    final absoluteOffset = cpalOffset + colorRecordsArrayOffset;

    final newR = (newBaseColor.r * 255).round();
    final newG = (newBaseColor.g * 255).round();
    final newB = (newBaseColor.b * 255).round();
    final newA = (newBaseColor.a * 255).round();

    for (int i = 0; i < numColorRecords; i++) {
      final colorOffset = absoluteOffset + i * 4;
      if (colorOffset + 4 > fontBytes.length) break;

      final b = fontBytes[colorOffset];
      final g = fontBytes[colorOffset + 1];
      final r = fontBytes[colorOffset + 2];
      final a = fontBytes[colorOffset + 3];

      if (r <= 30 && g <= 30 && b <= 30 && a >= 200) {
        fontBytes[colorOffset] = newB;
        fontBytes[colorOffset + 1] = newG;
        fontBytes[colorOffset + 2] = newR;
        fontBytes[colorOffset + 3] = newA;
      }
    }

    return fontBytes;
  }

  /// Recolors all palette entries in the font to the provided color.
  static Uint8List _modifyCpalAllColors(Uint8List fontBytes, Color color) {
    if (fontBytes.length < 12) return fontBytes;

    final bd = ByteData.view(
      fontBytes.buffer,
      fontBytes.offsetInBytes,
      fontBytes.lengthInBytes,
    );
    final numTables = bd.getUint16(4);
    int? cpalOffset;
    int? cpalLength;
    const cpalTag = 0x4350414C;

    for (int i = 0; i < numTables; i++) {
      final recordOffset = 12 + i * 16;
      if (recordOffset + 16 > fontBytes.length) break;
      final tag = bd.getUint32(recordOffset);
      if (tag == cpalTag) {
        cpalOffset = bd.getUint32(recordOffset + 8);
        cpalLength = bd.getUint32(recordOffset + 12);
        break;
      }
    }

    if (cpalOffset == null || cpalLength == null) return fontBytes;
    if (cpalOffset + cpalLength > fontBytes.length) return fontBytes;
    if (cpalOffset + 12 > fontBytes.length) return fontBytes;

    final numColorRecords = bd.getUint16(cpalOffset + 6);
    final colorRecordsArrayOffset = bd.getUint32(cpalOffset + 8);
    final absoluteOffset = cpalOffset + colorRecordsArrayOffset;

    final newR = (color.r * 255).round();
    final newG = (color.g * 255).round();
    final newB = (color.b * 255).round();
    final newA = (color.a * 255).round();

    for (int i = 0; i < numColorRecords; i++) {
      final colorOffset = absoluteOffset + i * 4;
      if (colorOffset + 4 > fontBytes.length) break;

      fontBytes[colorOffset] = newB;
      fontBytes[colorOffset + 1] = newG;
      fontBytes[colorOffset + 2] = newR;
      fontBytes[colorOffset + 3] = newA;
    }

    return fontBytes;
  }

  /// Clears the in-memory and on-disk cache for all loaded fonts.
  static Future<void> clearCache() async {
    _generation++;

    if (_currentMode == FontStorageMode.permanentDisk) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fontDir = Directory('${appDir.path}/qcf_fonts');

        if (await fontDir.exists()) {
          await fontDir.delete(recursive: true);
        }
      } catch (_) {}
    }

    _fontDirCache = null;
    _loadedPages.clear();
    _loadingTasks.clear();
    _chunkTasks.clear();
    _memoryChunkCache.clear();
  }
}
