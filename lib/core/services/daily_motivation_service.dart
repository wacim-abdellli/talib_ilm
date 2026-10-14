import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../app/constants/app_assets.dart';
import '../../app/constants/app_strings.dart';
import '../../features/home/data/models/daily_motivation.dart';

List<DailyMotivation> _parseMotivations(String raw) {
  final decoded = jsonDecode(raw);
  final list = decoded is List ? decoded : const [];

  return list.map((item) {
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
}

class DailyMotivationService {
  static List<DailyMotivation>? _cache;
  static Future<List<DailyMotivation>>? _loadingFuture;

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
    if (_loadingFuture != null) return _loadingFuture!;

    _loadingFuture = _loadInternal();
    return _loadingFuture!;
  }

  Future<List<DailyMotivation>> _loadInternal() async {
    try {
      final raw = await rootBundle.loadString(AppAssets.dailyMotivation);
      _cache = await compute(_parseMotivations, raw);
      return _cache!;
    } catch (_) {
      return const [];
    } finally {
      _loadingFuture = null;
    }
  }
}
