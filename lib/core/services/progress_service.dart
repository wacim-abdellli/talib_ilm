import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/ilm/data/models/progress_models.dart';

class ProgressService {
  static const _key = 'book_progress';

  Future<void> saveProgress(BookProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);

    final Map<String, dynamic> map =
        data == null ? {} : jsonDecode(data);

    map[progress.bookId] = progress.toJson();

    await prefs.setString(_key, jsonEncode(map));
  }

  Future<BookProgress?> getProgress(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return null;

    final map = jsonDecode(data) as Map<String, dynamic>;
    if (!map.containsKey(bookId)) return null;

    return BookProgress.fromJson(map[bookId]);
  }

  Future<List<BookProgress>> getAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];

    final map = jsonDecode(data) as Map<String, dynamic>;
    return map.values
        .map<BookProgress>((e) => BookProgress.fromJson(e))
        .toList();
  }
}
