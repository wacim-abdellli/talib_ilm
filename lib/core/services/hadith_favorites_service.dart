import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/domain/models/hadith.dart';

class HadithFavoritesService {
  static const _key = 'hadith_favorites';

  Future<bool> isSaved(Hadith hadith) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key) ?? <String>[];
    return saved.contains(_idFor(hadith));
  }

  Future<bool> toggleSaved(Hadith hadith) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key) ?? <String>[];
    final id = _idFor(hadith);

    if (saved.contains(id)) {
      saved.remove(id);
      await prefs.setStringList(_key, saved);
      return false;
    }

    saved.add(id);
    await prefs.setStringList(_key, saved);
    return true;
  }

  String _idFor(Hadith hadith) {
    return '${hadith.text}||${hadith.source}';
  }
}
