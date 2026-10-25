import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../../core/constants/app_policy.dart';
import '../models/shamela_models.dart';
import 'shamela_download_manager.dart';
import 'shamela_html_parser.dart';

/// Hardened remote client for fetching Maktaba Shamela book pages and table of contents.
///
/// Enforces:
/// 1. HTTP Client test seam for deterministic injection in tests.
/// 2. Raw-response byte limits while streaming with immediate socket cancellation.
/// 3. Bounded TOC candidate node processing and throttled concurrent worker requests.
/// 4. Incomplete/truncated TOC protection ensuring partial results are not cached.
class ShamelaRemoteFetcher {
  const ShamelaRemoteFetcher._();

  static http.Client? _customHttpClient;
  static final http.Client _defaultHttpClient = http.Client();

  static http.Client get httpClient => _customHttpClient ?? _defaultHttpClient;
  static void setHttpClient(http.Client? client) => _customHttpClient = client;
  static void resetHttpClient() => _customHttpClient = null;

  /// Streamed HTTP GET with strict byte ceiling and immediate stream cancellation.
  static Future<String> fetchStreamedStringWithLimit(
    Uri url, {
    required int maxBytes,
    Map<String, String>? headers,
    Duration timeout = AppPolicy.networkTimeout,
  }) async {
    final request = http.Request('GET', url);
    if (headers != null) request.headers.addAll(headers);

    final streamedResponse = await httpClient.send(request).timeout(timeout);

    if (streamedResponse.statusCode == 404) {
      throw Exception('صفحة غير متوفرة في الكتاب (404)');
    }
    if (streamedResponse.statusCode != 200) {
      throw Exception(
        'تعذر تحميل المحتوى من المكتبة الشاملة (${streamedResponse.statusCode})',
      );
    }

    final contentLength = streamedResponse.contentLength;
    if (contentLength != null && contentLength > maxBytes) {
      throw ShamelaDownloadException(
        'حجم الاستجابة ($contentLength بايت) يتجاوز الحد الأقصى ($maxBytes بايت)',
      );
    }

    final bytesBuilder = BytesBuilder(copy: false);
    int totalBytes = 0;
    final completer = Completer<List<int>>();
    late final StreamSubscription<List<int>> subscription;

    subscription = streamedResponse.stream.listen(
      (chunk) {
        totalBytes += chunk.length;
        if (totalBytes > maxBytes) {
          subscription.cancel();
          if (!completer.isCompleted) {
            completer.completeError(
              ShamelaDownloadException(
                'تم إلغاء الاستجابة لتجاوزها الحد الأقصى للبيانات ($maxBytes بايت)',
              ),
            );
          }
          return;
        }
        bytesBuilder.add(chunk);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(bytesBuilder.takeBytes());
        }
      },
      cancelOnError: true,
    );

    final bytes = await completer.future.timeout(
      timeout,
      onTimeout: () {
        subscription.cancel();
        throw TimeoutException('انتهت مهلة استلام البيانات من الخادم', timeout);
      },
    );

    return utf8.decode(bytes, allowMalformed: true);
  }

  /// Fetch and parse a single page over the network with byte ceiling protection.
  static Future<ShamelaPage> fetchRemotePage({
    required int bookId,
    required int pageNumber,
  }) async {
    final url = Uri.parse('https://shamela.ws/book/$bookId/$pageNumber');
    final html = await fetchStreamedStringWithLimit(
      url,
      maxBytes: AppPolicy.maxShamelaPageBytes,
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml',
        'Accept-Language': 'ar,en;q=0.9',
      },
    );
    return ShamelaHtmlParser.parsePageHtml(bookId, pageNumber, html);
  }

  /// Fetch table of contents over network with bounded concurrency and incomplete cache guard.
  static Future<List<ShamelaChapter>> fetchRemoteTableOfContents({
    required int bookId,
    required void Function(int maxChapterPage) onDiscoveredTotalPages,
    required Future<void> Function(List<ShamelaChapter> chapters) onCommitValidFihris,
  }) async {
    try {
      final url = Uri.parse('https://shamela.ws/book/$bookId');
      final html = await fetchStreamedStringWithLimit(
        url,
        maxBytes: AppPolicy.maxShamelaTocCoverBytes,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      );

      final linkRegex = RegExp(
        r"""<a[^>]+href=["'](?:https://shamela\.ws)?/book/\d+/(\d+)["'][^>]*>(.*?)</a>""",
      );

      final Map<int, String> chaptersMap = {};

      // A. Extract all direct chapters on cover page
      for (final m in linkRegex.allMatches(html)) {
        final pageNum = int.tryParse(m.group(1)!);
        final rawTitle = ShamelaHtmlParser.cleanHtml(m.group(2)!);

        if (pageNum != null &&
            rawTitle.isNotEmpty &&
            rawTitle != '*' &&
            !rawTitle.contains('تصفح') &&
            !rawTitle.contains('الرئيسية')) {
          chaptersMap[pageNum] = rawTitle;
        }
      }

      // B. Check for expandable tree nodes with fanout & concurrency bounds
      final rootMatches = RegExp(
        r"""data-id=["'](\d+)["'][^>]*data-book-id=["'](\d+)["']""",
      ).allMatches(html).toList();

      bool isTruncated = false;
      bool hasChildErrors = false;

      if (rootMatches.isNotEmpty) {
        if (rootMatches.length > AppPolicy.maxShamelaTocNodes) {
          isTruncated = true;
        }
        final candidateNodes =
            rootMatches.take(AppPolicy.maxShamelaTocNodes).toList();
        final concurrency = AppPolicy.maxShamelaConcurrentRequests;
        for (int i = 0; i < candidateNodes.length; i += concurrency) {
          final chunk = candidateNodes.sublist(
            i,
            i + concurrency > candidateNodes.length
                ? candidateNodes.length
                : i + concurrency,
          );
          await Future.wait(chunk.map((rm) async {
            final dataId = rm.group(1)!;
            final bId = rm.group(2)!;
            try {
              final childUrl =
                  Uri.parse('https://shamela.ws/ajax/titlechilds/$bId/$dataId');
              final childHtml = await fetchStreamedStringWithLimit(
                childUrl,
                maxBytes: AppPolicy.maxShamelaTocChildBytes,
                headers: const {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                  'X-Requested-With': 'XMLHttpRequest',
                },
              );

              for (final cm in linkRegex.allMatches(childHtml)) {
                final cp = int.tryParse(cm.group(1)!);
                var ct = ShamelaHtmlParser.cleanHtml(cm.group(2)!);
                if (ct.startsWith('-')) ct = ct.substring(1).trim();
                if (cp != null && ct.isNotEmpty && ct != '*') {
                  chaptersMap[cp] = ct;
                }
              }
            } catch (_) {
              hasChildErrors = true;
            }
          }));
        }
      }

      final sortedPages = chaptersMap.keys.toList()..sort();
      final List<ShamelaChapter> chapters = sortedPages
          .map((p) => ShamelaChapter(title: chaptersMap[p]!, pageNumber: p))
          .toList();

      final maxChapterPage =
          chaptersMap.keys.fold<int>(0, (prev, elem) => elem > prev ? elem : prev);
      if (maxChapterPage > 0) {
        onDiscoveredTotalPages(maxChapterPage);
      }

      // Only cache to SQLite when the table of contents was fetched completely
      // without truncation or child node expansion errors.
      if (chapters.isNotEmpty && !isTruncated && !hasChildErrors) {
        await onCommitValidFihris(chapters);
      }

      return chapters;
    } catch (_) {}

    return [];
  }
}
