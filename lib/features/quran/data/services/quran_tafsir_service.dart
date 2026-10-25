import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_policy.dart';

enum TafsirScholar {
  muyassar, // التفسير الميسر (مجمع الملك فهد)
  saadi, // تفسير السعدي
  ibnKathir, // تفسير ابن كثير
  baghawi, // تفسير البغوي
  englishIbnKathir, // English Ibn Kathir & Translation
}

const Duration _kApiTimeout = Duration(seconds: 4); // ui-lint: allow network timeout

class WordMeaning {
  final String word;
  final String meaning;
  final String? morphology;
  final String? transliteration;

  const WordMeaning({
    required this.word,
    required this.meaning,
    this.morphology,
    this.transliteration,
  });
}

/// Hardened service for fetching Ayah Tafsir and Word-by-Word data.
///
/// Features:
/// 1. HTTP client test seam for deterministic mock injection.
/// 2. Strict raw-response streaming byte ceilings with early cancellation.
/// 3. Complete input validation against authentic Quran verse boundaries.
/// 4. Bounded RAM cache capacity with FIFO eviction to prevent memory growth.
/// 5. In-flight request deduplication preventing redundant concurrent network requests.
class QuranTafsirService {
  QuranTafsirService._();

  static http.Client? _customHttpClient;
  static final http.Client _defaultHttpClient = http.Client();

  @visibleForTesting
  static http.Client get httpClient => _customHttpClient ?? _defaultHttpClient;

  @visibleForTesting
  static void setHttpClient(http.Client? client) => _customHttpClient = client;

  @visibleForTesting
  static void resetHttpClient() => _customHttpClient = null;

  static final Map<String, String> _memCache = {};
  static final Map<String, List<WordMeaning>> _wordsCache = {};
  static final Map<String, Future<String>> _inFlightTafsir = {};
  static final Map<String, Future<List<WordMeaning>>> _inFlightWords = {};

  /// Validate that the given surah and ayah represent an authentic Quranic verse.
  static bool isValidVerse(int surahNumber, int ayahNumber) {
    if (surahNumber < 1 || surahNumber > 114) return false;
    final totalVerses = quran.getVerseCount(surahNumber);
    return ayahNumber >= 1 && ayahNumber <= totalVerses;
  }

  static void _putTafsirMemory(String key, String value) {
    if (_memCache.length >= AppPolicy.maxTafsirMemoryEntries) {
      _memCache.remove(_memCache.keys.first);
    }
    _memCache[key] = value;
  }

  static void _putWordsMemory(String key, List<WordMeaning> value) {
    if (_wordsCache.length >= AppPolicy.maxWordMeaningMemoryEntries) {
      _wordsCache.remove(_wordsCache.keys.first);
    }
    _wordsCache[key] = value;
  }

  @visibleForTesting
  static void clearMemoryCache() {
    _memCache.clear();
    _wordsCache.clear();
    _inFlightTafsir.clear();
    _inFlightWords.clear();
  }

  @visibleForTesting
  static int get memCacheSize => _memCache.length;

  @visibleForTesting
  static int get wordsCacheSize => _wordsCache.length;

  static String getScholarName(TafsirScholar scholar) {
    switch (scholar) {
      case TafsirScholar.muyassar:
        return 'التفسير الميسر';
      case TafsirScholar.saadi:
        return 'تفسير السعدي';
      case TafsirScholar.ibnKathir:
        return 'تفسير ابن كثير';
      case TafsirScholar.englishIbnKathir:
        return 'English (Tafsir & Translation)';
      case TafsirScholar.baghawi:
        return 'تفسير البغوي';
    }
  }

