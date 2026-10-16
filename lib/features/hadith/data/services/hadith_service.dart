import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/hadith_models.dart';

final RegExp _tashkeelRegex = RegExp(r'[\u064B-\u065F\u0670]');
final RegExp _alefRegex = RegExp(r'[إأآا]');

String _normalizeArabicText(String text) {
  if (text.isEmpty) return '';
  return text
      .replaceAll(_tashkeelRegex, '') // remove tashkeel
      .replaceAll(_alefRegex, 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .toLowerCase();
}

List<GradedHadith> _parseHadithsJson(String jsonStr) {
  final list = json.decode(jsonStr) as List;
  return list
      .whereType<Map<String, dynamic>>()
      .map((m) {
        final hadith = GradedHadith.fromJson(m);
        final searchIdx = _normalizeArabicText(
          '${hadith.title} ${hadith.matn} ${hadith.narrator} ${hadith.benefits}',
        );
        return hadith.copyWith(searchIndex: searchIdx);
      })
      .toList();
}

class HadithService {
  static final HadithService _instance = HadithService._internal();
  factory HadithService() => _instance;
  HadithService._internal();

  List<GradedHadith>? _cachedHadiths;
  Future<List<GradedHadith>>? _loadingFuture;

  /// Loads all graded hadiths via background isolate with zero main-thread hitching
  Future<List<GradedHadith>> getAllHadiths() async {
    if (_cachedHadiths != null && _cachedHadiths!.isNotEmpty) {
      return _cachedHadiths!;
    }
    if (_loadingFuture != null) {
      return _loadingFuture!;
    }

    _loadingFuture = _loadInternal();
    return _loadingFuture!;
  }

  Future<List<GradedHadith>> _loadInternal() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/hadith_collection.json');
      _cachedHadiths = await compute(_parseHadithsJson, jsonStr);
      return _cachedHadiths!;
    } catch (_) {
      return const [];
    } finally {
      _loadingFuture = null;
    }
  }

  /// Returns a daily hadith deterministically based on day-of-year
  Future<GradedHadith?> getDailyHadith({int dayOffset = 0}) async {
    final all = await getAllHadiths();
    if (all.isEmpty) return null;

    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = (dayOfYear + dayOffset).abs() % all.length;
    return all[index];
  }

  /// Returns a random hadith from the collection, optionally avoiding [excludeId]
  Future<GradedHadith?> getRandomHadith({String? excludeId}) async {
    final all = await getAllHadiths();
    if (all.isEmpty) return null;
    if (all.length == 1) return all.first;
    final rng = Random();
    GradedHadith candidate;
    int attempts = 0;
    do {
      candidate = all[rng.nextInt(all.length)];
      attempts++;
    } while (candidate.id == excludeId && attempts < 10);
    return candidate;
  }

  /// Canonical collections and core sources
  static const List<String> canonicalCollections = [
    'الكل',
    'متفق عليه',
    'صحيح البخاري',
    'صحيح مسلم',
    'رياض الصالحين',
    'الأربعون النووية',
    'الأحاديث القدسية',
  ];

  /// Standard pedagogical categories ordering
  static const List<String> standardCategoryOrder = [
    'الإخلاص والنية',
    'أصول العقيدة',
    'القضاء والقدر',
    'الاتباع والسنة',
    'التوبة والاستغفار',
    'الصبر والتوكل',
    'الأخلاق والآداب',
    'الصلوات والعبادات',
    'الذكر والدعاء',
    'الزهد والرقائق',
    'العلم وفضله',
    'بر الوالدين وحقوق المسلم',
    'التحذير من المنهيات',
    'الجهاد والأمر بالمعروف',
  ];

  /// Filters a list of hadiths by canonical collection or primary source
  List<GradedHadith> filterByCollection(
    List<GradedHadith> hadiths,
    String collection,
  ) {
    if (collection.isEmpty || collection == 'الكل') return hadiths;
    if (collection == 'متفق عليه') {
      return hadiths.where((h) => h.source.contains('متفق عليه')).toList();
    }
    if (collection == 'صحيح البخاري') {
      return hadiths
          .where(
            (h) =>
                h.source.contains('البخاري') || h.collection == 'صحيح البخاري',
          )
          .toList();
    }
    if (collection == 'صحيح مسلم') {
      return hadiths
          .where(
            (h) => h.source.contains('مسلم') || h.collection == 'صحيح مسلم',
          )
          .toList();
    }
    return hadiths.where((h) => h.collection == collection).toList();
  }

  /// Returns list of unique collections including canonical Bukhari/Muslim filters
  Future<List<String>> getCollections() async {
    return canonicalCollections;
  }

  /// Returns list of unique categories (optionally scoped to a collection)
  Future<List<String>> getCategories([String? collection]) async {
    final all = await getAllHadiths();
    final scoped = (collection == null || collection == 'الكل')
        ? all
        : filterByCollection(all, collection);

    final set = <String>{};
    for (final h in scoped) {
      if (h.category.isNotEmpty) set.add(h.category);
    }

    final ordered = <String>[];
    for (final cat in standardCategoryOrder) {
      if (set.contains(cat)) {
        ordered.add(cat);
        set.remove(cat);
      }
    }
    ordered.addAll(set);
    return ordered;
  }

  /// Filters hadiths by category
  Future<List<GradedHadith>> getByCategory(String category) async {
    final all = await getAllHadiths();
    if (category.isEmpty || category == 'الكل') return all;
    return all.where((h) => h.category == category).toList();
  }

  /// Normalizes Arabic text using shared precompiled regular expressions
  static String normalizeArabic(String text) => _normalizeArabicText(text);

  /// Search hadiths by title, matn, or narrator with diacritics normalization
  Future<List<GradedHadith>> searchHadiths(String query) async {
    final all = await getAllHadiths();
    final cleanQuery = _normalizeArabicText(query.trim());
    if (cleanQuery.isEmpty) return all;

    return all.where((h) {
      if (h.searchIndex != null) {
        return h.searchIndex!.contains(cleanQuery);
      }
      final cleanTitle = _normalizeArabicText(h.title);
      final cleanMatn = _normalizeArabicText(h.matn);
      final cleanNarrator = _normalizeArabicText(h.narrator);
      final cleanBenefits = _normalizeArabicText(h.benefits);

      return cleanTitle.contains(cleanQuery) ||
          cleanMatn.contains(cleanQuery) ||
          cleanNarrator.contains(cleanQuery) ||
          cleanBenefits.contains(cleanQuery);
    }).toList();
  }
}
