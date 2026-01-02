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

  String _key(AdhkarCategory category, String field) {
    return '$_prefix${category.id}_$field';
  }
}
