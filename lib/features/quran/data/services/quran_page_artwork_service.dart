import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:brotli/brotli.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/quran_models.dart';

const int _maxExpandedPageBytes = 4 * 1024 * 1024;

/// Loads the original pinned King Fahd Complex Warsh/Qalun page vectors.
///
/// The page files are downloaded individually as they are first opened and
/// kept in the app's Quran pack directory. Users can also request all pages
/// from the riwayah download screen for complete offline reading.
class QuranPageArtworkService {
  QuranPageArtworkService._();

  static const String sourceRepository = 'quran-ws/quran-svg';
  static const String sourceCommit = 'b4155f07e4aea087d2c458069acff9f7c7e749f6';
  static const String _manifestAsset =
      'assets/data/quran/riwayah_page_art_manifest.json';
  static const int _maxCompressedPageBytes = 1024 * 1024;

  static http.Client? _client;
  static Future<_PageArtworkManifest>? _manifestFuture;
  static final Map<String, Future<String>> _loadedPages = {};
  static final Map<String, Future<List<int>>> _activePageDownloads = {};
  static final Set<QuranRiwayahId> _cancelledDownloads = {};
  static const int _maxMemoryCachedPages = 8;

  @visibleForTesting
  static Directory? testBaseDirectory;

  static Future<String> loadPage(QuranRiwayahId edition, int pageNumber) async {
    _validateEdition(edition);
    final key = '${edition.wireValue}:$pageNumber';
    final existing = _loadedPages[key];
    if (existing != null) {
      _loadedPages
        ..remove(key)
        ..[key] = existing;
      return existing;
    }

    final future = _loadPage(edition, pageNumber);
    _loadedPages[key] = future;
    while (_loadedPages.length > _maxMemoryCachedPages) {
      _loadedPages.remove(_loadedPages.keys.first);
    }
    try {
      return await future;
    } catch (_) {
      if (identical(_loadedPages[key], future)) _loadedPages.remove(key);
      rethrow;
    }
  }

  static Future<String> retryPage(
    QuranRiwayahId edition,
    int pageNumber,
  ) async {
    final key = '${edition.wireValue}:$pageNumber';
    _loadedPages.remove(key);
    return loadPage(edition, pageNumber);
  }

  static Future<String> _loadPage(
    QuranRiwayahId edition,
    int pageNumber,
  ) async {
    if (kIsWeb) {
      throw UnsupportedError('قراءة صفحات المصحف غير مدعومة على الويب');
    }
    final manifest = await _manifest();
    final source = manifest.page(edition, pageNumber);
    final file = await _pageFile(edition, pageNumber);
    var bytes = await _readValidFile(file, source);
    bytes ??= await _downloadPage(edition, source, file);
    return compute(_decodeAndValidateSvg, <String, Object>{
      'bytes': bytes,
      'sha1': source.gitBlobSha1,
    });
  }

  static Future<_PageArtworkManifest> _manifest() =>
      _manifestFuture ??= _loadManifest();

  static Future<_PageArtworkManifest> _loadManifest() async {
    final json = jsonDecode(await rootBundle.loadString(_manifestAsset));
    if (json is! Map<String, dynamic> || json['schemaVersion'] != 1) {
      throw const FormatException('بيانات صفحات المصحف غير صالحة');
    }
    final source = json['source'];
    final editions = json['editions'];
    if (source is! Map<String, dynamic> ||
        source['repository'] != sourceRepository ||
        source['commit'] != sourceCommit ||
        editions is! Map<String, dynamic>) {
      throw const FormatException('مصدر صفحات المصحف لا يطابق النسخة المثبتة');
    }
    return _PageArtworkManifest.fromJson(editions);
  }

  static Future<File> _pageFile(QuranRiwayahId edition, int pageNumber) async {
    final directory = await _artworkDirectory(edition);
    return File(
      p.join(directory.path, '${pageNumber.toString().padLeft(3, '0')}.svg.br'),
    );
  }

