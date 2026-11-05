import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:talib_ilm/features/quran/data/database/quran_pack_database.dart';
import 'package:talib_ilm/features/quran/data/models/quran_models.dart';

void main() {
  group('QuranPackDatabase', () {
    test('rejects a pack that belongs to another riwayah', () async {
      final database = _FakePackDatabase(editionId: 'hafs');

      await expectLater(
        QuranPackDatabase.openForTesting(
          database: database,
          editionId: QuranRiwayahId.warsh,
        ),
        throwsA(isA<FormatException>()),
      );
      expect(database.closed, isTrue);
    });

    test('rejects the wrong native SQLite application identity', () async {
      final database = _FakePackDatabase(applicationId: 42);

      await expectLater(
        QuranPackDatabase.openForTesting(
          database: database,
          editionId: QuranRiwayahId.warsh,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'opens the matching read-only pack and preserves page-spanning ayahs',
      () async {
        final database = _FakePackDatabase(editionId: 'warsh');
        final pack = await QuranPackDatabase.openForTesting(
          database: database,
          editionId: QuranRiwayahId.warsh,
        );
        addTearDown(pack.close);

        expect(pack.editionId, QuranRiwayahId.warsh);
        expect(pack.ayahCount, 6214);
        expect(pack.pageCount, 604);

        final surah = await pack.getSurah(4);
        expect(surah?.nameArabic, 'سورة اختبار');
        expect(surah?.ayahCount, 176);

        final verse = await pack.getAyah(4, 44);
        expect(verse?.displayText, 'نص مصدر تجريبي دون تعديل');
        expect(verse?.firstPage, 85);
        expect(verse?.lastPage, 86);
        expect(verse?.firstLine, 14);
        expect(verse?.lastLine, 1);

        final firstPage = await pack.getPageAyahs(85);
        final nextPage = await pack.getPageAyahs(86);
        expect(firstPage.single.ayahNumber, 44);
        expect(nextPage.single.ayahNumber, 44);
        expect(firstPage.single.firstPage, 85);
        expect(firstPage.single.lastPage, 86);
      },
    );

    test('returns no page data for out-of-range edition coordinates', () async {
      final pack = await QuranPackDatabase.openForTesting(
        database: _FakePackDatabase(editionId: 'qalun'),
        editionId: QuranRiwayahId.qalun,
      );
      addTearDown(pack.close);

      expect(await pack.getSurah(0), isNull);
      expect(await pack.getAyah(1, 0), isNull);
      expect(await pack.getPageAyahs(605), isEmpty);
    });
  });
}

class _FakePackDatabase implements Database {
  _FakePackDatabase({
    this.editionId = 'warsh',
    this.applicationId = QuranPackDatabase.applicationId,
  });

  final String editionId;
  final int applicationId;
  bool closed = false;

  static const _crossPageAyah = <String, Object?>{
    'source_id': 536,
    'surah_number': 4,
    'ayah_number': 44,
    'display_text': 'نص مصدر تجريبي دون تعديل',
    'search_text': null,
    'juz_number': 6,
    'page_start': 85,
    'page_end': 86,
    'line_start': 14,
    'line_end': 1,
  };

  static const _surah = <String, Object?>{
    'surah_number': 4,
    'name_ar': 'سورة اختبار',
    'name_en': 'Fixture Surah',
    'ayah_count': 176,
    'page_start': 77,
    'page_end': 106,
  };

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    if (sql == 'PRAGMA application_id') {
      return [
        <String, Object?>{'application_id': applicationId},
      ];
    }
    if (sql == 'PRAGMA user_version') {
      return const [
        <String, Object?>{'user_version': 1},
      ];
    }
    if (sql == 'PRAGMA integrity_check') {
      return const [
        <String, Object?>{'integrity_check': 'ok'},
      ];
    }
    if (sql.contains('COUNT(*) AS record_count FROM surahs')) {
      return const [
        <String, Object?>{'record_count': 114},
      ];
    }
    if (sql.contains('COUNT(*) AS record_count FROM ayahs')) {
      return const [
        <String, Object?>{'record_count': 6214},
      ];
    }
    if (sql.contains('MIN(surah_number)')) {
      return const [
        <String, Object?>{'first_surah': 1, 'last_surah': 114},
      ];
    }
    return const [];
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (table == 'pack_metadata') {
      return [
        {'key': 'edition_id', 'value': editionId},
        {'key': 'schema_version', 'value': '1'},
        {'key': 'ayah_count', 'value': '6214'},
        {'key': 'surah_count', 'value': '114'},
        {'key': 'page_count', 'value': '604'},
      ];
    }
    if (table == 'surahs') {
      if (whereArgs != null && whereArgs.isNotEmpty && whereArgs.first == 4) {
        return [_surah];
      }
      if (orderBy != null) return [_surah];
      return const [];
    }
    if (table == 'ayahs') {
      if (where == 'page_start <= ? AND page_end >= ?') {
        final page = whereArgs != null && whereArgs.isNotEmpty
            ? whereArgs.first
            : null;
        return page == 85 || page == 86 ? [_crossPageAyah] : const [];
      }
      if (whereArgs?.length == 2 && whereArgs![0] == 4 && whereArgs[1] == 44) {
        return [_crossPageAyah];
      }
      return const [];
    }
    return const [];
  }

  @override
  Future<void> close() async {
    closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
