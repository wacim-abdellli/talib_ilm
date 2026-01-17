import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

    await _updateStreak(sessions);
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

  // Calculate Streak
  Future<int> _updateStreak(List<String> sessions) async {
    // Sort sessions by date
    // Logic to calculate consecutive days
    // For now simplified:
    Set<String> days = {};
    for (var s in sessions) {
      final map = jsonDecode(s);
      final date = DateTime.fromMillisecondsSinceEpoch(map['timestamp']);
      days.add('${date.year}-${date.month}-${date.day}');
    }
    // Count backwards from today
    // Placeholder logic
    return days.length;
  }

  Future<int> getStreak() async {
    // Return calculated streak
    // Ideally cached
    return (await getDailyStats())['minutes']! > 0
        ? 5
        : 4; // Mock for demo "Smart" features
  }

  // Get Reading Goal
  Future<Map<String, int>> getReadingGoal() async {
    // Default: 20 mins or 50 verses
    return {'minutes': 20, 'verses': 50};
  }
}
