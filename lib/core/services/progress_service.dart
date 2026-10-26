import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/ilm/data/models/progress_models.dart';
import '../utils/async_lock.dart';

class ProgressService {
  static const _key = 'book_progress';
  static final AsyncLock _lock = AsyncLock();

  // In-memory cache guarded by raw JSON string comparison
  static String? _cachedRawData;
  static Map<String, BookProgress>? _cachedProgress;

  @visibleForTesting
  static void resetCacheForTesting() {
    _cachedRawData = null;
    _cachedProgress = null;
  }

  Future<Map<String, BookProgress>> _getOrLoadProgress(SharedPreferences prefs) async {
    final data = prefs.getString(_key);
    if (data == _cachedRawData && _cachedProgress != null) {
      return _cachedProgress!;
    }

    final Map<String, BookProgress> result = {};
    if (data != null && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final val = entry.value;
            if (val is Map) {
              try {
                final typedMap = val.map((k, v) => MapEntry(k.toString(), v));
                result[entry.key.toString()] = BookProgress.fromJson(typedMap);
              } catch (_) {
                // Per-record recovery: ignore corrupted record
              }
            }
          }
        }
      } catch (_) {}
    }

    _cachedRawData = data;
    _cachedProgress = result;
    return result;
  }

  Future<void> saveProgress(BookProgress progress) {
    return _lock.synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      final map = await _getOrLoadProgress(prefs);

      map[progress.bookId] = progress;
      final serialized = map.map((k, v) => MapEntry(k, v.toJson()));
      final encoded = jsonEncode(serialized);

      _cachedRawData = encoded;
      _cachedProgress = map;
      await prefs.setString(_key, encoded);
    });
  }

  Future<BookProgress?> getProgress(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _getOrLoadProgress(prefs);
    return map[bookId];
  }

  Future<List<BookProgress>> getAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _getOrLoadProgress(prefs);
    return map.values.toList();
  }
}

