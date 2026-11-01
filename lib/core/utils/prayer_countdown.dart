import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../app/constants/app_strings.dart';
import '../services/prayer_time_service.dart';
import '../services/iqama_timing_policy.dart';
import '../constants/app_policy.dart';
import '../../features/prayer/data/models/prayer_models.dart';

class PrayerCountdownState {
  final String nextPrayerName;
  final DateTime nextPrayerTime;
  final Duration remaining;
  final bool isInPrayerTime;
  final Duration elapsed;

  const PrayerCountdownState({
    required this.nextPrayerName,
    required this.nextPrayerTime,
    required this.remaining,
    this.isInPrayerTime = false,
    this.elapsed = Duration.zero,
  });
}

class PrayerCountdownController {
  final PrayerTimeService _prayerTimeService;
  final DateTime Function() now;
  Map<String, int> _iqamaOverrides;

  PrayerTimesDay _day;
  Timer? _timer;
  bool _loadingNextDay = false;

  final ValueNotifier<PrayerCountdownState> state;

  PrayerCountdownController({
    required PrayerTimesDay day,
    PrayerTimeService? prayerTimeService,
    DateTime Function()? now,
    Map<String, int> iqamaOverrides = const {},
  })  : _day = day,
        _prayerTimeService = prayerTimeService ?? PrayerTimeService(),
        _iqamaOverrides = iqamaOverrides,
        now = now ?? DateTime.now,
        state = ValueNotifier<PrayerCountdownState>(
          _initialState(day, now ?? DateTime.now),
        );

  static PrayerCountdownState _initialState(
    PrayerTimesDay day,
    DateTime Function() nowFn,
  ) {
    final current = nowFn();
    final nextPrayerName = day.nextPrayer;
    var nextPrayerTime = day.nextPrayerTime ?? day.prayers[nextPrayerName] ?? current;
    if (nextPrayerTime.isBefore(current) && nextPrayerName == AppStrings.prayerFajr) {
      nextPrayerTime = nextPrayerTime.add(const Duration(days: 1));
    }
    final remaining = nextPrayerTime.difference(current);
    return PrayerCountdownState(
      nextPrayerName: nextPrayerName,
      nextPrayerTime: nextPrayerTime,
      remaining: remaining.isNegative ? Duration.zero : remaining,
    );
  }

  void updateDay(PrayerTimesDay day) {
    _day = day;
    unawaited(_tick());
  }

  void start() {
    _tick();
    _timer = Timer.periodic(AppPolicy.oneSecond, (_) => _tick());
  }

  void updateIqamaOverrides(Map<String, int> overrides) {
    _iqamaOverrides = overrides;
    unawaited(_tick());
  }

  void dispose() {
    _timer?.cancel();
    state.dispose();
  }

  Future<void> _tick() async {
    final current = now();
    // 1. Check whether the current prayer is before its configured Iqama time.
    final entries = _day.prayers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (int i = entries.length - 1; i >= 0; i--) {
      final entry = entries[i];
      if (entry.key.contains('الشروق')) continue;
      if (!current.isBefore(entry.value)) {
        final elapsed = current.difference(entry.value);
        final isJumua = current.weekday == DateTime.friday &&
            entry.key == AppStrings.prayerDhuhr;
        final iqamaMinutes = IqamaTimingPolicy.minutesAfterAdhan(
          entry.key,
          isJumua: isJumua,
          configuredMinutes: _iqamaOverrides,
        );
        final iqamaDuration = Duration(minutes: iqamaMinutes);
        if (elapsed < iqamaDuration) {
          state.value = PrayerCountdownState(
            nextPrayerName: entry.key,
            nextPrayerTime: entry.value,
            remaining: Duration.zero,
            isInPrayerTime: true,
            elapsed: elapsed,
          );
          return;
        }
      }
    }

    // 2. Find next upcoming prayer today
    final nextEntry = _findNextPrayer(_day.prayers, current);

    if (nextEntry == null) {
      // All of today's prayers have passed (after Isha). Next prayer is tomorrow's Fajr.
      var nextPrayerTime = _day.nextPrayerTime ??
          _day.prayers[AppStrings.prayerFajr]?.add(const Duration(days: 1)) ??
          current.add(const Duration(hours: 8));
      if (nextPrayerTime.isBefore(current)) {
        nextPrayerTime = nextPrayerTime.add(const Duration(days: 1));
      }
      final remaining = nextPrayerTime.difference(current);
      state.value = PrayerCountdownState(
        nextPrayerName: AppStrings.prayerFajr,
        nextPrayerTime: nextPrayerTime,
        remaining: remaining.isNegative ? Duration.zero : remaining,
        isInPrayerTime: false,
        elapsed: Duration.zero,
      );
      await _loadNextDay(current);
      return;
    }

    final remaining = nextEntry.value.difference(current);
    state.value = PrayerCountdownState(
      nextPrayerName: nextEntry.key,
      nextPrayerTime: nextEntry.value,
      remaining: remaining.isNegative ? Duration.zero : remaining,
      isInPrayerTime: false,
      elapsed: Duration.zero,
    );
  }

  Future<void> _loadNextDay(DateTime current) async {
    if (_loadingNextDay) return;
    _loadingNextDay = true;
    try {
      final tomorrow = current.add(const Duration(days: 1));
      _day = await _prayerTimeService.getPrayerTimesDay(date: tomorrow);
    } finally {
      _loadingNextDay = false;
    }
  }

  MapEntry<String, DateTime>? _findNextPrayer(
    Map<String, DateTime> prayers,
    DateTime current,
  ) {
    final entries = prayers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (final entry in entries) {
      if (!entry.value.isBefore(current)) {
        return entry;
      }
    }

    return null;
  }
}
