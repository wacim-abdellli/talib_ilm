import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../app/constants/app_assets.dart';
import '../../app/constants/app_strings.dart';
import '../../features/home/data/models/daily_motivation.dart';

class DailyMotivationService {
  static List<DailyMotivation>? _cache;

  Future<DailyMotivation> getDailyMotivation() async {
    final items = await _loadAll();
    if (items.isEmpty) {
      return const DailyMotivation(
        text: AppStrings.dailyMotivationFallback,
        source: '',
      );
    }
    final random = Random();
    return items[random.nextInt(items.length)];
  }

  Future<List<DailyMotivation>> _loadAll() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString(AppAssets.dailyMotivation);
    final decoded = jsonDecode(raw);
    final list = decoded is List ? decoded : const [];

    _cache = list.map((item) {
      if (item is String) {
        return DailyMotivation(text: item, source: '');
      }
      if (item is Map) {
        return DailyMotivation.fromJson(
          Map<String, dynamic>.from(item),
        );
      }
      return null;
    }).whereType<DailyMotivation>().toList();

    return _cache!;
  }
}