  static String getScholarAuthor(TafsirScholar scholar) {
    switch (scholar) {
      case TafsirScholar.muyassar:
        return 'مجمع الملك فهد لطباعة المصحف الشريف';
      case TafsirScholar.saadi:
        return 'الشيخ عبد الرحمن بن ناصر السعدي';
      case TafsirScholar.ibnKathir:
        return 'الحافظ ابن كثير الدمشقي';
      case TafsirScholar.englishIbnKathir:
        return 'Hafiz Ibn Kathir (English translation)';
      case TafsirScholar.baghawi:
        return 'الإمام الحسين بن مسعود البغوي';
    }
  }

  static String _getCdnTafsirSlug(TafsirScholar scholar) {
    switch (scholar) {
      case TafsirScholar.muyassar:
        return 'ar-tafsir-muyassar';
      case TafsirScholar.saadi:
        return 'ar-tafseer-al-saddi';
      case TafsirScholar.ibnKathir:
        return 'ar-tafsir-ibn-kathir';
      case TafsirScholar.baghawi:
        return 'ar-tafsir-al-baghawi';
      case TafsirScholar.englishIbnKathir:
        return 'en-tafisr-ibn-kathir';
    }
  }

  static int _getTafsirId(TafsirScholar scholar) {
    switch (scholar) {
      case TafsirScholar.muyassar:
        return 16;
      case TafsirScholar.saadi:
        return 91;
      case TafsirScholar.ibnKathir:
        return 14;
      case TafsirScholar.englishIbnKathir:
        return 169;
      case TafsirScholar.baghawi:
        return 94;
    }
  }