  static Future<Directory> _artworkDirectory(QuranRiwayahId edition) async {
    _validateEdition(edition);
    final base = testBaseDirectory ?? await getApplicationSupportDirectory();
    final directory = Directory(
      p.join(base.path, 'quran_packs', edition.wireValue, 'artwork'),
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  static Future<List<int>?> _readValidFile(
    File file,
    _PageArtworkSource source,
  ) async {
    if (!await file.exists()) return null;
    try {
      final bytes = await file.readAsBytes();
      if (_isValidCompressedPage(bytes, source)) return bytes;
    } catch (_) {}
    try {
      await file.delete();
    } catch (_) {}
    return null;
  }

  static Future<List<int>> _downloadPage(
    QuranRiwayahId edition,
    _PageArtworkSource source,
    File destination,
  ) {
    final key = '${edition.wireValue}:${source.pageNumber}';
    final active = _activePageDownloads[key];
    if (active != null) return active;
    final download = _downloadAndStorePage(edition, source, destination);
    _activePageDownloads[key] = download;
    return download.whenComplete(() {
      _activePageDownloads.remove(key);
    });
  }

  static Future<List<int>> _downloadAndStorePage(
    QuranRiwayahId edition,
    _PageArtworkSource source,
    File destination,
  ) async {
    final urls = _sourceUrls(edition, source.pageNumber);
    Object? lastError;
    for (final url in urls) {
      try {
        final response = await (_client ??= http.Client())
            .get(Uri.parse(url))
            .timeout(
              const Duration(seconds: 18), // ui-lint: allow network timeout
            );
        if (response.statusCode != HttpStatus.ok) {
          throw HttpException(
            'HTTP ${response.statusCode}',
            uri: Uri.parse(url),
          );
        }
        final bytes = response.bodyBytes;
        if (!_isValidCompressedPage(bytes, source)) {
          throw const FormatException('تعذر التحقق من سلامة صفحة المصحف');
        }
        await _writeAtomically(destination, bytes);
        return bytes;
      } catch (error) {
        lastError = error;
      }
    }
    throw StateError(
      'تعذر تنزيل صفحة المصحف. تحقق من الاتصال، ثم أعد المحاولة. ${lastError ?? ''}',
    );
  }

  static List<String> _sourceUrls(QuranRiwayahId edition, int pageNumber) {
    final sourceEdition = edition == QuranRiwayahId.qalun ? 'qalon' : 'warsh';
    final path =
        'mushafs/$sourceEdition/kfqc/svg-br/${pageNumber.toString().padLeft(3, '0')}.svg.br';
    return [
      'https://raw.githubusercontent.com/$sourceRepository/$sourceCommit/$path',
      'https://cdn.jsdelivr.net/gh/$sourceRepository@$sourceCommit/$path',
    ];
  }

  static bool _isValidCompressedPage(
    List<int> bytes,
    _PageArtworkSource source,
  ) =>
      bytes.length == source.compressedBytes &&
      bytes.length <= _maxCompressedPageBytes &&
      _gitBlobSha1(bytes) == source.gitBlobSha1;

  static String _gitBlobSha1(List<int> bytes) {
    final header = utf8.encode('blob ${bytes.length}\u0000');
    return sha1.convert(<int>[...header, ...bytes]).toString();
  }

  static Future<void> _writeAtomically(
    File destination,
    List<int> bytes,
  ) async {
    final temporary = File('${destination.path}.partial');
    if (await temporary.exists()) await temporary.delete();
    await temporary.writeAsBytes(bytes, flush: true);
    if (await destination.exists()) await destination.delete();
    await temporary.rename(destination.path);
  }

  static Future<ArtworkStorageStatus> storageStatus(
    QuranRiwayahId edition,
  ) async {
    _validateEdition(edition);
    final manifest = await _manifest();
    final pages = manifest.edition(edition).pages;
    var downloadedPages = 0;
    var bytesOnDisk = 0;
    final directory = await _artworkDirectory(edition);
    for (final source in pages) {
      final file = File(
        p.join(
          directory.path,
          '${source.pageNumber.toString().padLeft(3, '0')}.svg.br',
        ),
      );
      if (!await file.exists()) continue;
      final length = await file.length();
      if (length != source.compressedBytes) continue;
      downloadedPages++;
      bytesOnDisk += length;
    }
    return ArtworkStorageStatus(
      downloadedPages: downloadedPages,
      totalPages: pages.length,
      bytesOnDisk: bytesOnDisk,
      totalBytes: manifest.edition(edition).compressedBytes,
    );
  }

  static Future<void> deleteArtwork(QuranRiwayahId edition) async {
    _validateEdition(edition);
    final directory = await _artworkDirectory(edition);
    if (await directory.exists()) await directory.delete(recursive: true);
    _loadedPages.removeWhere(
      (key, _) => key.startsWith('${edition.wireValue}:'),
    );
  }

  static Stream<ArtworkDownloadProgress> downloadAll(
    QuranRiwayahId edition,
  ) async* {
    _validateEdition(edition);
    _cancelledDownloads.remove(edition);
    final manifest = await _manifest();
    final editionManifest = manifest.edition(edition);
    var completedPages = 0;
    var completedBytes = 0;
    yield ArtworkDownloadProgress(
      edition: edition,
      completedPages: 0,
      totalPages: editionManifest.pages.length,
      completedBytes: 0,
      totalBytes: editionManifest.compressedBytes,
      status: 'جارٍ تجهيز صفحات المصحف الأصلية',
    );

    for (var start = 0; start < editionManifest.pages.length; start += 4) {
      if (_cancelledDownloads.contains(edition)) break;
      final batch = editionManifest.pages.skip(start).take(4).toList();
      try {
        final results = await Future.wait<int>([
          for (final source in batch) _ensureCompressedPage(edition, source),
        ]);
        completedPages += batch.length;
        completedBytes += results.fold<int>(0, (sum, size) => sum + size);
        yield ArtworkDownloadProgress(
          edition: edition,
          completedPages: completedPages,
          totalPages: editionManifest.pages.length,
          completedBytes: completedBytes,
          totalBytes: editionManifest.compressedBytes,
          status:
              'تنزيل الصفحات الأصلية: $completedPages من ${editionManifest.pages.length}',
        );
      } catch (error) {
        yield ArtworkDownloadProgress(
          edition: edition,
          completedPages: completedPages,
          totalPages: editionManifest.pages.length,
          completedBytes: completedBytes,
          totalBytes: editionManifest.compressedBytes,
          status: 'تعذر إكمال التنزيل؛ يمكنك المتابعة من حيث توقف. $error',
          isError: true,
        );
        return;
      }
    }

    final canceled = _cancelledDownloads.remove(edition);
    yield ArtworkDownloadProgress(
      edition: edition,
      completedPages: completedPages,
      totalPages: editionManifest.pages.length,
      completedBytes: completedBytes,
      totalBytes: editionManifest.compressedBytes,
      status: canceled
          ? 'أُلغي التنزيل؛ يمكن استكماله لاحقاً'
          : 'اكتمل تنزيل صفحات المصحف الأصلية',
      isComplete: !canceled,
      isCanceled: canceled,
    );
  }

  static Future<int> _ensureCompressedPage(
    QuranRiwayahId edition,
    _PageArtworkSource source,
  ) async {
    if (_cancelledDownloads.contains(edition)) return 0;
    final file = await _pageFile(edition, source.pageNumber);
    final cached = await _readValidFile(file, source);
    if (cached != null) return cached.length;
    final bytes = await _downloadPage(edition, source, file);
    return bytes.length;
  }

  static void cancelDownload(QuranRiwayahId edition) {
    _cancelledDownloads.add(edition);
  }

  static void _validateEdition(QuranRiwayahId edition) {
    if (edition != QuranRiwayahId.warsh && edition != QuranRiwayahId.qalun) {
      throw ArgumentError.value(
        edition,
        'edition',
        'Only Warsh and Qalun artwork is available',
      );
    }
  }
}

String _decodeAndValidateSvg(Map<String, Object> request) {
  final bytes = request['bytes']! as List<int>;
  final expectedSha1 = request['sha1']! as String;
  final header = utf8.encode('blob ${bytes.length}\u0000');
  if (sha1.convert(<int>[...header, ...bytes]).toString() != expectedSha1) {
    throw const FormatException('ملف صفحة المصحف تالف');
  }
  final expanded = brotliDecode(bytes);
  if (expanded.length > _maxExpandedPageBytes) {
    throw const FormatException('حجم صفحة المصحف بعد فك الضغط غير صالح');
  }
  final svg = utf8.decode(expanded);
  final dangerousLink = RegExp(
    r"""(?:href|xlink:href)\s*=\s*["'](?!#|data:)""",
    caseSensitive: false,
  );
  if (!RegExp(r'<svg\b').hasMatch(svg) ||
      RegExp(r'<script\b', caseSensitive: false).hasMatch(svg) ||
      dangerousLink.hasMatch(svg)) {
    throw const FormatException('صيغة صفحة المصحف غير آمنة أو غير صالحة');
  }
  return svg;
}

class ArtworkStorageStatus {
  final int downloadedPages;
  final int totalPages;
  final int bytesOnDisk;
  final int totalBytes;

  const ArtworkStorageStatus({
    required this.downloadedPages,
    required this.totalPages,
    required this.bytesOnDisk,
    required this.totalBytes,
  });

  bool get isComplete => downloadedPages == totalPages;
}

class ArtworkDownloadProgress {
  final QuranRiwayahId edition;
  final int completedPages;
  final int totalPages;
  final int completedBytes;
  final int totalBytes;
  final String status;
  final bool isError;
  final bool isComplete;
  final bool isCanceled;

  const ArtworkDownloadProgress({
    required this.edition,
    required this.completedPages,
    required this.totalPages,
    required this.completedBytes,
    required this.totalBytes,
    required this.status,
    this.isError = false,
    this.isComplete = false,
    this.isCanceled = false,
  });

  double get progress => totalPages == 0 ? 0 : completedPages / totalPages;
}

class _PageArtworkManifest {
  final Map<QuranRiwayahId, _PageArtworkEdition> editions;

  const _PageArtworkManifest(this.editions);

  factory _PageArtworkManifest.fromJson(Map<String, dynamic> json) {
    final editions = <QuranRiwayahId, _PageArtworkEdition>{};
    for (final edition in [QuranRiwayahId.warsh, QuranRiwayahId.qalun]) {
      final value = json[edition.wireValue];
      if (value is! Map<String, dynamic>) {
        throw const FormatException('إحدى روايات المصحف غير موجودة في الفهرس');
      }
      final expectedSourceEdition = edition == QuranRiwayahId.qalun
          ? 'qalon'
          : 'warsh';
      final parsed = _PageArtworkEdition.fromJson(
        value,
        expectedSourceEdition: expectedSourceEdition,
      );
      if (parsed.pages.length != 604 ||
          parsed.compressedBytes !=
              parsed.pages.fold<int>(
                0,
                (sum, page) => sum + page.compressedBytes,
              )) {
        throw const FormatException('عدد صفحات المصحف في الفهرس غير صحيح');
      }
      editions[edition] = parsed;
    }
    return _PageArtworkManifest(Map.unmodifiable(editions));
  }

  _PageArtworkEdition edition(QuranRiwayahId edition) => editions[edition]!;

  _PageArtworkSource page(QuranRiwayahId edition, int pageNumber) {
    final pages = this.edition(edition).pages;
    if (pageNumber < 1 || pageNumber > pages.length) {
      throw RangeError.range(pageNumber, 1, pages.length, 'pageNumber');
    }
    return pages[pageNumber - 1];
  }
}

class _PageArtworkEdition {
  final int compressedBytes;
  final List<_PageArtworkSource> pages;

  const _PageArtworkEdition({
    required this.compressedBytes,
    required this.pages,
  });

  factory _PageArtworkEdition.fromJson(
    Map<String, dynamic> json, {
    required String expectedSourceEdition,
  }) {
    final sourceEdition = json['sourceEdition'];
    final rawPages = json['pages'];
    if (sourceEdition != expectedSourceEdition || rawPages is! List) {
      throw const FormatException('مصدر صفحات الرواية غير صالح');
    }
    final pages = rawPages
        .map((page) => _PageArtworkSource.fromJson(page))
        .toList(growable: false);
    for (var index = 0; index < pages.length; index++) {
      if (pages[index].pageNumber != index + 1) {
        throw const FormatException('ترتيب صفحات المصحف غير صحيح');
      }
    }
    return _PageArtworkEdition(
      compressedBytes: json['compressedBytes'] as int,
      pages: List.unmodifiable(pages),
    );
  }
}

class _PageArtworkSource {
  final int pageNumber;
  final int compressedBytes;
  final String gitBlobSha1;

  const _PageArtworkSource({
    required this.pageNumber,
    required this.compressedBytes,
    required this.gitBlobSha1,
  });

  factory _PageArtworkSource.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('سجل صفحة المصحف غير صالح');
    }
    final page = json['page'];
    final bytes = json['bytes'];
    final sha = json['gitBlobSha1'];
    if (page is! int ||
        bytes is! int ||
        bytes < 1 ||
        bytes > 1024 * 1024 ||
        sha is! String ||
        !RegExp(r'^[0-9a-f]{40}$').hasMatch(sha)) {
      throw const FormatException('بيانات سلامة صفحة المصحف غير صالحة');
    }
    return _PageArtworkSource(
      pageNumber: page,
      compressedBytes: bytes,
      gitBlobSha1: sha,
    );
  }
}
