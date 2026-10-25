import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_policy.dart';
import '../database/quran_database.dart';
import 'quran_page_service.dart';

typedef PageGetter = Future<QuranPageData?> Function(int pageNumber);
typedef PageSaver = Future<void> Function(int pageNumber, QuranPageData data);

/// Service for background chunk syncing of Quran page data from quran.com API
/// into local SQLite database for offline Mushaf rendering.
/// Hardened with streaming byte limits, input validation, in-flight deduplication, and testing seams.
class QuranSyncService {
  static const String _chunkKeyPrefix = 'quran_chunk_synced_';
  static const String _baseUrl = 'https://api.quran.com/api/v4';

  // Singleton
  static final QuranSyncService _instance = QuranSyncService._();
  QuranSyncService._();
  static QuranSyncService get instance => _instance;

  final StreamController<double> _progressController =
      StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  // Track active downloads to prevent duplicate executions
  final Set<int> _activeDownloads = {};
  final Map<int, Future<void>> _inFlightChunkDownloads = {};

  // ═══════════════════════════════════════════════════════════════════════════
  // HTTP TEST SEAM & TESTING HOOKS
  // ═══════════════════════════════════════════════════════════════════════════

  static http.Client? _injectedClient;
  static http.Client? _defaultClient;
  static PageGetter? _testPageGetter;
  static PageSaver? _testPageSaver;

  @visibleForTesting
  static Duration retryDelay = AppPolicy.oneSecond;

  @visibleForTesting
  static void setHttpClient(http.Client client) {
    _injectedClient = client;
  }

  @visibleForTesting
  static void resetHttpClient() {
    _injectedClient?.close();
    _injectedClient = null;
    _defaultClient?.close();
    _defaultClient = null;
  }

  static http.Client get _client =>
      _injectedClient ?? (_defaultClient ??= http.Client());

  @visibleForTesting
  static void setDatabaseHooks({PageGetter? getPage, PageSaver? savePage}) {
    _testPageGetter = getPage;
    _testPageSaver = savePage;
  }

