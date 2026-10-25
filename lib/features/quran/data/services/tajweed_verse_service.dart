import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quran/quran.dart' as quran;
import 'package:talib_ilm/app/theme/app_policy.dart';

/// Fetches `text_uthmani_tajweed` from Quran.com with streaming byte caps,
/// in-flight deduplication, bounded FIFO memory caches, and input bounds checking.
class TajweedVerseService {
  TajweedVerseService._();

  static http.Client? _testClient;
  static http.Client? _sharedClient;

  @visibleForTesting
  static void setHttpClient(http.Client client) => _testClient = client;

  @visibleForTesting
  static void resetHttpClient() => _testClient = null;

  static http.Client get httpClient =>
      _testClient ?? (_sharedClient ??= http.Client());

  static final Map<String, String> _ayahCache = {};
  static final Map<int, Map<int, String>> _surahCache = {};
  static final Map<int, Future<Map<int, String>>> _inFlightSurahs = {};

  static const Duration _kApiTimeout = Duration(seconds: 4); // ui-lint: allow network timeout

  /// Validates surah bound (1..114).
  static bool isValidSurah(int surah) => surah >= 1 && surah <= 114;

  /// Validates surah and ayah bound (1..verseCount).
  static bool isValidVerse(int surah, int ayah) {
    if (!isValidSurah(surah)) return false;
    final maxVerses = quran.getVerseCount(surah);
    return ayah >= 1 && ayah <= maxVerses;
  }

  /// Gets cached or fetched Tajweed markup for a specific Ayah.
  /// Rejects invalid verse identifiers immediately without network or cache mutation.
  static Future<String?> getAyahMarkup(int surah, int ayah) async {
    if (!isValidVerse(surah, ayah)) {
      return null;
    }

    final key = '$surah:$ayah';
    if (_ayahCache.containsKey(key)) {
      return _ayahCache[key];
    }

    final surahMap = await getSurahMarkups(surah);
    return surahMap[ayah];
  }

  /// Gets all Tajweed markups for a Surah with in-flight deduplication,
  /// streaming byte limit, and safe non-empty cache retention.
  static Future<Map<int, String>> getSurahMarkups(int surah) async {
    if (!isValidSurah(surah)) {
      return const <int, String>{};
    }

    if (_surahCache.containsKey(surah)) {
      return _surahCache[surah]!;
    }

    if (_inFlightSurahs.containsKey(surah)) {
      return await _inFlightSurahs[surah]!;
    }

    final future = _fetchAndCacheSurah(surah);
    _inFlightSurahs[surah] = future;

    try {
      return await future;
    } finally {
      _inFlightSurahs.remove(surah);
    }
  }

  /// Internal worker fetching chapter Tajweed JSON from Quran.com with streaming byte caps.
  static Future<Map<int, String>> _fetchAndCacheSurah(int surah) async {
    final map = <int, String>{};
    try {
      final uri = Uri.parse(
        'https://api.quran.com/api/v4/verses/by_chapter/$surah'
        '?per_page=300&words=false&fields=text_uthmani_tajweed',
      );
      final body = await _fetchStreamedStringWithLimit(
        uri,
        maxBytes: AppPolicy.maxTajweedChapterResponseBytes,
        headers: const {'Accept': 'application/json'},
      );

      final data = json.decode(body) as Map<String, dynamic>;
      final verses = data['verses'] as List<dynamic>? ?? [];
      for (final raw in verses) {
        if (raw is Map<String, dynamic>) {
          final ayah = raw['verse_number'] as int?;
          final markup = raw['text_uthmani_tajweed'] as String?;
          if (ayah != null && markup != null && markup.isNotEmpty) {
            map[ayah] = markup;
            _putAyahMemory('$surah:$ayah', markup);
          }
        }
      }
    } catch (_) {}

    // CRUCIAL: Only store non-empty maps in the memory cache.
    // If the network request fails, times out, or gets cancelled, an empty map
    // must NOT poison the session cache so subsequent calls can retry safely.
    if (map.isNotEmpty) {
      _putSurahMemory(surah, map);
    }

    return map;
  }

  /// Streamed HTTP GET with strict byte ceiling and early cancellation.
  static Future<String> _fetchStreamedStringWithLimit(
    Uri url, {
    required int maxBytes,
    Map<String, String>? headers,
    Duration timeout = _kApiTimeout,
  }) async {
    final request = http.Request('GET', url);
    if (headers != null) request.headers.addAll(headers);

    final streamedResponse = await httpClient.send(request).timeout(timeout);

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
        throw TimeoutException('Tajweed request timed out', timeout);
      },
    );

    return utf8.decode(bytes, allowMalformed: true);
  }

  static void _putSurahMemory(int surah, Map<int, String> markups) {
    if (_surahCache.length >= AppPolicy.maxTajweedSurahMemoryEntries &&
        !_surahCache.containsKey(surah)) {
      _surahCache.remove(_surahCache.keys.first);
    }
    _surahCache[surah] = markups;
  }

  static void _putAyahMemory(String key, String markup) {
    if (_ayahCache.length >= AppPolicy.maxTajweedAyahMemoryEntries &&
        !_ayahCache.containsKey(key)) {
      _ayahCache.remove(_ayahCache.keys.first);
    }
    _ayahCache[key] = markup;
  }

  /// Clears in-memory caches and pending in-flight requests.
  static void clearMemoryCache() {
    _ayahCache.clear();
    _surahCache.clear();
    _inFlightSurahs.clear();
  }
}
