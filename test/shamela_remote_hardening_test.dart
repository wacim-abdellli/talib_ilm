import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:talib_ilm/core/constants/app_policy.dart';
import 'package:talib_ilm/features/ilm/data/services/shamela_service.dart';

/// Test HTTP client that routes requests to custom streaming handlers.
class TestStreamingHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) handler;
  TestStreamingHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => handler(request);
}

/// In-memory fake database implementing SQLite queries for Shamela offline and TOC tests.
class FakeShamelaFullDatabase implements Database {
  final Map<int, Map<int, Map<String, Object?>>> pages = {};
  final Map<int, List<Map<String, Object?>>> fihris = {};

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
    final bookId = whereArgs?.first as int?;
    if (table == ShamelaService.tableNamePages) {
      if (bookId != null && pages.containsKey(bookId)) {
        if (whereArgs != null && whereArgs.length > 1) {
          final pageNum = whereArgs[1] as int?;
          final row = pages[bookId]?[pageNum];
          return row != null ? [row] : [];
        }
        return pages[bookId]!.values.toList();
      }
      return [];
    } else if (table == 'shamela_fihris') {
      if (bookId != null && fihris.containsKey(bookId)) {
        final list = List<Map<String, Object?>>.from(fihris[bookId]!);
        list.sort((a, b) => (a['page_num'] as int).compareTo(b['page_num'] as int));
        return list;
      }
      return [];
    }
    return [];
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final bookId = values['book_id'] as int?;
    if (bookId == null) return 0;
    if (table == ShamelaService.tableNamePages) {
      final pageNum = values['page_num'] as int?;
      if (pageNum != null) {
        pages.putIfAbsent(bookId, () => {})[pageNum] = Map<String, Object?>.from(values);
      }
    } else if (table == 'shamela_fihris') {
      fihris.putIfAbsent(bookId, () => []);
      fihris[bookId]!.removeWhere((row) => row['page_num'] == values['page_num']);
      fihris[bookId]!.add(Map<String, Object?>.from(values));
    }
    return 1;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final bookId = whereArgs?.first as int?;
    if (bookId == null) return 0;
    if (table == ShamelaService.tableNamePages) {
      pages.remove(bookId);
    } else if (table == 'shamela_fihris') {
      fihris.remove(bookId);
    }
    return 1;
  }

  @override
  Batch batch() => _FakeBatch(this);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBatch implements Batch {
  final FakeShamelaFullDatabase db;
  final List<Future<void> Function()> ops = [];

  _FakeBatch(this.db);

  @override
  void insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    ops.add(() async {
      await db.insert(table, values, conflictAlgorithm: conflictAlgorithm);
    });
  }

  @override
  Future<List<Object?>> commit({
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) async {
    for (final op in ops) {
      await op();
    }
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeShamelaFullDatabase fakeDb;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeDb = FakeShamelaFullDatabase();
    ShamelaService.setMockDatabase(fakeDb);
    ShamelaService.resetHttpClient();
  });

  tearDown(() {
    ShamelaService.setMockDatabase(null);
    ShamelaService.resetHttpClient();
  });

  group('Shamela Remote Fetching Hardening (R78)', () {
    test('Seam: ShamelaService.setHttpClient enables focused test injection', () async {
      bool handlerCalled = false;
      final testClient = TestStreamingHttpClient((request) async {
        handlerCalled = true;
        const html = '<html><body><div class="book-title">صفحة اختبارية</div>'
            '<div class="nass">المحتوى التجريبي لكتاب التوحيد</div></body></html>';
        final bytes = utf8.encode(html);
        return http.StreamedResponse(
          Stream.value(bytes),
          200,
          contentLength: bytes.length,
        );
      });

      ShamelaService.setHttpClient(testClient);
      final page = await ShamelaService.fetchPage(bookId: 9999, pageNumber: 1);

      expect(handlerCalled, isTrue);
      expect(page.content, contains('المحتوى التجريبي لكتاب التوحيد'));
    });

    test('Risk 1 Reproduction & Fix: Oversized page streams are cancelled and throw', () async {
      bool streamCancelled = false;
      final controller = StreamController<List<int>>(onCancel: () {
        streamCancelled = true;
      });

      // Deliver chunks exceeding 512 KB (e.g. 3 chunks of 200 KB = 600 KB)
      final chunk200kb = Uint8List(200 * 1024);
      final testClient = TestStreamingHttpClient((request) async {
        Future<void>.microtask(() async {
          controller.add(chunk200kb);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk200kb);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk200kb);
          await controller.close();
        });

        return http.StreamedResponse(
          controller.stream,
          200,
        );
      });

      ShamelaService.setHttpClient(testClient);

      expect(
        () => ShamelaService.fetchPage(bookId: 9999, pageNumber: 1),
        throwsA(isA<ShamelaDownloadException>().having(
          (e) => e.message,
          'message',
          contains('تم إلغاء الاستجابة لتجاوزها الحد الأقصى'),
        )),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(streamCancelled, isTrue, reason: 'Stream subscription must be cancelled on byte limit breach');

      // Verify oversized page was NOT saved into database
      final cached = await fakeDb.query(
        ShamelaService.tableNamePages,
        where: 'book_id = ? AND page_num = ?',
        whereArgs: [9999, 1],
      );
      expect(cached.isEmpty, isTrue, reason: 'Oversized page response must never be committed to SQLite');
    });

    test('Risk 1 Reproduction & Fix: Oversized TOC cover streams (>1 MB) are rejected', () async {
      bool streamCancelled = false;
      final controller = StreamController<List<int>>(onCancel: () {
        streamCancelled = true;
      });

      // Deliver chunks exceeding 1 MB (3 chunks of 400 KB = 1.2 MB)
      final chunk400kb = Uint8List(400 * 1024);
      final testClient = TestStreamingHttpClient((request) async {
        Future<void>.microtask(() async {
          controller.add(chunk400kb);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk400kb);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          if (!controller.isClosed) controller.add(chunk400kb);
          await controller.close();
        });

        return http.StreamedResponse(
          controller.stream,
          200,
        );
      });

      ShamelaService.setHttpClient(testClient);

      final chapters = await ShamelaService.fetchTableOfContents(8888);
      expect(chapters, isEmpty, reason: 'Oversized TOC cover must safely return empty list');

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(streamCancelled, isTrue, reason: 'TOC cover stream must be aborted immediately');

      // Verify no corrupted TOC in SQLite
      final cached = await fakeDb.query(
        'shamela_fihris',
        where: 'book_id = ?',
        whereArgs: [8888],
      );
      expect(cached.isEmpty, isTrue);
    });

    test('Risk 2 Reproduction & Fix: TOC child node expansion bounds total nodes and throttles concurrency', () async {
      int activeRequests = 0;
      int maxObservedConcurrency = 0;
      final requestedChildIds = <int>{};

      // Generate a cover page with 65 expandable nodes (> 50 limit)
      final buffer = StringBuffer('<html><body><div class="fihris">');
      for (int i = 1; i <= 65; i++) {
        buffer.write('<button class="exp_bu" data-id="$i" data-book-id="7777">+</button>');
      }
      buffer.write('</div></body></html>');
      final coverBytes = utf8.encode(buffer.toString());

      final testClient = TestStreamingHttpClient((request) async {
        final path = request.url.path;
        if (path.contains('/ajax/titlechilds/7777/')) {
          activeRequests++;
          maxObservedConcurrency = max(maxObservedConcurrency, activeRequests);

          final childId = int.parse(path.split('/').last);
          requestedChildIds.add(childId);

          // Simulate realistic async network roundtrip
          await Future<void>.delayed(const Duration(milliseconds: 20));
          activeRequests--;

          final childHtml = '<a href="/book/7777/$childId">باب رقم $childId</a>';
          final b = utf8.encode(childHtml);
          return http.StreamedResponse(Stream.value(b), 200, contentLength: b.length);
        } else {
          return http.StreamedResponse(
            Stream.value(coverBytes),
            200,
            contentLength: coverBytes.length,
          );
        }
      });

      ShamelaService.setHttpClient(testClient);

      final chapters = await ShamelaService.fetchTableOfContents(7777);

      expect(chapters.isNotEmpty, isTrue);
      // Fanout bound: Must only process up to maxShamelaTocNodes (50)
      expect(requestedChildIds.length, equals(AppPolicy.maxShamelaTocNodes));
      expect(requestedChildIds.contains(51), isFalse, reason: 'Child nodes beyond cap must be truncated');
      expect(requestedChildIds.contains(65), isFalse);

      // Concurrency bound: Must never exceed maxShamelaConcurrentRequests (4)
      expect(maxObservedConcurrency, lessThanOrEqualTo(AppPolicy.maxShamelaConcurrentRequests));
    });

    test('Risk 2 & Invariant: Truncated TOC is NOT cached to SQLite as complete', () async {
      // Setup cover page with 55 nodes (exceeds cap of 50)
      final buffer = StringBuffer('<html><body><div class="fihris">');
      for (int i = 1; i <= 55; i++) {
        buffer.write('<button class="exp_bu" data-id="$i" data-book-id="6666">+</button>');
      }
      buffer.write('</div></body></html>');
      final coverBytes = utf8.encode(buffer.toString());

      final testClient = TestStreamingHttpClient((request) async {
        final path = request.url.path;
        if (path.contains('/ajax/titlechilds/6666/')) {
          final childId = int.parse(path.split('/').last);
          final childHtml = '<a href="/book/6666/$childId">فصل $childId</a>';
          final b = utf8.encode(childHtml);
          return http.StreamedResponse(Stream.value(b), 200, contentLength: b.length);
        }
        return http.StreamedResponse(Stream.value(coverBytes), 200, contentLength: coverBytes.length);
      });

      ShamelaService.setHttpClient(testClient);

      final chapters = await ShamelaService.fetchTableOfContents(6666);
      expect(chapters.length, equals(50), reason: 'Returns truncated list in memory for active reading');

      // Invariant: Truncated TOC must NOT be committed to SQLite persistent cache
      final cachedRows = await fakeDb.query(
        'shamela_fihris',
        where: 'book_id = ?',
        whereArgs: [6666],
      );
      expect(cachedRows.isEmpty, isTrue, reason: 'Truncated TOC must not be cached as complete');
    });

    test('Risk 2 & Invariant: Child node network failure prevents overwriting valid SQLite TOC', () async {
      // 1. Pre-seed SQLite cache with valid existing TOC
      await fakeDb.insert('shamela_fihris', {'book_id': 5555, 'page_num': 1, 'title': 'مقدمة الكتاب الأصلي'});
      await fakeDb.insert('shamela_fihris', {'book_id': 5555, 'page_num': 10, 'title': 'باب الطهارة الأصلي'});

      // 2. Cover page has 3 expandable nodes
      const coverHtml = '<html><body><div class="fihris">'
          '<button class="exp_bu" data-id="1" data-book-id="5555">+</button>'
          '<button class="exp_bu" data-id="2" data-book-id="5555">+</button>'
          '<button class="exp_bu" data-id="3" data-book-id="5555">+</button>'
          '</div></body></html>';
      final coverBytes = utf8.encode(coverHtml);

      // Child node 2 fails with 500 Internal Server Error
      final testClient = TestStreamingHttpClient((request) async {
        final path = request.url.path;
        if (path.contains('/ajax/titlechilds/5555/2')) {
          return http.StreamedResponse(
            Stream.value(utf8.encode('Internal Server Error')),
            500,
          );
        } else if (path.contains('/ajax/titlechilds/5555/')) {
          final b = utf8.encode('<a href="/book/5555/5">فصل فرعي</a>');
          return http.StreamedResponse(Stream.value(b), 200, contentLength: b.length);
        }
        return http.StreamedResponse(Stream.value(coverBytes), 200, contentLength: coverBytes.length);
      });

      ShamelaService.setHttpClient(testClient);

      // Force refresh to bypass in-memory check
      final chapters = await ShamelaService.fetchTableOfContents(5555, forceRefresh: true);
      expect(chapters.isNotEmpty, isTrue);

      // Invariant: Because child node 2 failed, the existing valid SQLite fihris was preserved intact!
      final preservedRows = await fakeDb.query(
        'shamela_fihris',
        where: 'book_id = ?',
        whereArgs: [5555],
      );
      expect(preservedRows.length, equals(2));
      expect(preservedRows.first['title'], equals('مقدمة الكتاب الأصلي'));
      expect(preservedRows.last['title'], equals('باب الطهارة الأصلي'));
    });

    test('Normal Flow: Complete, untruncated, error-free TOC is safely cached to SQLite', () async {
      const coverHtml = '<html><body><div class="fihris">'
          '<a href="/book/4444/1">المقدمة العامة</a>'
          '<button class="exp_bu" data-id="10" data-book-id="4444">+</button>'
          '</div></body></html>';
      final coverBytes = utf8.encode(coverHtml);

      final testClient = TestStreamingHttpClient((request) async {
        final path = request.url.path;
        if (path.contains('/ajax/titlechilds/4444/10')) {
          final b = utf8.encode('<a href="/book/4444/20">الفصل الأول: في التوحيد</a>');
          return http.StreamedResponse(Stream.value(b), 200, contentLength: b.length);
        }
        return http.StreamedResponse(Stream.value(coverBytes), 200, contentLength: coverBytes.length);
      });

      ShamelaService.setHttpClient(testClient);

      final chapters = await ShamelaService.fetchTableOfContents(4444);
      expect(chapters.length, equals(2));
      expect(chapters[0].title, equals('المقدمة العامة'));
      expect(chapters[0].pageNumber, equals(1));
      expect(chapters[1].title, equals('الفصل الأول: في التوحيد'));
      expect(chapters[1].pageNumber, equals(20));

      // Successfully saved to SQLite persistent cache
      final cachedRows = await fakeDb.query(
        'shamela_fihris',
        where: 'book_id = ?',
        whereArgs: [4444],
      );
      expect(cachedRows.length, equals(2));
      expect(cachedRows[0]['title'], equals('المقدمة العامة'));
      expect(cachedRows[1]['title'], equals('الفصل الأول: في التوحيد'));
    });
  });
}
