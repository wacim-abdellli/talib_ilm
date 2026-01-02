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
}
