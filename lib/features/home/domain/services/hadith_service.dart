import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../../../app/constants/app_assets.dart';
import '../models/hadith.dart';

class HadithService {
  Future<List<Hadith>>? _cache;
  final Random _random = Random();

  Future<Hadith> getHadithOfTheDay() async {
    try {
      final items = await _loadHadith();
      if (items.isEmpty) {
        return const Hadith(text: '', source: '');
      }

      final seed = _dailySeed(DateTime.now());
      final index = seed % items.length;
      return items[index];
    } catch (_) {
      return const Hadith(text: '', source: '');
    }
  }

  Future<Hadith> getRandomHadith({Hadith? exclude}) async {
    try {
      final items = await _loadHadith();
      if (items.isEmpty) {
        return const Hadith(text: '', source: '');
      }

      final options = exclude == null
          ? items
          : items
              .where(
                (item) =>
                    item.text != exclude.text ||
                    item.source != exclude.source,
              )
              .toList();

      final list = options.isEmpty ? items : options;
      final choice = list[_random.nextInt(list.length)];
      return choice;
    } catch (_) {
      return const Hadith(text: '', source: '');
    }
  }

  Future<List<Hadith>> _loadHadith() {
    return _cache ??= _loadFromAssets();
  }

  Future<List<Hadith>> _loadFromAssets() async {
    final raw = await rootBundle.loadString(AppAssets.hadithData);
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    final result = <Hadith>[];
    for (final entry in decoded) {
      if (entry is! Map) continue;
      final text = entry['text']?.toString().trim() ?? '';
      final source = entry['source']?.toString().trim() ?? '';
      if (text.isEmpty) continue;
      result.add(Hadith(text: text, source: source));
    }
    return result;
  }

  int _dailySeed(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(startOfYear).inDays;
    return date.year * 1000 + dayOfYear;
  }
}
