import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/quran_models.dart';

/// Read-only runtime access to one already-installed edition-scoped Quran pack.
///
/// Installation, source hash verification, and font registration belong to the
/// pack installer. This class independently checks the SQLite identity/schema
/// before exposing any records and never falls back to another edition.
class QuranPackDatabase {
  static const int applicationId = 0x514D5348; // QMSH
  static const int supportedSchemaVersion = 1;

  final Database _database;
  final QuranRiwayahId editionId;
  final int ayahCount;
  final int pageCount;
  bool _closed = false;

  QuranPackDatabase._({
    required Database database,
    required this.editionId,
    required this.ayahCount,
    required this.pageCount,
  }) : _database = database;

  /// Open a pack SQLite database in read-only mode and verify its identity.
  static Future<QuranPackDatabase> open({
    required String databasePath,
    required QuranRiwayahId editionId,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Downloadable Quran packs are not supported on Web',
      );
    }
    if (databasePath.trim().isEmpty || !p.isAbsolute(databasePath)) {
      throw ArgumentError.value(
        databasePath,
        'databasePath',
        'Must be an absolute installed-pack database path',
      );
    }

    final database = await openDatabase(
      databasePath,
      readOnly: true,
      singleInstance: false,
    );
    try {
      return await _openValidated(database, editionId);
    } catch (_) {
      await database.close();
      rethrow;
    }
  }

  @visibleForTesting
  static Future<QuranPackDatabase> openForTesting({
    required Database database,
    required QuranRiwayahId editionId,
  }) async {
    try {
      return await _openValidated(database, editionId);
    } catch (_) {
      await database.close();
      rethrow;
    }
  }

  static Future<QuranPackDatabase> _openValidated(
    Database database,
    QuranRiwayahId expectedEdition,
  ) async {
    final appIdRows = await database.rawQuery('PRAGMA application_id');
    final schemaRows = await database.rawQuery('PRAGMA user_version');
    final actualApplicationId = appIdRows.isEmpty
        ? null
        : appIdRows.first['application_id'];
    final actualSchemaVersion = schemaRows.isEmpty
        ? null
        : schemaRows.first['user_version'];
    if (actualApplicationId != applicationId) {
      throw const FormatException(
        'Quran pack SQLite application_id is invalid',
      );
    }
    if (actualSchemaVersion != supportedSchemaVersion) {
      throw FormatException(
        'Unsupported Quran pack SQLite schema: $actualSchemaVersion',
      );
    }

    final metadataRows = await database.query('pack_metadata');
    final metadata = <String, String>{};
    for (final row in metadataRows) {
      final key = row['key'];
      final value = row['value'];
      if (key is! String || value is! String || metadata.containsKey(key)) {
        throw const FormatException('Quran pack metadata is malformed');
      }
      metadata[key] = value;
    }

    if (metadata['edition_id'] != expectedEdition.wireValue) {
      throw FormatException(
        'Quran pack edition mismatch: expected ${expectedEdition.wireValue}, '
        'received ${metadata['edition_id'] ?? 'missing'}',
      );
    }
    if (metadata['schema_version'] != supportedSchemaVersion.toString()) {
      throw const FormatException('Quran pack metadata schema mismatch');
    }
    final ayahCount = int.tryParse(metadata['ayah_count'] ?? '');
    final surahCount = int.tryParse(metadata['surah_count'] ?? '');
    final pageCount = int.tryParse(metadata['page_count'] ?? '');
    final expectedAyahCount = switch (expectedEdition) {
      QuranRiwayahId.hafs => 6236,
      QuranRiwayahId.warsh || QuranRiwayahId.qalun => 6214,
    };
    if (ayahCount == null || ayahCount != expectedAyahCount) {
      throw FormatException(
        'Quran pack ayah count is invalid for ${expectedEdition.wireValue}',
      );
    }
    if (surahCount != 114 || pageCount == null || pageCount < 1) {
      throw const FormatException('Quran pack navigation counts are invalid');
    }

    final actualSurahs = await database.rawQuery(
      'SELECT COUNT(*) AS record_count FROM surahs',
    );
    final actualAyahs = await database.rawQuery(
      'SELECT COUNT(*) AS record_count FROM ayahs',
    );
    if (_readCount(actualSurahs) != 114 ||
        _readCount(actualAyahs) != ayahCount) {
      throw const FormatException(
        'Quran pack database record counts do not match',
      );
    }

    final bounds = await database.rawQuery(
      'SELECT MIN(surah_number) AS first_surah, '
      'MAX(surah_number) AS last_surah FROM surahs',
    );
    if (bounds.length != 1 ||
        bounds.single['first_surah'] != 1 ||
        bounds.single['last_surah'] != 114) {
      throw const FormatException('Quran pack surah bounds are invalid');
    }

    return QuranPackDatabase._(
      database: database,
      editionId: expectedEdition,
      ayahCount: ayahCount,
      pageCount: pageCount,
    );
  }

  static int? _readCount(List<Map<String, Object?>> rows) {
    if (rows.length != 1) return null;
    final value = rows.single['record_count'];
    return value is int ? value : null;
  }

  Future<QuranPackSurah?> getSurah(int surahNumber) async {
    _ensureOpen();
    if (surahNumber < 1 || surahNumber > 114) return null;
    final rows = await _database.query(
      'surahs',
      where: 'surah_number = ?',
      whereArgs: [surahNumber],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return QuranPackSurah.fromRow(rows.single);
  }

  Future<List<QuranPackSurah>> getSurahList() async {
    _ensureOpen();
    final rows = await _database.query('surahs', orderBy: 'surah_number ASC');
    return List.unmodifiable(rows.map(QuranPackSurah.fromRow));
  }

  Future<QuranPackAyah?> getAyah(int surahNumber, int ayahNumber) async {
    _ensureOpen();
    if (surahNumber < 1 || surahNumber > 114 || ayahNumber < 1) return null;
    final rows = await _database.query(
      'ayahs',
      where: 'surah_number = ? AND ayah_number = ?',
      whereArgs: [surahNumber, ayahNumber],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return QuranPackAyah.fromRow(rows.single);
  }

  Future<List<QuranPackAyah>> getSurahAyahs(int surahNumber) async {
    _ensureOpen();
    if (surahNumber < 1 || surahNumber > 114) return const [];
    final rows = await _database.query(
      'ayahs',
      where: 'surah_number = ?',
      whereArgs: [surahNumber],
      orderBy: 'ayah_number ASC',
    );
    return List.unmodifiable(rows.map(QuranPackAyah.fromRow));
  }

  /// Returns ayahs whose printed page span includes [pageNumber].
  /// Cross-page ayahs are returned on both pages with both coordinates intact.
  Future<List<QuranPackAyah>> getPageAyahs(int pageNumber) async {
    _ensureOpen();
    if (pageNumber < 1 || pageNumber > pageCount) return const [];
    final rows = await _database.query(
      'ayahs',
      where: 'page_start <= ? AND page_end >= ?',
      whereArgs: [pageNumber, pageNumber],
      orderBy: 'surah_number ASC, ayah_number ASC',
    );
    return List.unmodifiable(rows.map(QuranPackAyah.fromRow));
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _database.close();
  }

  void _ensureOpen() {
    if (_closed) throw StateError('Quran pack database is closed');
  }
}

class QuranPackSurah {
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final int ayahCount;
  final int firstPage;
  final int lastPage;

  const QuranPackSurah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.ayahCount,
    required this.firstPage,
    required this.lastPage,
  });

  factory QuranPackSurah.fromRow(Map<String, Object?> row) => QuranPackSurah(
    number: _requiredInt(row, 'surah_number'),
    nameArabic: _requiredString(row, 'name_ar'),
    nameEnglish: _requiredString(row, 'name_en'),
    ayahCount: _requiredInt(row, 'ayah_count'),
    firstPage: _requiredInt(row, 'page_start'),
    lastPage: _requiredInt(row, 'page_end'),
  );
}

