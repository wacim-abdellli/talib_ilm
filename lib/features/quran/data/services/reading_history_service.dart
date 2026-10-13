import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single chronological reading history record.
class ReadingHistoryItem {
  final int surah;
  final int ayah;
  final int page;
  final DateTime timestamp;

  const ReadingHistoryItem({
    required this.surah,
    required this.ayah,
    required this.page,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'surah': surah,
        'ayah': ayah,
        'page': page,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ReadingHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReadingHistoryItem(
      surah: json['surah'] as int? ?? 1,
      ayah: json['ayah'] as int? ?? 1,
      page: json['page'] as int? ?? 1,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Service managing chronological user reading history with capping and throttling.
class ReadingHistoryService {
  static const String _historyKey = 'reading_history_v1';
  static const int maxHistoryEntries = 50;

  static final ValueNotifier<List<ReadingHistoryItem>> historyNotifier =
      ValueNotifier<List<ReadingHistoryItem>>([]);

  static DateTime? _lastRecordedAt;
  static int? _lastRecordedSurah;
  static int? _lastRecordedPage;

  /// Loads reading history from SharedPreferences.
  static Future<List<ReadingHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_historyKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      historyNotifier.value = [];
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      final items = list.map((e) => ReadingHistoryItem.fromJson(e)).toList();
      historyNotifier.value = items;
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Records a reading event.
  /// Throttled so that rapid swipe frames or repeated visits within 15 seconds
  /// to the same page/surah are not duplicated.
  static Future<void> recordReading({
    required int surah,
    required int ayah,
    required int page,
  }) async {
    final now = DateTime.now();

    // Throttle: avoid recording duplicate entry if same surah & page within 15s
    if (_lastRecordedSurah == surah &&
        _lastRecordedPage == page &&
        _lastRecordedAt != null &&
        now.difference(_lastRecordedAt!).inSeconds < 15) {
      return;
    }

    _lastRecordedAt = now;
    _lastRecordedSurah = surah;
    _lastRecordedPage = page;

    final current = await getHistory();

    // Remove any identical prior verse entry to bring it to the top
    current.removeWhere((item) => item.surah == surah && item.page == page);

    // Insert new item at the top
    current.insert(
      0,
      ReadingHistoryItem(
        surah: surah,
        ayah: ayah,
        page: page,
        timestamp: now,
      ),
    );

    // Cap at maxHistoryEntries
    if (current.length > maxHistoryEntries) {
      current.removeRange(maxHistoryEntries, current.length);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );

    historyNotifier.value = List.unmodifiable(current);
  }

  /// Clears all reading history entries.
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    _lastRecordedAt = null;
    _lastRecordedSurah = null;
    _lastRecordedPage = null;
    historyNotifier.value = [];
  }
}
