import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_item.dart';

class FavoritesService {
  static const _key = 'favorites_items';

  static List<String>? _cachedRawList;
  static List<FavoriteItem>? _cachedFavorites;

  @visibleForTesting
  static void resetCacheForTesting() {
    _cachedRawList = null;
    _cachedFavorites = null;
  }

  Future<List<FavoriteItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];

    if (_cachedRawList != null &&
        _cachedFavorites != null &&
        listEquals(_cachedRawList, raw)) {
      return List.of(_cachedFavorites!);
    }

    final items = raw
        .map(_decode)
        .where((item) => item.id.isNotEmpty)
        .toList();

    _cachedRawList = List.of(raw);
    _cachedFavorites = items;
    return List.of(items);
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
    final items = await getAll();
    final index = items.indexWhere(
      (existing) => existing.type == item.type && existing.id == item.id,
    );

    final bool isAdded;
    if (index >= 0) {
      items.removeAt(index);
      isAdded = false;
    } else {
      items.add(item);
      isAdded = true;
    }

    final raw = items.map(_encode).toList();
    _cachedRawList = List.of(raw);
    _cachedFavorites = items;
    await prefs.setStringList(_key, raw);
    return isAdded;
  }

  Future<void> add(FavoriteItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getAll();
    final exists = items.any(
      (existing) => existing.type == item.type && existing.id == item.id,
    );
    if (!exists) {
      items.add(item);
      final raw = items.map(_encode).toList();
      _cachedRawList = List.of(raw);
      _cachedFavorites = items;
      await prefs.setStringList(_key, raw);
    }
  }

  Future<void> remove(FavoriteType type, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getAll();
    items.removeWhere((item) => item.type == type && item.id == id);
    final raw = items.map(_encode).toList();
    _cachedRawList = List.of(raw);
    _cachedFavorites = items;
    await prefs.setStringList(_key, raw);
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