  @visibleForTesting
  static void resetForTesting() {
    resetHttpClient();
    retryDelay = AppPolicy.oneSecond;
    _testPageGetter = null;
    _testPageSaver = null;
    _instance._activeDownloads.clear();
    _instance._inFlightChunkDownloads.clear();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INPUT BOUNDS VALIDATION
  // ═══════════════════════════════════════════════════════════════════════════

  static bool isValidChunkIndex(int chunkIndex) =>
      chunkIndex >= 1 && chunkIndex <= 31;

  static bool isValidPageNumber(int pageNumber) =>
      pageNumber >= 1 && pageNumber <= 604;

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAMED HTTP GET WITH BYTE CEILING & EARLY CANCELLATION
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<String> _fetchStreamedStringWithLimit(
    Uri uri, {
    required int maxBytes,
    required Duration timeout,
  }) async {
    final request = http.Request('GET', uri)
      ..headers.addAll({
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
        'Accept': 'application/json',
      });

    final streamedResponse = await _client.send(request).timeout(timeout);

    if (streamedResponse.statusCode != 200) {
      throw Exception('HTTP error ${streamedResponse.statusCode}');
    }

    final contentLength = streamedResponse.contentLength;
    if (contentLength != null && contentLength > maxBytes) {
      throw Exception('Response exceeded maximum byte limit ($maxBytes)');
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
              Exception('Response stream cancelled: exceeded $maxBytes bytes'),
            );
          }
          return;
        }
        bytesBuilder.add(chunk);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete(bytesBuilder.takeBytes());
      },
      cancelOnError: true,
    );

    final bytes = await completer.future.timeout(
      timeout,
      onTimeout: () {
        subscription.cancel();
        throw TimeoutException('Request timed out', timeout);
      },
    );

    return utf8.decode(bytes, allowMalformed: true);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHUNK SYNC & INITIAL CONTENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if a specific chunk (20 pages) is downloaded
  Future<bool> isChunkDownloaded(int chunkIndex) async {
    if (!isValidChunkIndex(chunkIndex)) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_chunkKeyPrefix$chunkIndex') ?? false;
  }

  /// Download Initial content (Chunk 1: Pages 1-20)
  /// Blocking, fast, essential for First Launch.
  Future<void> downloadInitialContent() async {
    if (await isChunkDownloaded(1)) return;
    await downloadChunk(1);
  }

  /// Download a logical chunk of pages (Index 1..31)
  /// Each chunk is 20 pages (Juz-like size).
  /// Synchronously joins existing in-flight download if already in progress.
  Future<void> downloadChunk(int chunkIndex) {
    if (!isValidChunkIndex(chunkIndex)) return Future.value();

    // Join in-flight download if one is already active (join/no-op)
    final existingFuture = _inFlightChunkDownloads[chunkIndex];
    if (existingFuture != null) return existingFuture;

    final completer = Completer<void>();
    _inFlightChunkDownloads[chunkIndex] = completer.future;

    _executeDownloadChunk(chunkIndex).then((_) {
      if (!completer.isCompleted) completer.complete();
    }).catchError((Object error, StackTrace stackTrace) {
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
    }).whenComplete(() {
      _inFlightChunkDownloads.remove(chunkIndex);
    });

    return completer.future;
  }

  Future<void> _executeDownloadChunk(int chunkIndex) async {
    if (await isChunkDownloaded(chunkIndex)) return;

    _activeDownloads.add(chunkIndex);
    _progressController.add(0.0);

    try {
      final startPage = (chunkIndex - 1) * 20 + 1;
      final endPage = (chunkIndex * 20).clamp(1, 604);
      final totalPages = endPage - startPage + 1;

      debugPrint(
        'Starting download for Chunk $chunkIndex (Pages $startPage-$endPage)',
      );

      for (int i = 0; i < totalPages; i++) {
        final pageNum = startPage + i;

        // Check DB first (Checkpointing)
        final existing = _testPageGetter != null
            ? await _testPageGetter!(pageNum)
            : await QuranDatabase.instance.getPage(pageNum);

        if (existing == null) {
          await _fetchAndSavePage(pageNum);
        }

        // Progress for this chunk operation
        _progressController.add((i + 1) / totalPages);

        // Gentle throttle
        await Future.delayed(AppPolicy.microPause);
      }

      // Mark as done
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_chunkKeyPrefix$chunkIndex', true);
      debugPrint('Chunk $chunkIndex Completed.');
    } catch (e) {
      debugPrint('Chunk $chunkIndex Failed: $e');
      _progressController.addError(e);
      rethrow;
    } finally {
      _activeDownloads.remove(chunkIndex);
    }
  }

  /// Single Page Fetcher (Internal) with byte cap and retry
  Future<void> _fetchAndSavePage(int pageNumber) async {
    if (!isValidPageNumber(pageNumber)) {
      throw ArgumentError('Invalid page number: $pageNumber');
    }

    int attempts = 0;
    while (attempts < 3) {
      try {
        final uri = Uri.parse(
          '$_baseUrl/verses/by_page/$pageNumber?fields=text_uthmani',
        );

        final body = await _fetchStreamedStringWithLimit(
          uri,
          maxBytes: AppPolicy.maxQuranPageResponseBytes,
          timeout: AppPolicy.networkRetry,
        );

        final json = jsonDecode(body);
        final data = QuranPageData.fromApiResponse(pageNumber, json);

        if (_testPageSaver != null) {
          await _testPageSaver!(pageNumber, data);
        } else {
          await QuranDatabase.instance.savePage(pageNumber, data);
        }
        return;
      } catch (e) {
        attempts++;
        if (attempts >= 3) rethrow;
        await Future.delayed(retryDelay);
      }
    }
  }
}
