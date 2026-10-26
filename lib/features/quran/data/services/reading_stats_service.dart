import 'dart:convert';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_policy.dart';
import '../../../../core/utils/async_lock.dart';

/// Service managing persistent Quran reading session logs and streak calculations.
/// Bound by strict retention budgets, in-memory caching, and isolated clock injection.
class ReadingStatsService {
  static const String _sessionsKey = 'quran_reading_sessions';
  static final AsyncLock _lock = AsyncLock();

  // In-memory cache of decoded sessions with raw snapshot equality guard
  static List<String>? _cachedRawSessions;
  static List<Map<String, dynamic>>? _cachedDecodedSessions;

  final DateTime Function() _clock;

  ReadingStatsService({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  @visibleForTesting
  static void resetCacheForTesting() {
    _cachedRawSessions = null;
    _cachedDecodedSessions = null;
  }

  Future<List<Map<String, dynamic>>> _getOrLoadSessions(SharedPreferences prefs) async {
    final List<String> rawSessions = prefs.getStringList(_sessionsKey) ?? [];

    if (_cachedRawSessions != null &&
        _cachedDecodedSessions != null &&
        listEquals(_cachedRawSessions, rawSessions)) {
      return _cachedDecodedSessions!;
    }

    final now = _clock();
    final cutoffMs = DateTime(
      now.year,
      now.month,
      now.day - AppPolicy.maxReadingSessionAgeDays,
    ).millisecondsSinceEpoch;

    final valid = <Map<String, dynamic>>[];
    for (final s in rawSessions) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is! Map) continue;
        final ts = decoded['timestamp'];
        if (ts is int && ts >= cutoffMs) {
          valid.add(decoded.map((k, v) => MapEntry(k.toString(), v)));
        }
      } catch (_) {
        // Discard corrupt session entry
      }
    }

    _cachedRawSessions = List<String>.of(rawSessions);
    _cachedDecodedSessions = valid;
    return valid;
  }

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
      final sessions = await _getOrLoadSessions(prefs);

      final now = _clock();
      final cutoffMs = DateTime(
        now.year,
        now.month,
        now.day - AppPolicy.maxReadingSessionAgeDays,
      ).millisecondsSinceEpoch;

      sessions.removeWhere((s) {
        final ts = s['timestamp'];
        return ts is! int || ts < cutoffMs;
      });

      final sessionMap = <String, dynamic>{
        'timestamp': now.millisecondsSinceEpoch,
        'duration': durationSeconds > 0 ? durationSeconds : 0,
        'verses': versesRead > 0 ? versesRead : 0,
        'surah': surahNumber,
      };

      sessions.add(sessionMap);
      if (sessions.length > AppPolicy.maxStoredReadingSessions) {
        sessions.removeRange(
          0,
          sessions.length - AppPolicy.maxStoredReadingSessions,
        );
      }

      final encoded = sessions.map((s) => jsonEncode(s)).toList();
      _cachedRawSessions = List<String>.of(encoded);
      _cachedDecodedSessions = sessions;
      await prefs.setStringList(_sessionsKey, encoded);
    });
  }

  /// Get stats for today (minutes and verses read).
  Future<Map<String, int>> getDailyStats() async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await _getOrLoadSessions(prefs);

    int totalSeconds = 0;
    int totalVerses = 0;

    final now = _clock();
    final startOfDay = DateTime(now.year, now.month, now.day);

    for (final decoded in sessions) {
      final ts = decoded['timestamp'];
      if (ts is! int) continue;
      final date = DateTime.fromMillisecondsSinceEpoch(ts);
      if (date.isAfter(startOfDay)) {
        final dur = decoded['duration'];
        final ver = decoded['verses'];
        if (dur is int && dur > 0) totalSeconds += dur;
        if (ver is int && ver > 0) totalVerses += ver;
      }
    }

    // Convert total seconds to minutes
    int totalMinutes = (totalSeconds / 60).ceil();
    if (totalSeconds > 0 && totalMinutes == 0) {
      totalMinutes = 1; // Minimum 1 min calculation if any reading
    }

    return {'minutes': totalMinutes, 'verses': totalVerses};
  }

  /// Calculate consecutive day reading streak with civil calendar rollover.
  int _calculateStreak(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) return 0;

    final SplayTreeSet<String> activeDays = SplayTreeSet<String>();

    for (final decoded in sessions) {
      final ts = decoded['timestamp'];
      if (ts is! int) continue;
      final date = DateTime.fromMillisecondsSinceEpoch(ts);
      final dayKey = _formatDate(date);
      activeDays.add(dayKey);
    }

    if (activeDays.isEmpty) return 0;

    final sortedDays = activeDays.toList().reversed.toList();
    final now = _clock();
    final today = _formatDate(now);
    final yesterday = _formatDate(DateTime(now.year, now.month, now.day - 1));

    // If last active day was before yesterday, streak is broken
    if (sortedDays.first != today && sortedDays.first != yesterday) {
      return 0;
    }

    // Check if today is active
    bool streakAlive = activeDays.contains(today);
    DateTime checkDate = now;

    if (!streakAlive) {
      if (activeDays.contains(yesterday)) {
        streakAlive = true;
        checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
      } else {
        return 0;
      }
    }

    int streak = 0;
    while (activeDays.contains(_formatDate(checkDate))) {
      streak++;
      checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
    }

    return streak;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await _getOrLoadSessions(prefs);
    return _calculateStreak(sessions);
  }

  Future<Map<String, int>> getReadingGoal() async {
    return {'minutes': 20, 'verses': 50};
  }
}

