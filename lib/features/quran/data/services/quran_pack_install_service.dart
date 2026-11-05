import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/utils/arabic_search_utils.dart';
import '../database/quran_pack_database.dart';
import '../models/quran_models.dart';

/// Installs immutable, app-pinned riwayah sources from the user-selected
/// community mirror. The compiled SHA-256 pins authenticate the exact source
/// bytes for this app version; catalog updates therefore require an app update.
/// This service does not claim independent verification against KFGQPC archives.
class QuranPackInstallService {
  static const String _downloadedKey = 'quran_installed_packs_v1';
  static const int _maxSourceBytes = 16 * 1024 * 1024;
  static const String sourceCommit = '281dbbe8eed1370daa5a023b6cd81655cbfd6473';
  static const String _sourceRepositoryPath = 'thetruetruth/quran-data-kfgqpc';
  static const String sourceRepository =
      'https://github.com/$_sourceRepositoryPath';

  static http.Client? _injectedClient;
  static http.Client? _defaultClient;
  static final Map<QuranRiwayahId, Completer<void>> _active = {};

  /// Test-only root override. Installed packs live outside the app bundle.
  @visibleForTesting
  static Directory? testBaseDir;

  @visibleForTesting
  static void setHttpClient(http.Client client) {
    _injectedClient = client;
  }

  @visibleForTesting
  static void resetForTesting() {
    _injectedClient?.close();
    _injectedClient = null;
    _defaultClient?.close();
    _defaultClient = null;
    _active.clear();
    testBaseDir = null;
  }

  static http.Client get _client =>
      _injectedClient ?? (_defaultClient ??= http.Client());

  static Map<String, dynamic> sourcePin(QuranRiwayahId edition) =>
      Map.unmodifiable(_sourcePins[edition]!);

  @visibleForTesting
  static List<String> sourceUrlsForTesting(
    QuranRiwayahId edition,
    String assetKind,
  ) {
    final asset = _sourcePins[edition]![assetKind] as Map<String, dynamic>?;
    if (asset == null) throw ArgumentError.value(assetKind, 'assetKind');
    return List.unmodifiable(_sourceUrls(asset['url'] as String));
  }

  static List<String> _sourceUrls(String primaryUrl) {
    final prefix =
        'https://raw.githubusercontent.com/$_sourceRepositoryPath/$sourceCommit/';
    if (!primaryUrl.startsWith(prefix)) return [primaryUrl];
    final path = primaryUrl.substring(prefix.length);
    final fallback =
        'https://cdn.jsdelivr.net/gh/$_sourceRepositoryPath@$sourceCommit/$path';
    return [primaryUrl, fallback];
  }

