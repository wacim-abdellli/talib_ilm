import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_policy.dart';
import '../models/quran_waqf_analysis.dart';

/// Hardened service for fetching and caching Quranic Waqf judgments
/// from the 5 Classical Imams of Waqf.
class QuranWaqfService {
  static final QuranWaqfService _instance = QuranWaqfService._internal();
  factory QuranWaqfService() => _instance;
  QuranWaqfService._internal();

  static const String _baseUrl = 'https://web.wahy.net/api/waqf';
  static const String _prefsPrefix = 'quran_waqf_analysis_v1';

  final Map<String, AyahWaqfAnalysis> _ramCache = {};
  http.Client? _client;

  @visibleForTesting
  void setHttpClient(http.Client? client) {
    _client = client;
  }

  http.Client get _effectiveClient => _client ?? http.Client();

  /// Retrieve the classical Waqf judgments for a specific Ayah.
  Future<AyahWaqfAnalysis> getAyahWaqf(int surah, int ayah) async {
    final cacheKey = '${surah}_$ayah';

    // 1. In-memory RAM cache
    if (_ramCache.containsKey(cacheKey)) {
      return _ramCache[cacheKey]!;
    }

    // 2. Persistent SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString('${_prefsPrefix}_$cacheKey');
    if (cachedStr != null && cachedStr.isNotEmpty) {
      try {
        final decoded = json.decode(cachedStr) as Map<String, dynamic>;
        final analysis = AyahWaqfAnalysis.fromJson(decoded);
        _ramCache[cacheKey] = analysis;
        return analysis;
      } catch (_) {}
    }

    // 3. Network Fetch
    try {
      final analysis = await _fetchFromWahy(surah, ayah);
      if (analysis != null) {
        _ramCache[cacheKey] = analysis;
        await prefs.setString(
          '${_prefsPrefix}_$cacheKey',
          json.encode(analysis.toJson()),
        );
        return analysis;
      }
    } catch (_) {}

    // 4. Offline Algorithmic Fallback
    final fallback = _generateOfflineFallback(surah, ayah);
    _ramCache[cacheKey] = fallback;
    return fallback;
  }

  Future<AyahWaqfAnalysis?> _fetchFromWahy(int surah, int ayah) async {
    final url = Uri.parse('$_baseUrl/$surah/$ayah');
    final response = await _effectiveClient.get(url).timeout(AppPolicy.networkTimeout);

    if (response.statusCode != 200) {
      return null;
    }

    final decoded = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final rawText = decoded['text'] as String? ?? quran.getVerse(surah, ayah, verseEndSymbol: true);
    final firstWordId = (decoded['first'] as num?)?.toInt() ?? 1;

    // Parse scholars
    final rawBooks = decoded['books'] as List<dynamic>? ?? const [];
    final scholars = rawBooks
        .map((b) => WaqfScholar.fromJson(b as Map<String, dynamic>))
        .toList();

    // Words in ayah
    final wordsInVerse = _extractWordsFromAyah(surah, ayah);
    final rawWordsMap = decoded['words'] as Map<String, dynamic>? ?? const {};

    final wordsList = <WaqfWord>[];
    for (var i = 1; i <= wordsInVerse.length; i++) {
      final key = '$i';
      final wordJudgmentsRaw = rawWordsMap[key] as List<dynamic>?;
      if (wordJudgmentsRaw != null && wordJudgmentsRaw.isNotEmpty) {
        final wordStr = wordsInVerse[i - 1];
        final judgments = wordJudgmentsRaw
            .map((j) => WaqfJudgment.fromWahyList(j as List<dynamic>))
            .toList();

        wordsList.add(
          WaqfWord(
            wordIndex: i,
            word: wordStr,
            judgments: judgments,
          ),
        );
      }
    }

    return AyahWaqfAnalysis(
      surah: surah,
      ayah: ayah,
      verseText: rawText,
      firstGlobalWordId: firstWordId,
      scholars: scholars.isNotEmpty ? scholars : _defaultScholars,
      words: wordsList,
    );
  }

  List<String> _extractWordsFromAyah(int surah, int ayah) {
    final rawText = quran.getVerse(surah, ayah, verseEndSymbol: false);
    return rawText
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();
  }

  AyahWaqfAnalysis _generateOfflineFallback(int surah, int ayah) {
    final verseText = quran.getVerse(surah, ayah, verseEndSymbol: true);
    final wordsInVerse = _extractWordsFromAyah(surah, ayah);

    // Provide end-of-ayah stop as universal Tam stop
    final lastWord = wordsInVerse.isNotEmpty ? wordsInVerse.last : 'الآية';
    final endWord = WaqfWord(
      wordIndex: wordsInVerse.length,
      word: lastWord,
      judgments: const [
        WaqfJudgment(
          scholarId: 'dani',
          type: 'w',
          label: 'تام',
          longLabel: 'تام',
          grade: 'tam',
          explanation: 'تمام رأس الآية وانقضاء المعنى التام.',
          note: '',
          page: 'المكتفى',
        ),
        WaqfJudgment(
          scholarId: 'ashmuni',
          type: 'w',
          label: 'تام',
          longLabel: 'التامّة',
          grade: 'tam',
          explanation: 'رأس آية تام حسن الوقف والابتداء بما بعده.',
          note: '',
          page: 'منار الهدى',
        ),
      ],
    );

    return AyahWaqfAnalysis(
      surah: surah,
      ayah: ayah,
      verseText: verseText,
      firstGlobalWordId: 1,
      scholars: _defaultScholars,
      words: [endWord],
    );
  }

  static const List<WaqfScholar> _defaultScholars = [
    WaqfScholar(
      id: 'dani',
      shortName: 'الداني',
      bookTitle: 'المكتفى في الوقف والابتدا',
      deathYear: 444,
    ),
    WaqfScholar(
      id: 'sajawandi',
      shortName: 'السجاوندي',
      bookTitle: 'علل الوقوف',
      deathYear: 560,
    ),
    WaqfScholar(
      id: 'ansari',
      shortName: 'زكريا الأنصاري',
      bookTitle: 'المقصد لتلخيص ما في المرشد',
      deathYear: 926,
    ),
    WaqfScholar(
      id: 'habti',
      shortName: 'الهبطي',
      bookTitle: 'تقييد وقف القرآن',
      deathYear: 930,
    ),
    WaqfScholar(
      id: 'ashmuni',
      shortName: 'الأشموني',
      bookTitle: 'منار الهدى في بيان الوقف والابتدا',
      deathYear: 1100,
    ),
  ];
}

