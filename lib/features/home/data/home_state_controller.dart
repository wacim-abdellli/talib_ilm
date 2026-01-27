import 'package:flutter/foundation.dart';
import '../../../core/services/user_day_tracker.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../features/prayer/data/models/prayer_models.dart';

/// Emotional states for the Home screen
/// Each state affects hierarchy, emphasis, and tone
enum HomeEmotionalState {
  /// ≤20-30 min before prayer - subtle urgency
  approachingPrayer,

  /// Adhan time → +30 min - maximum prayer focus
  prayerWindow,

  /// After prayer window - calm continuation
  postPrayerCalm,

  /// User has acted today - acknowledged
  userProgressed,

  /// No action today - quiet invitation
  userAbsent,
}

/// Calculates current emotional state based on prayer timing and user actions
class HomeStateController extends ChangeNotifier {
  final UserDayTracker _dayTracker;
  final PrayerTimeService _prayerService;

  HomeEmotionalState _currentState = HomeEmotionalState.userAbsent;
  PrayerTimesDay? _prayerDay;
  bool _hasActedToday = false;
  String? _lastAction;
  int _minutesToNextPrayer = 999;
  int _minutesSinceLastPrayer = 999;

  HomeEmotionalState get currentState => _currentState;
  PrayerTimesDay? get prayerDay => _prayerDay;
  bool get hasActedToday => _hasActedToday;
  String? get lastAction => _lastAction;
  int get minutesToNextPrayer => _minutesToNextPrayer;

  /// Nearness factor: 0.0 = far (>30min), 1.0 = imminent (0min)
  double get nearnessFactor {
    if (_minutesToNextPrayer >= 30) return 0.0;
    if (_minutesToNextPrayer <= 0) return 1.0;
    return 1.0 - (_minutesToNextPrayer / 30.0);
  }

  /// Whether in prayer window (0 to +30 min after adhan)
  bool get isInPrayerWindow {
    return _minutesToNextPrayer <= 0 && _minutesSinceLastPrayer <= 30;
  }

  HomeStateController({
    UserDayTracker? dayTracker,
    PrayerTimeService? prayerService,
  }) : _dayTracker = dayTracker ?? UserDayTracker(),
       _prayerService = prayerService ?? PrayerTimeService();

  /// Initialize and calculate current state
  Future<void> initialize() async {
    await _loadUserState();
    await _loadPrayerTimes();
    _calculateState();
    notifyListeners();
  }

  /// Refresh state (call periodically or on resume)
  Future<void> refresh() async {
    await _loadUserState();
    _calculateState();
    notifyListeners();
  }

  Future<void> _loadUserState() async {
    _hasActedToday = await _dayTracker.hasActedToday();
    _lastAction = await _dayTracker.getLastAction();
  }

  Future<void> _loadPrayerTimes() async {
    _prayerDay = await _prayerService.getPrayerTimesDay();
    _updatePrayerProximity();
  }

  void _updatePrayerProximity() {
    if (_prayerDay == null) return;

    final now = DateTime.now();
    final prayers = _prayerDay!.prayers;
    final nextPrayerName = _prayerDay!.nextPrayer;
    final nextPrayerTime = prayers[nextPrayerName];

    if (nextPrayerTime != null) {
      _minutesToNextPrayer = nextPrayerTime.difference(now).inMinutes;
    }

    // Find minutes since last prayer
    DateTime? lastPrayerTime;
    for (final entry in prayers.entries) {
      if (entry.value.isBefore(now)) {
        if (lastPrayerTime == null || entry.value.isAfter(lastPrayerTime)) {
          lastPrayerTime = entry.value;
        }
      }
    }

    if (lastPrayerTime != null) {
      _minutesSinceLastPrayer = now.difference(lastPrayerTime).inMinutes;
    }
  }

  void _calculateState() {
    _updatePrayerProximity();

    // Priority 1: Prayer window (adhan to +30 min)
    if (_minutesToNextPrayer <= 0 && _minutesSinceLastPrayer <= 30) {
      _currentState = HomeEmotionalState.prayerWindow;
      return;
    }

    // Priority 2: Approaching prayer (≤30 min before)
    if (_minutesToNextPrayer > 0 && _minutesToNextPrayer <= 30) {
      _currentState = HomeEmotionalState.approachingPrayer;
      return;
    }

    // Priority 3: Post-prayer calm (30-90 min after prayer)
    if (_minutesSinceLastPrayer > 30 && _minutesSinceLastPrayer <= 90) {
      _currentState = HomeEmotionalState.postPrayerCalm;
      return;
    }

    // Priority 4: User progressed (has acted today)
    if (_hasActedToday) {
      _currentState = HomeEmotionalState.userProgressed;
      return;
    }

    // Default: User absent
    _currentState = HomeEmotionalState.userAbsent;
  }

  /// Record user action and update state
  Future<void> recordQuranOpened() async {
    await _dayTracker.recordQuranOpened();
    await refresh();
  }

  Future<void> recordLearningContinued() async {
    await _dayTracker.recordLearningContinued();
    await refresh();
  }

  Future<void> recordAdhkarOpened() async {
    await _dayTracker.recordAdhkarOpened();
    await refresh();
  }

  /// Get presence message based on current state
  String? getPresenceMessage() {
    switch (_currentState) {
      case HomeEmotionalState.prayerWindow:
        return 'حان الوقت';
      case HomeEmotionalState.approachingPrayer:
        if (_minutesToNextPrayer <= 5) return 'قريبًا جدًا';
        if (_minutesToNextPrayer <= 10) return 'قريب';
        return 'يقترب';
      case HomeEmotionalState.postPrayerCalm:
        return 'واصل التقدّم';
      case HomeEmotionalState.userProgressed:
        if (_lastAction == 'learning') return 'واصلت التعلّم';
        if (_lastAction == 'quran') return 'قرأت اليوم';
        if (_lastAction == 'adhkar') return 'ذكرت اليوم';
        return 'عدت اليوم';
      case HomeEmotionalState.userAbsent:
        return null; // Silent, no guilt
    }
  }

  /// Get hierarchy weights for current state
  /// Returns map of element -> weight (0.0 to 1.0)
  Map<String, double> getHierarchyWeights() {
    switch (_currentState) {
      case HomeEmotionalState.approachingPrayer:
      case HomeEmotionalState.prayerWindow:
        return {'prayer': 1.0, 'learning': 0.7, 'quote': 0.5, 'actions': 0.6};
      case HomeEmotionalState.postPrayerCalm:
        return {'prayer': 0.7, 'learning': 1.0, 'quote': 0.8, 'actions': 0.7};
      case HomeEmotionalState.userProgressed:
        return {'prayer': 0.8, 'learning': 0.9, 'quote': 0.7, 'actions': 0.8};
      case HomeEmotionalState.userAbsent:
        return {
          'prayer': 0.8,
          'learning': 0.85, // Soft invitation
          'quote': 0.6,
          'actions': 0.6,
        };
    }
  }
}