  /// Fetches and validates both pinned files, builds an edition-scoped SQLite
  /// database in a staging directory, checks it through the runtime reader,
  /// then atomically replaces the installed edition directory.
  static Stream<QuranPackInstallProgress> install(
    QuranRiwayahId edition,
  ) async* {
    if (kIsWeb) {
      yield QuranPackInstallProgress.failed(
        edition,
        'تنزيل المصحف غير مدعوم على الويب',
      );
      return;
    }
    if (_active.containsKey(edition)) {
      yield QuranPackInstallProgress.failed(
        edition,
        'التحميل قيد التنفيذ بالفعل',
      );
      return;
    }

    final abort = Completer<void>();
    _active[edition] = abort;
    Directory? staging;
    try {
      yield QuranPackInstallProgress(edition, 0, 'جارٍ تجهيز تنزيل الرواية');
      final root = await _packsDirectory();
      await _recoverInstalledDirectory(root, edition);
      staging = Directory(
        p.join(
          root.path,
          '.${edition.wireValue}.staging-${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      await staging.create(recursive: true);

      final pin = _sourcePins[edition]!;
      final assets = <_PinnedAsset>[
        _PinnedAsset.fromJson(pin['data'] as Map<String, dynamic>, 'data'),
        _PinnedAsset.fromJson(pin['font'] as Map<String, dynamic>, 'font'),
      ];
      final totalBytes = assets.fold<int>(0, (sum, asset) => sum + asset.bytes);
      var completedBytes = 0;

      for (final asset in assets) {
        final destination = File(p.join(staging.path, asset.filename));
        if (asset.bytes > _maxSourceBytes) {
          throw const FormatException('حجم الملف يتجاوز الحد المسموح');
        }

        final urls = _sourceUrls(asset.url);
        for (var sourceIndex = 0; sourceIndex < urls.length; sourceIndex++) {
          if (abort.isCompleted) throw StateError('download aborted');
          final url = urls[sourceIndex];
          try {
            final request = http.AbortableRequest(
              'GET',
              Uri.parse(url),
              abortTrigger: abort.future,
            );
            final response = await _client
                .send(request)
                .timeout(const Duration(minutes: 2));
            if (response.statusCode != HttpStatus.ok) {
              throw HttpException(
                'تعذر تنزيل ملف الرواية (${response.statusCode})',
                uri: request.url,
              );
            }
            if (response.contentLength != null &&
                response.contentLength! != asset.bytes) {
              throw const FormatException('حجم الملف لا يطابق البصمة المثبتة');
            }

            final sink = destination.openWrite();
            var receivedBytes = 0;
            var lastReportedBytes = 0;
            try {
              await for (final chunk in response.stream.timeout(
                const Duration(minutes: 2),
              )) {
                receivedBytes += chunk.length;
                if (receivedBytes > asset.bytes ||
                    receivedBytes > _maxSourceBytes) {
                  throw const FormatException('حجم الملف يتجاوز الحجم المتوقع');
                }
                sink.add(chunk);
                if (receivedBytes - lastReportedBytes >= 128 * 1024 ||
                    receivedBytes == asset.bytes) {
                  lastReportedBytes = receivedBytes;
                  final fraction =
                      (completedBytes + receivedBytes) / totalBytes;
                  yield QuranPackInstallProgress(
                    edition,
                    fraction.clamp(0.02, 0.92),
                    sourceIndex == 0
                        ? asset.kind == 'data'
                              ? 'جارٍ تنزيل بيانات المصحف'
                              : 'جارٍ تنزيل خط الرواية'
                        : 'جارٍ التنزيل من مصدر احتياطي',
                    receivedBytes: completedBytes + receivedBytes,
                    totalBytes: totalBytes,
                  );
                }
              }
              await sink.flush();
            } finally {
              await sink.close();
            }
            if (receivedBytes != asset.bytes) {
              throw const FormatException('اكتمل تنزيل ملف بحجم غير متوقع');
            }
            final digest = await _sha256File(destination);
            if (digest != asset.sha256) {
              throw FormatException('فشل التحقق من سلامة ملف ${asset.kind}');
            }
            completedBytes += receivedBytes;
            break;
          } on Object catch (error) {
            if (await destination.exists()) {
              try {
                await destination.delete();
              } catch (_) {}
            }
            if (abort.isCompleted || sourceIndex == urls.length - 1) {
              rethrow;
            }
            debugPrint(
              'Quran pack ${edition.wireValue} ${asset.kind} source '
              '${sourceIndex + 1} failed; trying pinned CDN: $error',
            );
            yield QuranPackInstallProgress(
              edition,
              completedBytes / totalBytes,
              'المصدر الأول غير متاح؛ جارٍ المحاولة بمصدر احتياطي',
              receivedBytes: completedBytes,
              totalBytes: totalBytes,
            );
          }
        }
      }

      if (abort.isCompleted) throw StateError('download aborted');
      yield QuranPackInstallProgress(
        edition,
        0.94,
        'جارٍ التحقق من الآيات وبناء قاعدة البيانات',
        receivedBytes: totalBytes,
        totalBytes: totalBytes,
      );
      final dataAsset = assets.firstWhere((asset) => asset.kind == 'data');
      final fontAsset = assets.firstWhere((asset) => asset.kind == 'font');
      final rows = await _readAndValidateSource(
        File(p.join(staging.path, dataAsset.filename)),
        edition,
      );
      final databaseFile = File(p.join(staging.path, 'quran.sqlite'));
      await _buildDatabase(databaseFile, edition, rows, pin);
      if (abort.isCompleted) throw StateError('download aborted');
      await File(p.join(staging.path, dataAsset.filename)).delete();
      await File(
        p.join(staging.path, fontAsset.filename),
      ).rename(p.join(staging.path, 'riwayah.ttf'));

      final opened = await QuranPackDatabase.open(
        databasePath: databaseFile.path,
        editionId: edition,
      );
      await opened.close();
      final installedMetadata = <String, Object>{
        'editionId': edition.wireValue,
        'schemaVersion': QuranPackDatabase.supportedSchemaVersion,
        'sourceRepository': sourceRepository,
        'sourceCommit': sourceCommit,
        'dataVersion': pin['dataVersion'] as String,
        'dataSha256': dataAsset.sha256,
        'fontSha256': fontAsset.sha256,
        'installedAt': DateTime.now().toUtc().toIso8601String(),
      };
      await File(
        p.join(staging.path, 'installed.json'),
      ).writeAsString(jsonEncode(installedMetadata), flush: true);

      final installedDirectory = Directory(
        p.join(root.path, edition.wireValue),
      );
      final backupDirectory = Directory(
        p.join(root.path, '.${edition.wireValue}.backup'),
      );
      if (abort.isCompleted) throw StateError('download aborted');
      if (await backupDirectory.exists()) {
        await backupDirectory.delete(recursive: true);
      }
      final hadPrevious = await installedDirectory.exists();
      if (hadPrevious) await installedDirectory.rename(backupDirectory.path);
      try {
        await staging.rename(installedDirectory.path);
        staging = null;
      } catch (_) {
        if (hadPrevious && await backupDirectory.exists()) {
          await backupDirectory.rename(installedDirectory.path);
        }
        rethrow;
      }
      if (await backupDirectory.exists()) {
        try {
          await backupDirectory.delete(recursive: true);
        } catch (_) {
          // The new pack is already active; startup recovery cleans this backup.
        }
      }

      try {
        final preferences = await SharedPreferences.getInstance();
        final installed = preferences.getStringList(_downloadedKey) ?? [];
        if (!installed.contains(edition.wireValue)) {
          installed.add(edition.wireValue);
          await preferences.setStringList(_downloadedKey, installed);
        }
      } catch (_) {
        // Installed state is verified from the pack itself; preferences are a cache.
      }
      yield QuranPackInstallProgress(
        edition,
        1,
        'اكتمل التثبيت، ويمكن قراءة الرواية دون إنترنت',
        receivedBytes: totalBytes,
        totalBytes: totalBytes,
        isComplete: true,
      );
    } on Object catch (error) {
      debugPrint('Quran pack install failed (${edition.wireValue}): $error');
      if (staging != null && await staging.exists()) {
        try {
          await staging.delete(recursive: true);
        } catch (_) {}
      }
      yield QuranPackInstallProgress.failed(
        edition,
        _installErrorMessage(error),
      );
    } finally {
      if (!abort.isCompleted) abort.complete();
      _active.remove(edition);
    }
  }

  static bool cancel(QuranRiwayahId edition) {
    final active = _active[edition];
    if (active == null || active.isCompleted) return false;
    active.complete();
    return true;
  }

  static Future<bool> isInstalled(QuranRiwayahId edition) async {
    try {
      final root = await _packsDirectory();
      await _recoverInstalledDirectory(root, edition);
      final directory = Directory(p.join(root.path, edition.wireValue));
      final databaseFile = File(p.join(directory.path, 'quran.sqlite'));
      final fontFile = File(p.join(directory.path, 'riwayah.ttf'));
      final metadataFile = File(p.join(directory.path, 'installed.json'));
      if (!await databaseFile.exists() ||
          !await fontFile.exists() ||
          !await metadataFile.exists()) {
        return false;
      }
      final metadata = jsonDecode(await metadataFile.readAsString());
      if (metadata is! Map<String, dynamic> ||
          metadata['editionId'] != edition.wireValue ||
          metadata['sourceCommit'] != sourceCommit ||
          metadata['dataSha256'] !=
              (_sourcePins[edition]!['data']
                  as Map<String, dynamic>)['sha256'] ||
          metadata['fontSha256'] !=
              (_sourcePins[edition]!['font']
                  as Map<String, dynamic>)['sha256'] ||
          await _sha256File(fontFile) != metadata['fontSha256']) {
        return false;
      }
      final opened = await QuranPackDatabase.open(
        databasePath: databaseFile.path,
        editionId: edition,
      );
      await opened.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<QuranPackDatabase?> openInstalled(
    QuranRiwayahId edition,
  ) async {
    if (!await isInstalled(edition)) return null;
    try {
      return await QuranPackDatabase.open(
        databasePath: p.join(
          (await _packsDirectory()).path,
          edition.wireValue,
          'quran.sqlite',
        ),
        editionId: edition,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String?> fontPath(QuranRiwayahId edition) async {
    if (!await isInstalled(edition)) return null;
    return p.join(
      (await _packsDirectory()).path,
      edition.wireValue,
      'riwayah.ttf',
    );
  }

  static Future<bool> delete(QuranRiwayahId edition) async {
    try {
      final root = await _packsDirectory();
      final directory = Directory(p.join(root.path, edition.wireValue));
      if (await directory.exists()) await directory.delete(recursive: true);
      final backup = Directory(
        p.join(root.path, '.${edition.wireValue}.backup'),
      );
      if (await backup.exists()) await backup.delete(recursive: true);
      await for (final entry in root.list()) {
        if (entry is Directory &&
            p
                .basename(entry.path)
                .startsWith('.${edition.wireValue}.staging-')) {
          await entry.delete(recursive: true);
        }
      }
      final preferences = await SharedPreferences.getInstance();
      final installed = preferences.getStringList(_downloadedKey) ?? [];
      installed.remove(edition.wireValue);
      await preferences.setStringList(_downloadedKey, installed);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<int> storageBytes(QuranRiwayahId edition) async {
    try {
      final directory = Directory(
        p.join((await _packsDirectory()).path, edition.wireValue),
      );
      if (!await directory.exists()) return 0;
      var bytes = 0;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) bytes += await entity.length();
      }
      return bytes;
    } catch (_) {
      return 0;
    }
  }

  static Future<List<_ValidatedAyah>> _readAndValidateSource(
    File file,
    QuranRiwayahId edition,
  ) async {
    final pin = _sourcePins[edition]!;
    final fields = pin['fields'] as Map<String, dynamic>;
    final expectedCount = pin['expectedAyahCount'] as int;
    final pageCount = pin['pageCount'] as int;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! List || decoded.length != expectedCount) {
      throw FormatException('عدد الآيات في المصدر غير مطابق للرواية');
    }

    final result = <_ValidatedAyah>[];
    final namesBySurah = <int, (String, String)>{};
    final lastAyahBySurah = <int, int>{};
    final coveredPages = <int>{};
    var previousSurah = 1;
    var previousPageStart = 0;
    for (var index = 0; index < decoded.length; index++) {
      final row = decoded[index];
      if (row is! Map<String, dynamic>) {
        throw FormatException('سجل آية غير صالح عند الموضع ${index + 1}');
      }
      final sourceId = _readInt(row, fields['id'] as String);
      final surah = _readInt(row, fields['surah'] as String);
      final ayah = _readInt(row, fields['ayah'] as String);
      final juz = _readInt(row, fields['juz'] as String);
      final lineStart = _readInt(row, fields['lineStart'] as String);
      final lineEnd = _readInt(row, fields['lineEnd'] as String);
      if (sourceId != index + 1 ||
          surah < 1 ||
          surah > 114 ||
          surah < previousSurah ||
          ayah != (lastAyahBySurah[surah] ?? 0) + 1 ||
          juz < 1 ||
          juz > 30 ||
          lineStart < 1 ||
          lineStart > 15 ||
          lineEnd < 1 ||
          lineEnd > 15) {
        throw FormatException('إحداثيات الآية غير صالحة عند السجل $sourceId');
      }
      previousSurah = surah;
      lastAyahBySurah[surah] = ayah;
      final displayText = row[fields['displayText'] as String];
      final searchField = fields['searchText'];
      final searchText = searchField == null
          ? null
          : row[searchField as String];
      final nameAr = row[fields['surahNameAr'] as String];
      final nameEn = row[fields['surahNameEn'] as String];
      if (displayText is! String ||
          displayText.isEmpty ||
          (searchText != null && searchText is! String) ||
          nameAr is! String ||
          nameAr.isEmpty ||
          nameEn is! String ||
          nameEn.isEmpty) {
        throw FormatException('حقول الآية أو اسم السورة ناقصة عند $sourceId');
      }
      final previousNames = namesBySurah.putIfAbsent(
        surah,
        () => (nameAr, nameEn),
      );
      if (previousNames != (nameAr, nameEn)) {
        throw FormatException('تغير اسم السورة ضمن بيانات السورة $surah');
      }
      final (pageStart, pageEnd) = _parsePageRange(
        row[fields['page'] as String],
        pageCount,
      );
      if (pageStart < previousPageStart ||
          (pageStart == pageEnd && lineEnd < lineStart) ||
          (pageEnd > pageStart && lineEnd >= lineStart)) {
        throw FormatException('ترتيب الصفحة أو السطر غير صالح عند $sourceId');
      }
      previousPageStart = pageStart;
      for (var page = pageStart; page <= pageEnd; page++) {
        coveredPages.add(page);
      }
      result.add(
        _ValidatedAyah(
          sourceId: sourceId,
          surahNumber: surah,
          ayahNumber: ayah,
          displayText: displayText,
          searchText: ArabicSearchUtils.normalize(
            (searchText as String?) ?? displayText,
          ),
          juzNumber: juz,
          pageStart: pageStart,
          pageEnd: pageEnd,
          lineStart: lineStart,
          lineEnd: lineEnd,
        ),
      );
    }
    if (namesBySurah.length != 114 ||
        !coveredPages.containsAll(
          List<int>.generate(pageCount, (i) => i + 1),
        )) {
      throw const FormatException('المصدر لا يغطي السور أو الصفحات كاملة');
    }
    _validatedSurahNames[edition] = Map.unmodifiable(namesBySurah);
    return result;
  }

  static Future<void> _buildDatabase(
    File file,
    QuranRiwayahId edition,
    List<_ValidatedAyah> ayahs,
    Map<String, dynamic> pin,
  ) async {
    final names = <int, (String, String)>{};
    final surahAyahCounts = <int, int>{};
    final surahPageRanges = <int, (int, int)>{};
    for (final ayah in ayahs) {
      final sourceRow = ayah;
      // Names are recovered from the pinned JSON during validation and stored
      // separately in the installer's normalized metadata map.
      final name = _validatedSurahNames[edition]?[sourceRow.surahNumber];
      if (name != null) names[sourceRow.surahNumber] = name;
      surahAyahCounts.update(
        sourceRow.surahNumber,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      final oldRange = surahPageRanges[sourceRow.surahNumber];
      surahPageRanges[sourceRow.surahNumber] = oldRange == null
          ? (sourceRow.pageStart, sourceRow.pageEnd)
          : (
              sourceRow.pageStart < oldRange.$1
                  ? sourceRow.pageStart
                  : oldRange.$1,
              sourceRow.pageEnd > oldRange.$2 ? sourceRow.pageEnd : oldRange.$2,
            );
    }
    final database = await openDatabase(
      file.path,
      version: QuranPackDatabase.supportedSchemaVersion,
      onCreate: (db, _) async {
        await db.execute(
          'PRAGMA application_id = ${QuranPackDatabase.applicationId}',
        );
        await db.execute(
          'PRAGMA user_version = ${QuranPackDatabase.supportedSchemaVersion}',
        );
        await db.execute('''
          CREATE TABLE pack_metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          ) WITHOUT ROWID
        ''');
        await db.execute('''
          CREATE TABLE surahs (
            surah_number INTEGER PRIMARY KEY,
            name_ar TEXT NOT NULL,
            name_en TEXT NOT NULL,
            ayah_count INTEGER NOT NULL,
            page_start INTEGER NOT NULL,
            page_end INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE ayahs (
            surah_number INTEGER NOT NULL REFERENCES surahs(surah_number),
            ayah_number INTEGER NOT NULL,
            source_id INTEGER NOT NULL UNIQUE,
            display_text TEXT NOT NULL,
            search_text TEXT,
            juz_number INTEGER NOT NULL,
            page_start INTEGER NOT NULL,
            page_end INTEGER NOT NULL,
            line_start INTEGER NOT NULL,
            line_end INTEGER NOT NULL,
            PRIMARY KEY (surah_number, ayah_number)
          ) WITHOUT ROWID
        ''');
        await db.execute(
          'CREATE INDEX ayahs_by_page ON ayahs(page_start, page_end, surah_number, ayah_number)',
        );
        await db.execute(
          'CREATE INDEX ayahs_by_juz ON ayahs(juz_number, surah_number, ayah_number)',
        );
      },
    );
    try {
      await database.transaction((transaction) async {
        final pinData = pin['data'] as Map<String, dynamic>;
        final pinFont = pin['font'] as Map<String, dynamic>;
        final metadata = <String, String>{
          'edition_id': edition.wireValue,
          'schema_version': '${QuranPackDatabase.supportedSchemaVersion}',
          'source_repository': sourceRepository,
          'source_commit': sourceCommit,
          'source_data_sha256': pinData['sha256'] as String,
          'source_font_sha256': pinFont['sha256'] as String,
          'data_version': pin['dataVersion'] as String,
          'ayah_count': '${ayahs.length}',
          'surah_count': '114',
          'page_count': '${pin['pageCount']}',
        };
        final metadataBatch = transaction.batch();
        for (final entry in metadata.entries) {
          metadataBatch.insert('pack_metadata', {
            'key': entry.key,
            'value': entry.value,
          });
        }
        await metadataBatch.commit(noResult: true);

        final surahBatch = transaction.batch();
        for (var surah = 1; surah <= 114; surah++) {
          final name = names[surah];
          final range = surahPageRanges[surah];
          if (name == null || range == null) {
            throw FormatException('بيانات السورة $surah غير مكتملة');
          }
          surahBatch.insert('surahs', {
            'surah_number': surah,
            'name_ar': name.$1,
            'name_en': name.$2,
            'ayah_count': surahAyahCounts[surah],
            'page_start': range.$1,
            'page_end': range.$2,
          });
        }
        await surahBatch.commit(noResult: true);

        for (var start = 0; start < ayahs.length; start += 500) {
          final end = (start + 500).clamp(0, ayahs.length);
          final batch = transaction.batch();
          for (final ayah in ayahs.sublist(start, end)) {
            batch.insert('ayahs', {
              'surah_number': ayah.surahNumber,
              'ayah_number': ayah.ayahNumber,
              'source_id': ayah.sourceId,
              'display_text': ayah.displayText,
              'search_text': ayah.searchText,
              'juz_number': ayah.juzNumber,
              'page_start': ayah.pageStart,
              'page_end': ayah.pageEnd,
              'line_start': ayah.lineStart,
              'line_end': ayah.lineEnd,
            });
          }
          await batch.commit(noResult: true);
        }
      });
      final integrity = await database.rawQuery('PRAGMA integrity_check');
      if (integrity.single.values.single != 'ok') {
        throw const FormatException('بنية قاعدة بيانات المصحف غير سليمة');
      }
    } finally {
      await database.close();
    }
  }

  static final Map<QuranRiwayahId, Map<int, (String, String)>>
  _validatedSurahNames = {};

  static int _readInt(Map<String, dynamic> row, String field) {
    final value = row[field];
    if (value is! int || value is bool) {
      throw FormatException('حقل المصدر $field غير صحيح');
    }
    return value;
  }

  static (int, int) _parsePageRange(Object? value, int pageCount) {
    final text = value.toString();
    final match = RegExp(
      r'^\s*([1-9]\d*)(?:\s*[-–—]\s*([1-9]\d*))?\s*$',
    ).firstMatch(text);
    if (match == null) throw const FormatException('رقم صفحة غير صالح');
    final start = int.parse(match.group(1)!);
    final end = int.parse(match.group(2) ?? match.group(1)!);
    if (start < 1 || end < start || end > pageCount || end - start > 1) {
      throw const FormatException('مدى الصفحات خارج الحدود');
    }
    return (start, end);
  }

  static Future<String> _sha256File(File file) async =>
      (await sha256.bind(file.openRead()).first).toString().toUpperCase();

  static Future<Directory> _packsDirectory() async {
    final base = testBaseDir ?? await getApplicationSupportDirectory();
    final directory = Directory(p.join(base.path, 'quran_packs'));
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  static Future<void> _recoverInstalledDirectory(
    Directory root,
    QuranRiwayahId edition,
  ) async {
    final installed = Directory(p.join(root.path, edition.wireValue));
    final backup = Directory(p.join(root.path, '.${edition.wireValue}.backup'));
    if (!await backup.exists()) return;
    if (!await installed.exists()) {
      await backup.rename(installed.path);
      return;
    }
    try {
      await backup.delete(recursive: true);
    } catch (_) {}
  }

  static String _shortError(Object error) {
    final message = error.toString().replaceFirst(RegExp(r'^.*?: '), '');
    return message.length <= 100 ? message : '${message.substring(0, 97)}…';
  }

  static String _installErrorMessage(Object error) {
    if (error.toString().toLowerCase().contains('abort')) {
      return 'أُلغي التنزيل';
    }
    if (error is TimeoutException) {
      return 'انتهت مهلة الاتصال؛ تحقق من الإنترنت وحاول مرة أخرى';
    }
    if (error is SocketException ||
        error is HandshakeException ||
        error is http.ClientException) {
      return 'تعذر الاتصال بمصادر التنزيل. تحقق من الإنترنت أو جرّب شبكة أخرى.';
    }
    if (error is HttpException) {
      return 'مصدر التنزيل غير متاح حالياً. حاول مرة أخرى بعد قليل.';
    }
    if (error is FileSystemException) {
      return 'تعذر حفظ الحزمة على الجهاز. تحقق من مساحة التخزين ثم أعد المحاولة.';
    }
    if (error is FormatException) return error.message.toString();
    return 'تعذر تثبيت الرواية: ${_shortError(error)}';
  }

  static const Map<QuranRiwayahId, Map<String, dynamic>> _sourcePins = {
    QuranRiwayahId.hafs: {
      'dataVersion': '18',
      'expectedAyahCount': 6236,
      'pageCount': 604,
      'fields': {
        'id': 'id',
        'surah': 'sora',
        'ayah': 'aya_no',
        'displayText': 'aya_text',
        'searchText': 'aya_text_emlaey',
        'juz': 'jozz',
        'page': 'page',
        'lineStart': 'line_start',
        'lineEnd': 'line_end',
        'surahNameAr': 'sora_name_ar',
        'surahNameEn': 'sora_name_en',
      },
      'data': {
        'kind': 'data',
        'filename': 'source.json',
        'url':
            'https://raw.githubusercontent.com/thetruetruth/quran-data-kfgqpc/281dbbe8eed1370daa5a023b6cd81655cbfd6473/hafs/data/hafsData_v18.json',
        'bytes': 3582144,
        'sha256':
            '5D8BB91726E482839D0057633CB1973031E4D706FA9604EEA5E08892F20BA140',
      },
      'font': {
        'kind': 'font',
        'filename': 'source.ttf',
        'url':
            'https://raw.githubusercontent.com/thetruetruth/quran-data-kfgqpc/281dbbe8eed1370daa5a023b6cd81655cbfd6473/hafs/font/hafs.18.ttf',
        'bytes': 242368,
        'sha256':
            'A0636E68E375AF9552470D67773936F54D536E6586CE2608311B2FE7F9CBEC3A',
      },
    },
    QuranRiwayahId.warsh: {
      'dataVersion': '10',
      'expectedAyahCount': 6214,
      'pageCount': 604,
      'fields': {
        'id': 'id',
        'surah': 'sura_no',
        'ayah': 'aya_no',
        'displayText': 'aya_text',
        'searchText': null,
        'juz': 'jozz',
        'page': 'page',
        'lineStart': 'line_start',
        'lineEnd': 'line_end',
        'surahNameAr': 'sura_name_ar',
        'surahNameEn': 'sura_name_en',
      },
      'data': {
        'kind': 'data',
        'filename': 'source.json',
        'url':
            'https://raw.githubusercontent.com/thetruetruth/quran-data-kfgqpc/281dbbe8eed1370daa5a023b6cd81655cbfd6473/warsh/data/warshData_v10.json',
        'bytes': 2772330,
        'sha256':
            'F05D0DC652FD46B38563CACB13242F76F80DB4CC64D25873DA0BCE157253872F',
      },
      'font': {
        'kind': 'font',
        'filename': 'source.ttf',
        'url':
            'https://raw.githubusercontent.com/thetruetruth/quran-data-kfgqpc/281dbbe8eed1370daa5a023b6cd81655cbfd6473/warsh/font/warsh.10.ttf',
        'bytes': 256048,
        'sha256':
            'E6347A1B4CF0CA32E9CB187A7DB8C9ECEE0D5E384269CA6A943373A34FF747FB',
      },
    },
    QuranRiwayahId.qalun: {
      'dataVersion': '10',
      'expectedAyahCount': 6214,
      'pageCount': 604,
      'fields': {
        'id': 'id',
        'surah': 'sura_no',
        'ayah': 'aya_no',
        'displayText': 'aya_text',
        'searchText': null,
        'juz': 'jozz',
        'page': 'page',
        'lineStart': 'line_start',
        'lineEnd': 'line_end',
        'surahNameAr': 'sura_name_ar',
        'surahNameEn': 'sura_name_en',
      },
      'data': {
        'kind': 'data',
        'filename': 'source.json',
        'url':
            'https://raw.githubusercontent.com/thetruetruth/quran-data-kfgqpc/281dbbe8eed1370daa5a023b6cd81655cbfd6473/qaloon/data/QaloonData_v10.json',
        'bytes': 2759672,
        'sha256':
            '18465C40EBEEC40A92EB98745C9B89796AC6E31F6E93988883DFB6602FAAEA95',
      },
      'font': {
        'kind': 'font',
        'filename': 'source.ttf',
        'url':
            'https://raw.githubusercontent.com/thetruetruth/quran-data-kfgqpc/281dbbe8eed1370daa5a023b6cd81655cbfd6473/qaloon/font/qaloon.10.ttf',
        'bytes': 260592,
        'sha256':
            '95E7F9268FD4AB9F8B79D2ED3827E0C8A78F80195C02C6CBADB97C90D837B1E3',
      },
    },
  };
}

class QuranPackInstallProgress {
  final QuranRiwayahId edition;
  final double progress;
  final String status;
  final int? receivedBytes;
  final int? totalBytes;
  final bool isComplete;
  final bool isError;

  const QuranPackInstallProgress(
    this.edition,
    this.progress,
    this.status, {
    this.receivedBytes,
    this.totalBytes,
    this.isComplete = false,
    this.isError = false,
  });

  factory QuranPackInstallProgress.failed(
    QuranRiwayahId edition,
    String message,
  ) => QuranPackInstallProgress(edition, 0, message, isError: true);
}

class _PinnedAsset {
  final String kind;
  final String filename;
  final String url;
  final int bytes;
  final String sha256;

  const _PinnedAsset({
    required this.kind,
    required this.filename,
    required this.url,
    required this.bytes,
    required this.sha256,
  });

  factory _PinnedAsset.fromJson(Map<String, dynamic> json, String kind) =>
      _PinnedAsset(
        kind: kind,
        filename: json['filename'] as String,
        url: json['url'] as String,
        bytes: json['bytes'] as int,
        sha256: (json['sha256'] as String).toUpperCase(),
      );
}

class _ValidatedAyah {
  final int sourceId;
  final int surahNumber;
  final int ayahNumber;
  final String displayText;
  final String? searchText;
  final int juzNumber;
  final int pageStart;
  final int pageEnd;
  final int lineStart;
  final int lineEnd;

  const _ValidatedAyah({
    required this.sourceId,
    required this.surahNumber,
    required this.ayahNumber,
    required this.displayText,
    required this.searchText,
    required this.juzNumber,
    required this.pageStart,
    required this.pageEnd,
    required this.lineStart,
    required this.lineEnd,
  });
}
