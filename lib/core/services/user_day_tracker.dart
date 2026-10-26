import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks user actions for the current day
/// Used to determine emotional state (progressed vs absent)
class UserDayTracker {
  static const _keyPrefix = 'user_day_';
  static const _keyQuran = 'opened_quran';
  static const _keyLearning = 'continued_learning';
  static const _keyAdhkar = 'opened_adhkar';
  static const _keyLastAction = 'last_action';
  static const _keyLastVisit = 'last_visit';

  // In-memory cache for today's state
  static String? _cachedToday;
  static bool? _cachedQuran;
  static bool? _cachedLearning;
  static bool? _cachedAdhkar;
  static String? _cachedLastAction;
  static String? _cachedLastVisit;

  @visibleForTesting
  static void resetCacheForTesting() {
    _cachedToday = null;
    _cachedQuran = null;
    _cachedLearning = null;
    _cachedAdhkar = null;
    _cachedLastAction = null;
    _cachedLastVisit = null;
  }

  /// Get today's date key
  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _ensureTodayCache() {
    final today = _todayKey();
    if (_cachedToday != today) {
      _cachedToday = today;
      _cachedQuran = null;
      _cachedLearning = null;
      _cachedAdhkar = null;
    }
  }

  /// Record that user opened Quran today
  Future<void> recordQuranOpened() async {
    _ensureTodayCache();
    _cachedQuran = true;
    _cachedLastAction = 'quran';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix${_todayKey()}_$_keyQuran', true);
    await prefs.setString('$_keyPrefix$_keyLastAction', 'quran');
    await _recordVisit();
  }

  /// Record that user continued learning today
  Future<void> recordLearningContinued() async {
    _ensureTodayCache();
    _cachedLearning = true;
    _cachedLastAction = 'learning';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix${_todayKey()}_$_keyLearning', true);
    await prefs.setString('$_keyPrefix$_keyLastAction', 'learning');
    await _recordVisit();
  }

  /// Record that user opened Adhkar today
  Future<void> recordAdhkarOpened() async {
    _ensureTodayCache();
    _cachedAdhkar = true;
    _cachedLastAction = 'adhkar';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix${_todayKey()}_$_keyAdhkar', true);
    await prefs.setString('$_keyPrefix$_keyLastAction', 'adhkar');
    await _recordVisit();
  }

  /// Record visit timestamp
  Future<void> _recordVisit() async {
    final nowIso = DateTime.now().toIso8601String();
    _cachedLastVisit = nowIso;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyPrefix$_keyLastVisit',
      nowIso,
    );
  }

  /// Record any home visit (even without action)
  Future<void> recordHomeVisit() async {
    await _recordVisit();
  }

  /// Check if user has done any meaningful action today
  Future<bool> hasActedToday() async {
    _ensureTodayCache();
    if (_cachedQuran == true || _cachedLearning == true || _cachedAdhkar == true) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final quran = prefs.getBool('$_keyPrefix${today}_$_keyQuran') == true;
    final learning = prefs.getBool('$_keyPrefix${today}_$_keyLearning') == true;
    final adhkar = prefs.getBool('$_keyPrefix${today}_$_keyAdhkar') == true;

    _cachedQuran = quran;
    _cachedLearning = learning;
    _cachedAdhkar = adhkar;

    return quran || learning || adhkar;
  }

  /// Get the last action type
  Future<String?> getLastAction() async {
    if (_cachedLastAction != null) {
      return _cachedLastAction;
    }
    final prefs = await SharedPreferences.getInstance();
    final action = prefs.getString('$_keyPrefix$_keyLastAction');
    _cachedLastAction = action;
    return action;
  }

  /// Check if user opened Quran today
  Future<bool> openedQuranToday() async {
    _ensureTodayCache();
    if (_cachedQuran != null) return _cachedQuran!;

    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getBool('$_keyPrefix${_todayKey()}_$_keyQuran') == true;
    _cachedQuran = val;
    return val;
  }

  /// Check if user continued learning today
  Future<bool> continuedLearningToday() async {
    _ensureTodayCache();
    if (_cachedLearning != null) return _cachedLearning!;

    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getBool('$_keyPrefix${_todayKey()}_$_keyLearning') == true;
    _cachedLearning = val;
    return val;
  }

  /// Check if user opened Adhkar today
  Future<bool> openedAdhkarToday() async {
    _ensureTodayCache();
    if (_cachedAdhkar != null) return _cachedAdhkar!;

    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getBool('$_keyPrefix${_todayKey()}_$_keyAdhkar') == true;
    _cachedAdhkar = val;
    return val;
  }

  /// Check if user visited today (even without action)
  Future<bool> visitedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastVisitStr = _cachedLastVisit ?? prefs.getString('$_keyPrefix$_keyLastVisit');
    if (lastVisitStr == null) return false;

    final lastVisit = DateTime.tryParse(lastVisitStr);
    if (lastVisit == null) return false;

    final now = DateTime.now();
    return lastVisit.year == now.year &&
        lastVisit.month == now.month &&
        lastVisit.day == now.day;
  }

  /// Check if this is a return visit (visited before today)
  Future<bool> isReturningUser() async {
    if (_cachedLastVisit != null) return true;
    final prefs = await SharedPreferences.getInstance();
    final lastVisitStr = prefs.getString('$_keyPrefix$_keyLastVisit');
    _cachedLastVisit = lastVisitStr;
    return lastVisitStr != null;
  }

  /// Prunes stale user_day tracking keys older than [retentionDays] to prevent storage bloat.
  static Future<int> pruneStaleKeys(
    SharedPreferences prefs, {
    DateTime? now,
    int retentionDays = 30,
  }) async {
    final current = now ?? DateTime.now();
    final cutoff = DateTime(current.year, current.month, current.day - retentionDays);
    final allKeys = prefs.getKeys();
    int prunedCount = 0;

    final dateRegex = RegExp(r'^user_day_(\d{4})-(\d{2})-(\d{2})_');
    for (final key in allKeys) {
      final match = dateRegex.firstMatch(key);
      if (match != null) {
        final year = int.tryParse(match.group(1)!);
        final month = int.tryParse(match.group(2)!);
        final day = int.tryParse(match.group(3)!);
        if (year != null && month != null && day != null) {
          final keyDate = DateTime(year, month, day);
          if (keyDate.isBefore(cutoff)) {
            await prefs.remove(key);
            prunedCount++;
          }
        }
      }
    }
    return prunedCount;
  }
}

