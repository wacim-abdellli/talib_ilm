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

  /// Get today's date key
  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Record that user opened Quran today
  Future<void> recordQuranOpened() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix${_todayKey()}_$_keyQuran', true);
    await prefs.setString('$_keyPrefix$_keyLastAction', 'quran');
    await _recordVisit();
  }

  /// Record that user continued learning today
  Future<void> recordLearningContinued() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix${_todayKey()}_$_keyLearning', true);
    await prefs.setString('$_keyPrefix$_keyLastAction', 'learning');
    await _recordVisit();
  }

  /// Record that user opened Adhkar today
  Future<void> recordAdhkarOpened() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix${_todayKey()}_$_keyAdhkar', true);
    await prefs.setString('$_keyPrefix$_keyLastAction', 'adhkar');
    await _recordVisit();
  }

  /// Record visit timestamp
  Future<void> _recordVisit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyPrefix$_keyLastVisit',
      DateTime.now().toIso8601String(),
    );
  }

  /// Record any home visit (even without action)
  Future<void> recordHomeVisit() async {
    await _recordVisit();
  }

  /// Check if user has done any meaningful action today
  Future<bool> hasActedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    return prefs.getBool('$_keyPrefix${today}_$_keyQuran') == true ||
        prefs.getBool('$_keyPrefix${today}_$_keyLearning') == true ||
        prefs.getBool('$_keyPrefix${today}_$_keyAdhkar') == true;
  }

  /// Get the last action type
  Future<String?> getLastAction() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_keyPrefix$_keyLastAction');
  }

  /// Check if user opened Quran today
  Future<bool> openedQuranToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyPrefix${_todayKey()}_$_keyQuran') == true;
  }

  /// Check if user continued learning today
  Future<bool> continuedLearningToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyPrefix${_todayKey()}_$_keyLearning') == true;
  }

  /// Check if user opened Adhkar today
  Future<bool> openedAdhkarToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyPrefix${_todayKey()}_$_keyAdhkar') == true;
  }

  /// Check if user visited today (even without action)
  Future<bool> visitedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastVisitStr = prefs.getString('$_keyPrefix$_keyLastVisit');
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
    final prefs = await SharedPreferences.getInstance();
    final lastVisitStr = prefs.getString('$_keyPrefix$_keyLastVisit');
    return lastVisitStr != null;
  }
}
