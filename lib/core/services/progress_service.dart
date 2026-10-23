import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/ilm/data/models/progress_models.dart';
import '../utils/async_lock.dart';

class ProgressService {
  static const _key = 'book_progress';
  static final AsyncLock _lock = AsyncLock();

  Future<void> saveProgress(BookProgress progress) {
    return _lock.synchronized(() async {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_key);

      Map<String, dynamic> map = {};
      if (data != null && data.isNotEmpty) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            map = decoded.map((k, v) => MapEntry(k.toString(), v));
          }
        } catch (_) {}
      }

      map[progress.bookId] = progress.toJson();
      await prefs.setString(_key, jsonEncode(map));
    });
  }

  Future<BookProgress?> getProgress(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null || data.isEmpty) return null;

    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map) return null;
      final raw = decoded[bookId];
      if (raw is! Map) return null;
      final typedMap = raw.map((k, v) => MapEntry(k.toString(), v));
      return BookProgress.fromJson(typedMap);
    } catch (_) {
      return null;
    }
  }

  Future<List<BookProgress>> getAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null || data.isEmpty) return [];

    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map) return [];
      final List<BookProgress> result = [];
      for (final val in decoded.values) {
        if (val is Map) {
          try {
            final typedMap = val.map((k, v) => MapEntry(k.toString(), v));
            result.add(BookProgress.fromJson(typedMap));
          } catch (_) {
            // Per-record recovery: ignore corrupted record
          }
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }
}
