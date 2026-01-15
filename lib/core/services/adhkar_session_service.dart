import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/adhkar/data/adhkar_models.dart';

class AdhkarSessionState {
  final int index;
  final int count;

  const AdhkarSessionState({
    required this.index,
    required this.count,
  });
}

class AdhkarSessionService {
  static const _prefix = 'adhkar_session_';
  static const _completionPrefix = 'adhkar_completion_';
  static const _countsPrefix = 'adhkar_counts_';

  Future<AdhkarSessionState> loadState(AdhkarCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key(category, 'index')) ?? 0;
    final count = prefs.getInt(_key(category, 'count')) ?? 0;
    return AdhkarSessionState(index: index, count: count);
  }

  Future<void> saveState(
    AdhkarCategory category,
    AdhkarSessionState state,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(category, 'index'), state.index);
    await prefs.setInt(_key(category, 'count'), state.count);
  }

  Future<void> clearState(AdhkarCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(category, 'index'));
    await prefs.remove(_key(category, 'count'));
  }

  Future<Map<String, int>> loadCounts(AdhkarCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_countsKey(category));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <String, int>{};
      for (final entry in decoded.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is int) {
          result[key] = value;
        } else if (value is num) {
          result[key] = value.toInt();
        } else {
          final parsed = int.tryParse(value.toString());
          if (parsed != null) result[key] = parsed;
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveCounts(
    AdhkarCategory category,
    Map<String, int> counts,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final filtered = <String, int>{};
    counts.forEach((key, value) {
      if (value > 0) filtered[key] = value;
    });
    await prefs.setString(_countsKey(category), jsonEncode(filtered));
  }

  Future<DateTime?> loadCompletion(AdhkarCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_completionKey(category));
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveCompletion(
    AdhkarCategory category,
    DateTime completion,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _completionKey(category),
      completion.toIso8601String(),
    );
  }

  Future<void> clearCompletion(AdhkarCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completionKey(category));
  }

  String _key(AdhkarCategory category, String field) {
    return '$_prefix${category.id}_$field';
  }

  String _completionKey(AdhkarCategory category) {
    return '$_completionPrefix${category.id}';
  }

  String _countsKey(AdhkarCategory category) {
    return '$_countsPrefix${category.id}';
  }
}
