import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_policy.dart';
import '../models/quran_word_analysis.dart';

/// Service providing 4-tier scholarly linguistic breakdowns for Quranic words:
/// (القراءات، الإعراب المفصل، المعنى والبيان، الصرف والاشتقاق والوزن).
class QuranWordAnalysisService {
  static final QuranWordAnalysisService _instance = QuranWordAnalysisService._internal();
  factory QuranWordAnalysisService() => _instance;
  QuranWordAnalysisService._internal();

  static const String _baseUrl = 'https://web.wahy.net/api';
  static const String _prefsPrefix = 'quran_word_analysis_v1';
  static const String _prefsTokensPrefix = 'quran_page_tokens_v1';

  final Map<String, List<QuranWordAnalysis>> _ramCache = {};
  final Map<int, List<List<dynamic>>> _pageTokensCache = {};

  http.Client? _client;

  @visibleForTesting
  void setHttpClient(http.Client? client) {
    _client = client;
  }

  http.Client get _effectiveClient => _client ?? http.Client();

  /// Retrieve the 4-tier linguistic breakdown for all words of a specific Ayah.
  Future<List<QuranWordAnalysis>> getAyahWordAnalyses(int surah, int ayah) async {
    final cacheKey = '${surah}_$ayah';

    // 1. RAM Cache
    if (_ramCache.containsKey(cacheKey)) {
      return _ramCache[cacheKey]!;
    }

    // 2. Persistent SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString('${_prefsPrefix}_$cacheKey');
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final decoded = json.decode(cachedJson) as List<dynamic>;
        final list = decoded
            .map((item) => QuranWordAnalysis.fromJson(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _ramCache[cacheKey] = list;
          return list;
        }
      } catch (_) {
        // Fall through to fetch
      }
    }

    // 3. Network Fetch
    try {
      final analyses = await _fetchFromWahy(surah, ayah, prefs);
      if (analyses.isNotEmpty) {
        _ramCache[cacheKey] = analyses;
        await prefs.setString(
          '${_prefsPrefix}_$cacheKey',
          json.encode(analyses.map((a) => a.toJson()).toList()),
        );
        return analyses;
      }
    } catch (_) {
      // Network failed or offline: fall through to fallback
    }

    // 4. Offline Algorithmic Fallback
    final fallback = _generateOfflineFallback(surah, ayah);
    _ramCache[cacheKey] = fallback;
    return fallback;
  }

  Future<List<QuranWordAnalysis>> _fetchFromWahy(
    int surah,
    int ayah,
    SharedPreferences prefs,
  ) async {
    final page = quran.getPageNumber(surah, ayah);
    final tokens = await _getPageTokens(page, prefs);

    // Filter tokens for this specific (surah, ayah)
    final ayahTokens = tokens.where((t) {
      return t.length > 4 && t[1] == surah && t[2] == ayah;
    }).toList();

    if (ayahTokens.isEmpty) {
      return const [];
    }

    final minWordId = (ayahTokens.first[4] as num).toInt();
    final maxWordId = (ayahTokens.last[4] as num).toInt();

    final url = Uri.parse('$_baseUrl/words/$surah?from=$minWordId&to=$maxWordId');
    final response = await _effectiveClient.get(url).timeout(AppPolicy.networkTimeout);

    if (response.statusCode != 200) {
      return const [];
    }

    final decoded = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final wordsInVerse = _extractWordsFromAyah(surah, ayah);

    final results = <QuranWordAnalysis>[];
    for (var i = 0; i < ayahTokens.length; i++) {
      final token = ayahTokens[i];
      final wordId = (token[4] as num).toInt();
      final wordStr = i < wordsInVerse.length ? wordsInVerse[i] : (token[0]?.toString() ?? '');
      final wordData = decoded['$wordId'] as List<dynamic>? ?? const [];

      results.add(
        QuranWordAnalysis.fromWahyList(
          globalWordId: wordId,
          wordIndexInAyah: i + 1,
          word: wordStr,
          list: wordData,
        ),
      );
    }

    return results;
  }

  Future<List<List<dynamic>>> _getPageTokens(int page, SharedPreferences prefs) async {
    if (_pageTokensCache.containsKey(page)) {
      return _pageTokensCache[page]!;
    }

    final cachedTokensStr = prefs.getString('${_prefsTokensPrefix}_$page');
    if (cachedTokensStr != null && cachedTokensStr.isNotEmpty) {
      try {
        final decoded = json.decode(cachedTokensStr) as List<dynamic>;
        final list = decoded.map((e) => (e as List<dynamic>)).toList();
        _pageTokensCache[page] = list;
        return list;
      } catch (_) {}
    }

    final url = Uri.parse('$_baseUrl/mushaf/hafs/$page');
    final response = await _effectiveClient.get(url).timeout(AppPolicy.networkTimeout);

    if (response.statusCode != 200) {
      return const [];
    }

    final decoded = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final lines = decoded['lines'] as List<dynamic>? ?? const [];
    final extracted = <List<dynamic>>[];

    for (final line in lines) {
      if (line is List && line.isNotEmpty && line[0] == 't') {
        final words = line[1] as List<dynamic>? ?? const [];
        for (final w in words) {
          if (w is List && w.length > 4) {
            extracted.add(w);
          }
        }
      }
    }

    if (extracted.isNotEmpty) {
      _pageTokensCache[page] = extracted;
      prefs.setString('${_prefsTokensPrefix}_$page', json.encode(extracted));
    }

    return extracted;
  }

  List<String> _extractWordsFromAyah(int surah, int ayah) {
    final rawText = quran.getVerse(surah, ayah, verseEndSymbol: false);
    return rawText
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();
  }

  List<QuranWordAnalysis> _generateOfflineFallback(int surah, int ayah) {
    final words = _extractWordsFromAyah(surah, ayah);
    return List.generate(words.length, (index) {
      final word = words[index];
      return QuranWordAnalysis(
        globalWordId: index + 1,
        wordIndexInAyah: index + 1,
        word: word,
        qiraat: 'قراءة حفص عن عاصم من طريق الشاطبية.',
        irab: 'كلمة قرآنية كريمة في الآية $ayah من سورة ${quran.getSurahNameArabic(surah)}.',
        meaning: 'انظر تفسير الآية الكريمة وبيان معانيها في تبويب التفسير.',
        sarf: '﴿$word﴾: مفردة قرآنية كريمة.',
      );
    });
  }
}
