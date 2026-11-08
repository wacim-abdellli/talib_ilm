import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mutashabih_card.dart';

const Duration _kApiTimeout = Duration(seconds: 5); // ui-lint: allow network timeout

/// Service for fetching authentic Quranic Similar Verses (المتشابهات اللفظية),
/// scholarly memory mnemonics (الضوابط الحفظية), and rhetorical reasoning (التوجيه البلاغي).
class QuranMutashabihatService {
  QuranMutashabihatService._();

  static http.Client? _customHttpClient;
  static final http.Client _defaultHttpClient = http.Client();

  @visibleForTesting
  static http.Client get httpClient => _customHttpClient ?? _defaultHttpClient;

  @visibleForTesting
  static void setHttpClient(http.Client? client) => _customHttpClient = client;

  @visibleForTesting
  static void resetHttpClient() => _customHttpClient = null;

  static final Map<String, List<MutashabihCard>> _memCache = {};

  /// Fetches similar verses cards for a given [surah] and [ayah].
  ///
  /// Checks in-memory cache first, then persistent storage, then the live API.
  /// Falls back to local structural phrase matching if offline and un-cached.
  static Future<List<MutashabihCard>> getSimilarVerses({
    required int surah,
    required int ayah,
  }) async {
    final cacheKey = 'mutashabih_${surah}_$ayah';

    // 1. Check in-memory RAM cache
    if (_memCache.containsKey(cacheKey)) {
      return _memCache[cacheKey]!;
    }

    // 2. Check SharedPreferences persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cache_$cacheKey');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = json.decode(cachedJson) as Map<String, dynamic>;
        final cards = _parseCards(decoded);
        _memCache[cacheKey] = cards;
        return cards;
      }
    } catch (_) {
      // Ignore storage errors and fall back to network/computation
    }

    // 3. Fetch from Wahy Mutashabih API
    try {
      final uri = Uri.parse('https://web.wahy.net/api/mutashabih/$surah/$ayah');
      final response = await httpClient
          .get(uri, headers: {
            'User-Agent': 'talib_ilm/1.0.0 (flutter; scholarly-edition)',
            'Accept': 'application/json',
          })
          .timeout(_kApiTimeout);

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        final cards = _parseCards(decoded);

        // Store in memory & persistent cache
        _memCache[cacheKey] = cards;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cache_$cacheKey', json.encode(decoded));
        } catch (_) {}

        return cards;
      }
    } catch (_) {
      // Network failure, timeout, or offline
    }

    // 4. Offline Algorithmic Fallback (Extract identical opening prefixes)
    final fallbackCards = _buildOfflineFallback(surah, ayah);
    _memCache[cacheKey] = fallbackCards;
    return fallbackCards;
  }

  static List<MutashabihCard> _parseCards(Map<String, dynamic> data) {
    final rawCards = data['cards'] as List<dynamic>?;
    if (rawCards == null) return const [];

    return rawCards
        .map((c) => MutashabihCard.fromJson(c as Map<String, dynamic>))
        .where((c) => c.places.isNotEmpty)
        .toList();
  }

  /// Generates clean algorithmic similarities when offline.
  /// Identifies verses sharing identical opening phrases or structural roots.
  static List<MutashabihPlacesOfflineMatcher> _buildOfflineFallback(
    int targetSurah,
    int targetAyah,
  ) {
    try {
      final currentVerse = quran.getVerse(targetSurah, targetAyah).trim();
      final words = currentVerse.split(RegExp(r'\s+'));
      if (words.length < 3) return const [];

      // Take first 3 words as opening similarity pattern
      final prefix = words.take(3).join(' ');
      final matchingPlaces = <MutashabihPlace>[
        MutashabihPlace(
          surah: targetSurah,
          ayah: targetAyah,
          fromWord: 1,
          toWord: 3,
          text: currentVerse,
        ),
      ];

      // Scan nearby / key surahs for the same prefix
      for (var s = 1; s <= 114; s++) {
        final ayahCount = quran.getVerseCount(s);
        for (var a = 1; a <= ayahCount; a++) {
          if (s == targetSurah && a == targetAyah) continue;
          final otherVerse = quran.getVerse(s, a).trim();
          if (otherVerse.startsWith(prefix)) {
            matchingPlaces.add(
              MutashabihPlace(
                surah: s,
                ayah: a,
                fromWord: 1,
                toWord: 3,
                text: otherVerse,
              ),
            );
            if (matchingPlaces.length >= 6) break;
          }
        }
        if (matchingPlaces.length >= 6) break;
      }

      if (matchingPlaces.length > 1) {
        return [
          MutashabihCard(
            id: targetSurah * 1000 + targetAyah,
            places: matchingPlaces,
            rule: 'تشابه في مطالع الآيات بصيغة ($prefix)',
            rhetoric: 'افتتاح السور والآيات بهذه الصيغة للتأكيد ولفت انتباه السامع',
            source: 'الضبط بالحصر والمطالعة الميدانية',
          ),
        ];
      }
    } catch (_) {}

    return const [];
  }
}

typedef MutashabihPlacesOfflineMatcher = MutashabihCard;

