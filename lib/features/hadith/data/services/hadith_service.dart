import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/hadith_models.dart';

class HadithService {
  static final HadithService _instance = HadithService._internal();
  factory HadithService() => _instance;
  HadithService._internal();

  List<GradedHadith>? _cachedHadiths;

  /// Loads all graded hadiths from local bundled asset with zero latency
  Future<List<GradedHadith>> getAllHadiths() async {
    if (_cachedHadiths != null && _cachedHadiths!.isNotEmpty) {
      return _cachedHadiths!;
    }

    try {
      final jsonStr = await rootBundle.loadString('assets/data/hadith_collection.json');
      final list = json.decode(jsonStr) as List;
      _cachedHadiths = list
          .map((item) => GradedHadith.fromJson(item as Map<String, dynamic>))
          .toList();
      return _cachedHadiths!;
    } catch (_) {
      return const [];
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

  /// Returns a random hadith from the collection
  Future<GradedHadith?> getRandomHadith() async {
    final all = await getAllHadiths();
    if (all.isEmpty) return null;
    final rng = Random();
    return all[rng.nextInt(all.length)];
  }

  /// Returns list of unique categories
  Future<List<String>> getCategories() async {
    final all = await getAllHadiths();
    final set = <String>{};
    for (final h in all) {
      if (h.category.isNotEmpty) set.add(h.category);
    }
    return set.toList();
  }

  /// Filters hadiths by category
  Future<List<GradedHadith>> getByCategory(String category) async {
    final all = await getAllHadiths();
    if (category.isEmpty || category == 'الكل') return all;
    return all.where((h) => h.category == category).toList();
  }

  /// Search hadiths by title, matn, or narrator with diacritics normalization
  Future<List<GradedHadith>> searchHadiths(String query) async {
    final all = await getAllHadiths();
    final cleanQuery = _normalizeArabic(query.trim());
    if (cleanQuery.isEmpty) return all;

    return all.where((h) {
      final cleanTitle = _normalizeArabic(h.title);
      final cleanMatn = _normalizeArabic(h.matn);
      final cleanNarrator = _normalizeArabic(h.narrator);
      final cleanBenefits = _normalizeArabic(h.benefits);

      return cleanTitle.contains(cleanQuery) ||
          cleanMatn.contains(cleanQuery) ||
          cleanNarrator.contains(cleanQuery) ||
          cleanBenefits.contains(cleanQuery);
    }).toList();
  }

  static String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') // remove tashkeel
        .replaceAll(RegExp(r'[إأآا]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .toLowerCase();
  }
}