  /// Streamed HTTP GET with strict byte ceiling and cancellation.
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
        throw TimeoutException('Tafsir request timed out', timeout);
      },
    );

    return utf8.decode(bytes, allowMalformed: true);
  }

  /// Fetches Tafsir for an Ayah with multi-layer caching, in-flight deduplication, and bounds.
  static Future<String> getTafsir({
    required int surahNumber,
    required int ayahNumber,
    TafsirScholar scholar = TafsirScholar.muyassar,
  }) {
    if (!isValidVerse(surahNumber, ayahNumber)) {
      return Future.value('آية غير صالحة');
    }

    final cacheKey = 'tafsir_v2_${scholar.name}_${surahNumber}_$ayahNumber';

    if (_memCache.containsKey(cacheKey)) {
      return Future.value(_memCache[cacheKey]!);
    }

    if (_inFlightTafsir.containsKey(cacheKey)) {
      return _inFlightTafsir[cacheKey]!;
    }

    final future = _fetchAndCacheTafsir(
      cacheKey: cacheKey,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      scholar: scholar,
    );
    _inFlightTafsir[cacheKey] = future;
    return future.whenComplete(() {
      _inFlightTafsir.remove(cacheKey);
    });
  }

  static Future<String> _fetchAndCacheTafsir({
    required String cacheKey,
    required int surahNumber,
    required int ayahNumber,
    required TafsirScholar scholar,
  }) async {
    // 1. Persistent SharedPreferences cache
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      _putTafsirMemory(cacheKey, cached);
      return cached;
    }

    // 2. Streamed Tafsir CDN source with byte ceiling
    try {
      final slug = _getCdnTafsirSlug(scholar);
      final cdnUrl = Uri.parse(
        'https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir/$slug/$surahNumber/$ayahNumber.json',
      );
      final body = await _fetchStreamedStringWithLimit(
        cdnUrl,
        maxBytes: AppPolicy.maxTafsirResponseBytes,
      );
      final data = json.decode(body);
      final rawText = data['text'] as String? ?? '';
      final cleanText = _cleanHtml(rawText);

      if (cleanText.isNotEmpty) {
        _putTafsirMemory(cacheKey, cleanText);
        await prefs.setString(cacheKey, cleanText);
        return cleanText;
      }
    } catch (_) {}

    // 3. Fallback Quran.com API with byte ceiling and stream cancellation
    try {
      final tafsirId = _getTafsirId(scholar);
      final url = Uri.parse(
        'https://api.quran.com/api/v4/tafsirs/$tafsirId/by_ayah/$surahNumber:$ayahNumber',
      );

      final body = await _fetchStreamedStringWithLimit(
        url,
        maxBytes: AppPolicy.maxTafsirResponseBytes,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 talib_ilm/1.0',
        },
      );

      final data = json.decode(body);
      final rawText = data['tafsir']?['text'] as String? ?? '';
      final cleanText = _cleanHtml(rawText);

      if (cleanText.isNotEmpty) {
        _putTafsirMemory(cacheKey, cleanText);
        await prefs.setString(cacheKey, cleanText);
        return cleanText;
      }
    } catch (_) {}

    // 4. Offline fallback using local bundled Quran translations
    final fallback = quran.getVerseTranslation(surahNumber, ayahNumber);
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return 'تفسير هذه الآية الكريمة: ${quran.getVerse(surahNumber, ayahNumber, verseEndSymbol: false)}';
  }

  /// Returns word meanings from in-memory cache if already fetched, or null.
  static List<WordMeaning>? getCachedWordMeanings(int surahNumber, int ayahNumber) {
    if (!isValidVerse(surahNumber, ayahNumber)) return null;
    return _wordsCache['wbw_${surahNumber}_$ayahNumber'];
  }

  /// Fetches real word-by-word data from Quran.com API with dual RAM + storage caching.
  static Future<List<WordMeaning>> fetchWordMeanings(
    int surahNumber,
    int ayahNumber,
  ) {
    if (!isValidVerse(surahNumber, ayahNumber)) {
      return Future.value(const []);
    }

    final cacheKey = 'wbw_${surahNumber}_$ayahNumber';
    if (_wordsCache.containsKey(cacheKey)) {
      return Future.value(_wordsCache[cacheKey]!);
    }

    if (_inFlightWords.containsKey(cacheKey)) {
      return _inFlightWords[cacheKey]!;
    }

    final future = _fetchAndCacheWordMeanings(
      cacheKey: cacheKey,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
    _inFlightWords[cacheKey] = future;
    return future.whenComplete(() {
      _inFlightWords.remove(cacheKey);
    });
  }

  static Future<List<WordMeaning>> _fetchAndCacheWordMeanings({
    required String cacheKey,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(cacheKey);
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final decoded = json.decode(cachedJson) as List;
        final list = decoded
            .map((item) => WordMeaning(
                  word: item['w'] as String,
                  meaning: item['m'] as String,
                  transliteration: item['t'] as String?,
                ))
            .toList();
        if (list.isNotEmpty) {
          _putWordsMemory(cacheKey, list);
          return list;
        }
      } catch (_) {}
    }

    try {
      final url = Uri.parse(
        'https://api.quran.com/api/v4/verses/by_key/$surahNumber:$ayahNumber?words=true&word_fields=text_uthmani,translation&language=en',
      );
      final body = await _fetchStreamedStringWithLimit(
        url,
        maxBytes: AppPolicy.maxWordMeaningResponseBytes,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 talib_ilm/1.0',
        },
      );

      final data = json.decode(body);
      final rawWords = data['verse']?['words'] as List? ?? [];
      final List<WordMeaning> result = [];
      final List<Map<String, String?>> forStorage = [];

      for (final w in rawWords) {
        if (w['char_type_name'] == 'end') continue;
        final arabic =
            w['text_uthmani'] as String? ?? w['text'] as String? ?? '';
        final translation = _cleanHtml(w['translation']?['text'] as String? ?? '');
        final translit = w['transliteration']?['text'] as String?;

        if (arabic.isNotEmpty && translation.isNotEmpty) {
          result.add(WordMeaning(
            word: arabic,
            meaning: translation,
            transliteration: translit,
          ));
          forStorage.add({'w': arabic, 'm': translation, 't': translit});
        }
      }

      if (result.isNotEmpty) {
        _putWordsMemory(cacheKey, result);
        await prefs.setString(cacheKey, json.encode(forStorage));
        return result;
      }
    } catch (_) {}

    return const [];
  }

  static String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}
