import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:collection';

class ReadingStatsService {
  static const String _sessionsKey = 'quran_reading_sessions';

  // Save a reading session
  Future<void> recordSession({
    required int durationSeconds,
    required int versesRead,
    required int surahNumber,
  }) async {
    if (durationSeconds < 10 && versesRead == 0) return; // Ignore tiny sessions

    final prefs = await SharedPreferences.getInstance();
    final List<String> sessions = prefs.getStringList(_sessionsKey) ?? [];

    final sessionMap = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'duration': durationSeconds,
      'verses': versesRead,
      'surah': surahNumber,
    };

    sessions.add(jsonEncode(sessionMap));
    await prefs.setStringList(_sessionsKey, sessions);
  }

  // Get stats for today
  Future<Map<String, int>> getDailyStats() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> sessions = prefs.getStringList(_sessionsKey) ?? [];

    int totalMinutes = 0;
    int totalVerses = 0;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    for (var s in sessions) {
      final map = jsonDecode(s);
      final date = DateTime.fromMillisecondsSinceEpoch(map['timestamp']);
      if (date.isAfter(startOfDay)) {
        totalMinutes += (map['duration'] as int) ~/ 60;
        totalVerses += (map['verses'] as int);
      }
    }

    return {'minutes': totalMinutes, 'verses': totalVerses};
  }

  // Calculate Actual Streak
  Future<int> _calculateStreak(List<String> sessions) async {
    if (sessions.isEmpty) return 0;

    // Use a Set to store unique dates (yyyy-mm-dd) that have activity
    final SplayTreeSet<String> activeDays = SplayTreeSet<String>();

    for (var s in sessions) {
      final map = jsonDecode(s);
      final date = DateTime.fromMillisecondsSinceEpoch(map['timestamp']);
      // Format as YYYY-MM-DD to ignore time
      final dayKey = _formatDate(date);
      activeDays.add(dayKey);
    }

    if (activeDays.isEmpty) return 0;

    // Convert to sorted list (descending - newest first)
    final sortedDays = activeDays.toList().reversed.toList();
    final today = _formatDate(DateTime.now());
    final yesterday = _formatDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    // Check if the streak is alive (active today or yesterday)
    // If last active day was before yesterday, streak is broken -> 0
    if (sortedDays.first != today && sortedDays.first != yesterday) {
      return 0;
    }

    int streak = 0;
    DateTime currentCheck = DateTime.now();

    // If today is not active, start checking from yesterday for the streak
    if (sortedDays.first != today) {
      currentCheck = currentCheck.subtract(const Duration(days: 1));
    }

    // Iterate backwards day by day to count streak
    // Note: This matches strict consecutive days.
    // Optimization: We iterate through our sorted active days.

    // Robust Logic:
    streak = 0;
    // Check if today is active
    bool streakAlive = activeDays.contains(today);
    DateTime checkDate = DateTime.now();

    // If today is NOT active, but yesterday IS, streak is still alive (just hasn't incremented for today yet)
    if (!streakAlive) {
      if (activeDays.contains(yesterday)) {
        streakAlive = true;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        return 0; // Streak broken
      }
    }

    // Count backwards while days are consecutive
    while (activeDays.contains(_formatDate(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> sessions = prefs.getStringList(_sessionsKey) ?? [];
    return _calculateStreak(sessions);
  }

  // Get Reading Goal
  Future<Map<String, int>> getReadingGoal() async {
    // Default: 20 mins or 50 verses
    return {'minutes': 20, 'verses': 50};
  }
}
