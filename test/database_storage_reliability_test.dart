import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:talib_ilm/features/quran/data/database/quran_database.dart';
import 'package:talib_ilm/features/quran/data/services/bookmark_service.dart';
import 'package:talib_ilm/features/quran/data/services/quran_page_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    QuranDatabase.resetForTesting();
  });

  tearDown(() async {
    QuranDatabase.resetForTesting();
  });

  group('QuranDatabase Bounds & Test Seams (R89)', () {
    test('isValidPageNumber accurately bounds 1..604', () {
      expect(QuranDatabase.isValidPageNumber(1), isTrue);
      expect(QuranDatabase.isValidPageNumber(604), isTrue);
      expect(QuranDatabase.isValidPageNumber(0), isFalse);
      expect(QuranDatabase.isValidPageNumber(605), isFalse);
      expect(QuranDatabase.isValidPageNumber(-1), isFalse);
    });

    test('getPage returns null immediately on invalid page numbers without hitting DB', () async {
      final db = QuranDatabase.instance;
      expect(await db.getPage(0), isNull);
      expect(await db.getPage(605), isNull);
      expect(await db.getPage(-10), isNull);
    });

    test('savePage throws ArgumentError on out-of-bounds page numbers', () async {
      final db = QuranDatabase.instance;
      final dummyData = QuranPageData(
        pageNumber: 0,
        verses: [],
      );

      expect(() => db.savePage(0, dummyData), throwsArgumentError);
      expect(() => db.savePage(605, dummyData), throwsArgumentError);
    });
  });

  group('QuranDatabase Corruption Recovery & Batch Operations (R89)', () {
    test('getPage detects corrupt JSON row, deletes it, and recovers cleanly with null', () async {
      final mockDb = _FakeDatabase();
      // Insert a corrupted, non-JSON string into page 1 row
      mockDb.store['pages'] = [
        {'page_number': 1, 'json_data': 'CORRUPTED_{NOT_JSON_DATA'},
      ];

      QuranDatabase.setDatabaseForTesting(mockDb);

      final result = await QuranDatabase.instance.getPage(1);
      expect(result, isNull);

      // Verify the corrupt row was deleted for self-healing
      final remainingRows = mockDb.store['pages'] as List<Map<String, dynamic>>;
      expect(remainingRows.any((r) => r['page_number'] == 1), isFalse);
    });

    test('savePagesBatch writes multiple pages atomically in transaction', () async {
      final mockDb = _FakeDatabase();
      QuranDatabase.setDatabaseForTesting(mockDb);

      final Map<int, QuranPageData> pages = {
        1: QuranPageData(pageNumber: 1, verses: []),
        2: QuranPageData(pageNumber: 2, verses: []),
      };

      await QuranDatabase.instance.savePagesBatch(pages);

      final stored = mockDb.store['pages'] as List<Map<String, dynamic>>;
      expect(stored.length, 2);
      expect(stored[0]['page_number'], 1);
      expect(stored[1]['page_number'], 2);
    });

    test('clearAllPages deletes all cached pages', () async {
      final mockDb = _FakeDatabase();
      mockDb.store['pages'] = [
        {'page_number': 1, 'json_data': '{}'},
        {'page_number': 2, 'json_data': '{}'},
      ];
      QuranDatabase.setDatabaseForTesting(mockDb);

      await QuranDatabase.instance.clearAllPages();
      final stored = mockDb.store['pages'] as List<Map<String, dynamic>>;
      expect(stored.isEmpty, isTrue);
    });
  });

  group('BookmarkService Storage Reliability & Migration (R89)', () {
    test('does not resurrect legacy bookmarks when active bookmarks list is empty', () async {
      // Setup SharedPreferences with empty active bookmarks list and old legacy data
      SharedPreferences.setMockInitialValues({
        'bookmarks_v2': '[]',
        'dashboard_fav_surahs': ['1', '2'],
        'bookmarks': '[{"surah": 36, "ayah": 1}]',
      });

      final bookmarks = await BookmarkService.getBookmarks();
      // Must respect the empty active list and NOT re-import legacy data
      expect(bookmarks, isEmpty);
    });

    test('cleans up legacy keys upon successful migration', () async {
      SharedPreferences.setMockInitialValues({
        'dashboard_fav_surahs': ['1', '112'],
      });

      final bookmarks = await BookmarkService.getBookmarks();
      expect(bookmarks.length, 2);
      expect(bookmarks.map((b) => b.surah), containsAll([1, 112]));

      final prefs = await SharedPreferences.getInstance();
      // Legacy key must be purged so future empty states do not resurrect it
      expect(prefs.containsKey('dashboard_fav_surahs'), isFalse);
      expect(prefs.containsKey('bookmarks_v2'), isTrue);
    });

    test('truncates notes exceeding 2000 characters to prevent storage bloat', () async {
      final hugeNote = 'A' * 3000;
      await BookmarkService.addBookmark(1, 1, note: hugeNote);

      final bookmarks = await BookmarkService.getBookmarks();
      expect(bookmarks.length, 1);
      expect(bookmarks.first.note!.length, 2000);
    });
  });
}

class _FakeDatabase implements Database {
  final Map<String, List<Map<String, dynamic>>> store = {
    'pages': [],
  };

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
    final list = store[table] ?? [];
    if (where != null && where.contains('page_number = ?') && whereArgs != null) {
      final target = whereArgs.first;
      return list.where((r) => r['page_number'] == target).toList();
    }
    return list;
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final list = store.putIfAbsent(table, () => []);
    list.removeWhere((r) => r['page_number'] == values['page_number']);
    list.add(Map<String, dynamic>.from(values));
    return 1;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final list = store[table] ?? [];
    if (where != null && where.contains('page_number = ?') && whereArgs != null) {
      final target = whereArgs.first;
      list.removeWhere((r) => r['page_number'] == target);
    } else {
      list.clear();
    }
    return 1;
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action, {bool? exclusive}) async {
    final fakeTxn = _FakeTransaction(this);
    return action(fakeTxn);
  }

  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTransaction implements Transaction {
  final _FakeDatabase _db;
  _FakeTransaction(this._db);

  @override
  Batch batch() => _FakeBatch(_db);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBatch implements Batch {
  final _FakeDatabase _db;
  final List<void Function()> _actions = [];

  _FakeBatch(this._db);

  @override
  void insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    _actions.add(() {
      _db.insert(table, values, conflictAlgorithm: conflictAlgorithm);
    });
  }

  @override
  Future<List<Object?>> commit({
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) async {
    for (final action in _actions) {
      action();
    }
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
