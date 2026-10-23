import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles persistence of bookmarks and notes specific to Sharh (commentary) books.
class SharhAnnotationService {
  static const String sharhBookmarksKey = 'sharh_bookmarks';
  static const String sharhNotesKey = 'sharh_notes';

  final SharedPreferences _prefs;

  SharhAnnotationService(this._prefs);

  String _sharhKey(String bookId, String sharhFile) => '$bookId|$sharhFile';

  Future<Map<String, List<int>>> loadSharhBookmarks() async {
    final jsonString = _prefs.getString(sharhBookmarksKey);
    if (jsonString == null) return {};
    final raw = json.decode(jsonString) as Map<String, dynamic>;
    return {
      for (final entry in raw.entries)
        entry.key: (entry.value as List<dynamic>)
            .map((value) => value is int ? value : int.tryParse('$value') ?? 0)
            .where((page) => page > 0)
            .toList(),
    };
  }

  Future<void> saveSharhBookmarksData(Map<String, List<int>> data) async {
    final jsonString = json.encode(data);
    await _prefs.setString(sharhBookmarksKey, jsonString);
  }

  Future<List<int>> getSharhBookmarks(String bookId, String sharhFile) async {
    final data = await loadSharhBookmarks();
    return data[_sharhKey(bookId, sharhFile)] ?? <int>[];
  }

  Future<void> addSharhBookmark(
    String bookId,
    String sharhFile,
    int page,
  ) async {
    final data = await loadSharhBookmarks();
    final key = _sharhKey(bookId, sharhFile);
    final pages = List<int>.from(data[key] ?? <int>[]);
    if (!pages.contains(page)) {
      pages.add(page);
      pages.sort();
    }
    data[key] = pages;
    await saveSharhBookmarksData(data);
  }

  Future<void> removeSharhBookmark(
    String bookId,
    String sharhFile,
    int page,
  ) async {
    final data = await loadSharhBookmarks();
    final key = _sharhKey(bookId, sharhFile);
    final pages = List<int>.from(data[key] ?? <int>[])..remove(page);
    data[key] = pages;
    await saveSharhBookmarksData(data);
  }

  Future<Map<String, Map<int, String>>> loadSharhNotes() async {
    final jsonString = _prefs.getString(sharhNotesKey);
    if (jsonString == null) return {};
    final raw = json.decode(jsonString) as Map<String, dynamic>;
    final result = <String, Map<int, String>>{};
    for (final entry in raw.entries) {
      final notesRaw = entry.value as Map<String, dynamic>;
      result[entry.key] = {
        for (final note in notesRaw.entries)
          int.tryParse(note.key) ?? 0: note.value?.toString() ?? '',
      }..removeWhere((key, value) => key == 0 || value.isEmpty);
    }
    return result;
  }

  Future<void> saveSharhNotesData(Map<String, Map<int, String>> data) async {
    final encoded = {
      for (final entry in data.entries)
        entry.key: {
          for (final note in entry.value.entries)
            note.key.toString(): note.value,
        },
    };
    await _prefs.setString(sharhNotesKey, json.encode(encoded));
  }

  Future<Map<int, String>> getSharhNotes(
    String bookId,
    String sharhFile,
  ) async {
    final data = await loadSharhNotes();
    return data[_sharhKey(bookId, sharhFile)] ?? <int, String>{};
  }

  Future<void> saveSharhNote(
    String bookId,
    String sharhFile,
    int page,
    String note,
  ) async {
    final data = await loadSharhNotes();
    final key = _sharhKey(bookId, sharhFile);
    final notes = Map<int, String>.from(data[key] ?? <int, String>{});
    notes[page] = note;
    data[key] = notes;
    await saveSharhNotesData(data);
  }

  Future<void> deleteSharhNote(
    String bookId,
    String sharhFile,
    int page,
  ) async {
    final data = await loadSharhNotes();
    final key = _sharhKey(bookId, sharhFile);
    final notes = Map<int, String>.from(data[key] ?? <int, String>{});
    notes.remove(page);
    data[key] = notes;
    await saveSharhNotesData(data);
  }

  Future<Map<String, List<int>>> getAllSharhBookmarks() async {
    return loadSharhBookmarks();
  }

  Future<Map<String, Map<int, String>>> getAllSharhNotes() async {
    return loadSharhNotes();
  }
}