class QuranPackAyah {
  final int sourceId;
  final int surahNumber;
  final int ayahNumber;
  final String displayText;
  final String? searchText;
  final int juzNumber;
  final int firstPage;
  final int lastPage;
  final int firstLine;
  final int lastLine;

  const QuranPackAyah({
    required this.sourceId,
    required this.surahNumber,
    required this.ayahNumber,
    required this.displayText,
    required this.searchText,
    required this.juzNumber,
    required this.firstPage,
    required this.lastPage,
    required this.firstLine,
    required this.lastLine,
  });

  factory QuranPackAyah.fromRow(Map<String, Object?> row) => QuranPackAyah(
    sourceId: _requiredInt(row, 'source_id'),
    surahNumber: _requiredInt(row, 'surah_number'),
    ayahNumber: _requiredInt(row, 'ayah_number'),
    displayText: _requiredString(row, 'display_text'),
    searchText: _optionalString(row, 'search_text'),
    juzNumber: _requiredInt(row, 'juz_number'),
    firstPage: _requiredInt(row, 'page_start'),
    lastPage: _requiredInt(row, 'page_end'),
    firstLine: _requiredInt(row, 'line_start'),
    lastLine: _requiredInt(row, 'line_end'),
  );
}

int _requiredInt(Map<String, Object?> row, String field) {
  final value = row[field];
  if (value is! int) {
    throw FormatException('Quran pack field $field is invalid');
  }
  return value;
}

String _requiredString(Map<String, Object?> row, String field) {
  final value = row[field];
  if (value is! String) {
    throw FormatException('Quran pack field $field is invalid');
  }
  return value;
}

String? _optionalString(Map<String, Object?> row, String field) {
  final value = row[field];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('Quran pack field $field is invalid');
  }
  return value;
}
