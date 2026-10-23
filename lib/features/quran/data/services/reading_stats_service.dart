import 'dart:convert';
import 'dart:collection';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_policy.dart';
import '../../../../core/utils/async_lock.dart';

/// Service managing persistent Quran reading session logs and streak calculations.
/// Bound by strict retention budgets and isolated clock injection for determinism.
class ReadingStatsService {
  static const String _sessionsKey = 'quran_reading_sessions';
  static final AsyncLock _lock = AsyncLock();

  final DateTime Function() _clock;

  ReadingStatsService({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  /// Save a reading session while enforcing retention budgets and input bounds.
  Future<void> recordSession({
    required int durationSeconds,
    required int versesRead,
    required int surahNumber,
  }) {
    if (durationSeconds < 5 && versesRead == 0) {
      return Future.value(); // Ignore very short accidental opens
    }

    return _lock.synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      final List<String> rawSessions = prefs.getStringList(_sessionsKey) ?? [];

      final now = _clock();
      final sessionMap = {
        'timestamp': now.millisecondsSinceEpoch,
        'duration': durationSeconds > 0 ? durationSeconds : 0,
        'verses': versesRead > 0 ? versesRead : 0,
        'surah': surahNumber,
      };

      final validSessions = <String>[];
      final cutoffMs = now
          .subtract(const Duration(days: AppPolicy.maxReadingSessionAgeDays))
          .millisecondsSinceEpoch;

      for (final s in rawSessions) {
        try {
          final decoded = jsonDecode(s);
          if (decoded is! Map) continue;
          final ts = decoded['timestamp'];
          if (ts is int && ts >= cutoffMs) {
            validSessions.add(s);
          }
        } catch (_) {
          // Discard corrupt session entry
        }
      }

      validSessions.add(jsonEncode(sessionMap));
      if (validSessions.length > AppPolicy.maxStoredReadingSessions) {
        validSessions.removeRange(
          0,
          validSessions.length - AppPolicy.maxStoredReadingSessions,
        );
      }
      await prefs.setStringList(_sessionsKey, validSessions);
    });
  }

  /// Get stats for today (minutes and verses read).
  Future<Map<String, int>> getDailyStats() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> sessions = prefs.getStringList(_sessionsKey) ?? [];

    int totalSeconds = 0;
    int totalVerses = 0;

    final now = _clock();
    final startOfDay = DateTime(now.year, now.month, now.day);

    for (final s in sessions) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is! Map) continue;
        final ts = decoded['timestamp'];
        if (ts is! int) continue;
        final date = DateTime.fromMillisecondsSinceEpoch(ts);
        if (date.isAfter(startOfDay)) {
          final dur = decoded['duration'];
          final ver = decoded['verses'];
          if (dur is int && dur > 0) totalSeconds += dur;
          if (ver is int && ver > 0) totalVerses += ver;
        }
      } catch (_) {
        // Skip malformed individual session
      }
    }

    // Convert total seconds to minutes
    int totalMinutes = (totalSeconds / 60).ceil();
    if (totalSeconds > 0 && totalMinutes == 0) {
      totalMinutes = 1; // Minimum 1 min calculation if any reading
    }

    return {'minutes': totalMinutes, 'verses': totalVerses};
  }

  /// Calculate consecutive day reading streak.
  Future<int> _calculateStreak(List<String> sessions) async {
    if (sessions.isEmpty) return 0;

    final SplayTreeSet<String> activeDays = SplayTreeSet<String>();

    for (final s in sessions) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is! Map) continue;
        final ts = decoded['timestamp'];
        if (ts is! int) continue;
        final date = DateTime.fromMillisecondsSinceEpoch(ts);
        final dayKey = _formatDate(date);
        activeDays.add(dayKey);
      } catch (_) {
        // Skip malformed individual session
      }
    }

    if (activeDays.isEmpty) return 0;

    final sortedDays = activeDays.toList().reversed.toList();
    final today = _formatDate(_clock());
    final yesterday = _formatDate(
      _clock().subtract(const Duration(days: 1)),
    );

    // If last active day was before yesterday, streak is broken
    if (sortedDays.first != today && sortedDays.first != yesterday) {
      return 0;
    }

    // Check if today is active
    bool streakAlive = activeDays.contains(today);
    DateTime checkDate = _clock();

    if (!streakAlive) {
      if (activeDays.contains(yesterday)) {
        streakAlive = true;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        return 0;
      }
    }

    int streak = 0;
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

  Future<Map<String, int>> getReadingGoal() async {
    return {'minutes': 20, 'verses': 50};
  }
}
