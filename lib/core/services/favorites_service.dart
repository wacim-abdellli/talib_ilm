import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_item.dart';

class FavoritesService {
  static const _key = 'favorites_items';

  Future<List<FavoriteItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    return raw
        .map(_decode)
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<Set<String>> getIdsByType(FavoriteType type) async {
    final items = await getAll();
    return items
        .where((item) => item.type == type)
        .map((item) => item.id)
        .toSet();
  }

  Future<bool> isFavorite(FavoriteType type, String id) async {
    final items = await getAll();
    return items.any((item) => item.type == type && item.id == id);
  }

  Future<bool> toggle(FavoriteItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    final items = raw.map(_decode).toList();
    final index = items.indexWhere(
      (existing) => existing.type == item.type && existing.id == item.id,
    );

    if (index >= 0) {
      items.removeAt(index);
      await prefs.setStringList(_key, items.map(_encode).toList());
      return false;
    }

    items.add(item);
    await prefs.setStringList(_key, items.map(_encode).toList());
    return true;
  }

  Future<void> remove(FavoriteType type, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    final items = raw.map(_decode).toList();
    items.removeWhere((item) => item.type == type && item.id == id);
    await prefs.setStringList(_key, items.map(_encode).toList());
  }

  FavoriteItem _decode(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        return FavoriteItem.fromJson(json);
      }
    } catch (_) {}
    return const FavoriteItem(
      type: FavoriteType.hadith,
      id: '',
      title: '',
      subtitle: '',
    );
  }

  String _encode(FavoriteItem item) {
    return jsonEncode(item.toJson());
  }
}
