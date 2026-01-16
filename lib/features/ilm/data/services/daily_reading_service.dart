import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking daily reading goals and streaks
class DailyReadingService {
  static const String _dailyProgressKey = 'daily_reading_progress';
  static const String _dailyGoalKey = 'daily_reading_goal';
  static const String _streakKey = 'reading_streak';
  static const String _lastReadDateKey = 'last_read_date';

  final SharedPreferences _prefs;

  DailyReadingService(this._prefs);

  /// Default daily goal (pages per day)
  static const int defaultDailyGoal = 5;

  /// Get user's daily page goal
  int getDailyGoal() {
    return _prefs.getInt(_dailyGoalKey) ?? defaultDailyGoal;
  }

  /// Set user's daily page goal
  Future<void> setDailyGoal(int pages) async {
    await _prefs.setInt(_dailyGoalKey, pages);
  }

  /// Get pages read today
  int getPagesReadToday() {
    final data = _loadDailyProgress();
    final today = _todayKey();
    return data[today] ?? 0;
  }

  /// Add pages read today
  Future<void> addPagesRead(int pages) async {
    final data = _loadDailyProgress();
    final today = _todayKey();
    data[today] = (data[today] ?? 0) + pages;
    await _saveDailyProgress(data);
    await _updateStreak();
  }

  /// Set pages read today (for syncing from book progress)
  Future<void> setPagesReadToday(int pages) async {
    final data = _loadDailyProgress();
    final today = _todayKey();
    data[today] = pages;
    await _saveDailyProgress(data);
    await _updateStreak();
  }

  /// Get current reading streak (consecutive days)
  int getCurrentStreak() {
    return _prefs.getInt(_streakKey) ?? 0;
  }

  /// Check if daily goal is completed
  bool isDailyGoalCompleted() {
    return getPagesReadToday() >= getDailyGoal();
  }

  /// Get the last date the user read any content
  DateTime? getLastReadDate() {
    final str = _prefs.getString(_lastReadDateKey);
    return str != null ? _keyToDate(str) : null;
  }

  /// Get progress towards daily goal (0.0 to 1.0)
  double getDailyProgress() {
    final goal = getDailyGoal();
    if (goal == 0) return 1.0;
    return (getPagesReadToday() / goal).clamp(0.0, 1.0);
  }

  /// Get remaining pages to reach daily goal
  int getRemainingPages() {
    final remaining = getDailyGoal() - getPagesReadToday();
    return remaining > 0 ? remaining : 0;
  }

  /// Get pages read in the last 7 days
  Map<String, int> getWeeklyProgress() {
    final data = _loadDailyProgress();
    final result = <String, int>{};
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final key = _dateToKey(date);
      result[key] = data[key] ?? 0;
    }

    return result;
  }

  /// Update streak based on reading activity
  Future<void> _updateStreak() async {
    final lastReadStr = _prefs.getString(_lastReadDateKey);
    final today = DateTime.now();
    final todayStr = _todayKey();

    if (lastReadStr == null) {
      // First time reading
      await _prefs.setInt(_streakKey, 1);
      await _prefs.setString(_lastReadDateKey, todayStr);
      return;
    }

    if (lastReadStr == todayStr) {
      // Already read today, no streak change
      return;
    }

    final lastRead = _keyToDate(lastReadStr);
    final yesterday = today.subtract(const Duration(days: 1));

    if (_isSameDay(lastRead, yesterday)) {
      // Read yesterday, increment streak
      final currentStreak = _prefs.getInt(_streakKey) ?? 0;
      await _prefs.setInt(_streakKey, currentStreak + 1);
    } else {
      // Missed a day, reset streak
      await _prefs.setInt(_streakKey, 1);
    }

    await _prefs.setString(_lastReadDateKey, todayStr);
  }

  /// Reset daily progress (called when syncing from book progress)
  Future<void> syncFromBookProgress(int totalPagesReadToday) async {
    await setPagesReadToday(totalPagesReadToday);
  }

  // ═══════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════

  Map<String, int> _loadDailyProgress() {
    final jsonString = _prefs.getString(_dailyProgressKey);
    if (jsonString == null) return {};

    try {
      final Map<String, dynamic> data = json.decode(jsonString);
      return data.map((key, value) => MapEntry(key, value as int));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveDailyProgress(Map<String, int> data) async {
    // Keep only last 30 days to prevent storage bloat
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    data.removeWhere((key, _) {
      final date = _keyToDate(key);
      return date.isBefore(cutoff);
    });

    await _prefs.setString(_dailyProgressKey, json.encode(data));
  }

  String _todayKey() => _dateToKey(DateTime.now());

  String _dateToKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  DateTime _keyToDate(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.tryParse(parts[0]) ?? 2024,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[2]) ?? 1,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
