import 'dart:async';

import 'package:flutter/foundation.dart';
import '../services/prayer_time_service.dart';
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

  PrayerTimesDay _day;
  Timer? _timer;
  bool _loadingNextDay = false;

  final ValueNotifier<PrayerCountdownState> state;

  PrayerCountdownController({
    required PrayerTimesDay day,
    PrayerTimeService? prayerTimeService,
    DateTime Function()? now,
  })  : _day = day,
        _prayerTimeService = prayerTimeService ?? PrayerTimeService(),
        now = now ?? DateTime.now,
        state = ValueNotifier<PrayerCountdownState>(
          PrayerCountdownState(
            nextPrayerName: day.nextPrayer,
            nextPrayerTime: day.prayers[day.nextPrayer] ?? DateTime.now(),
            remaining: Duration.zero,
          ),
        );

  void start() {
    _tick();
    _timer = Timer.periodic(AppPolicy.oneSecond, (_) => _tick());
  }

  void dispose() {
    _timer?.cancel();
    state.dispose();
  }

  Future<void> _tick() async {
    final current = now();
    const iqamaDuration = Duration(minutes: 15);

    // 1. Check if any prayer is currently within its 15-minute Iqama/Prayer window
    final entries = _day.prayers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (int i = entries.length - 1; i >= 0; i--) {
      final entry = entries[i];
      if (entry.key.contains('الشروق')) continue;
      if (!current.isBefore(entry.value)) {
        final elapsed = current.difference(entry.value);
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
