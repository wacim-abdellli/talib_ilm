import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/salaf_gem.dart';

class SalafGemsRepository {
  SalafGemsRepository._();
  static final SalafGemsRepository instance = SalafGemsRepository._();

  static const String _favStorageKey = 'talib_ilm_salaf_gems_favorites_v1';
  static const String _assetPath = 'assets/data/salaf_gems.json';

  static const SalafGem fallbackGem = SalafGem(
    id: 'gem_default_01',
    author: 'عمر بن الخطاب رضي الله عنه',
    role: 'أمير المؤمنين وصحابي جليل',
    category: 'أقوال الصحابة',
    topic: 'الصدق والأمانة',
    text: 'لَا تَنْظُرُوا إِلَى صِيَامِ أَحَدٍ وَلَا صَلَاتِهِ، وَلَكِنِ انْظُرُوا إِلَى صِدْقِ حَدِيثِهِ إِذَا حَدَّثَ، وَأَمَانَتِهِ إِذَا ائْتُمِنَ، وَوَرَعِهِ إِذَا أَشْفَى.',
    sourceRef: 'حلية الأولياء لأبي نعيم (3/ 27)',
  );

  SalafGem getFallbackGem() {
    if (_cachedGems != null && _cachedGems!.isNotEmpty) {
      return _cachedGems!.first;
    }
    return fallbackGem;
  }

  List<SalafGem>? _cachedGems;
  Set<String>? _favoriteIds;
  final Random _random = Random();

  /// For testing overrides
  @visibleForTesting
  void setMockGems(List<SalafGem> gems) {
    _cachedGems = List.unmodifiable(gems);
  }

  /// For testing overrides
  @visibleForTesting
  void setMockFavorites(Set<String> favs) {
    _favoriteIds = Set.from(favs);
  }

  Future<List<SalafGem>> getAllGems() async {
    if (_cachedGems != null) {
      return _cachedGems!;
    }

    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final dynamic decoded = json.decode(jsonString);
      if (decoded is Map<String, dynamic> && decoded['gems'] is List) {
        final rawList = decoded['gems'] as List;
        final list = rawList
            .map((e) => SalafGem.fromJson(e as Map<String, dynamic>))
            .where((g) => g.text.isNotEmpty)
            .toList();
        // Deterministically mix gems so that every category and browsing view displays
        // a rich, diverse mix of sahaba, scholars, and topics instead of sequential blocks.
        list.shuffle(Random(114));
        _cachedGems = List.unmodifiable(list);
        return _cachedGems!;
      }
    } catch (_) {
      // Fallback fallback sample if assets fail
      _cachedGems = const [
        SalafGem(
          id: 'gem_default_01',
          author: 'عمر بن الخطاب رضي الله عنه',
          role: 'صحابي جليل',
          category: 'أقوال الصحابة',
          topic: 'الصدق والأمانة',
          text: 'لا تنظروا إلى صيام أحد ولا صلاته، ولكن انظروا إلى صدق حديثه إذا حدث، وأمانته إذا ائتمن.',
          sourceRef: 'حلية الأولياء لأبي نعيم (3/ 27)',
        ),
      ];
    }
    return _cachedGems!;
  }

  Future<SalafGem> getDailyGem({DateTime? customDate}) async {
    final gems = await getAllGems();
    if (gems.isEmpty) {
      return const SalafGem(
        id: 'gem_empty',
        author: 'من درر السلف',
        role: '',
        category: 'درر السلف',
        topic: 'طلب العلم',
        text: 'العلم ما نفع، ليس العلم ما حفظ.',
        sourceRef: 'الإمام الشافعي',
      );
    }
    final now = customDate ?? DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = (now.year * 365 + dayOfYear) % gems.length;
    return gems[index];
  }

  Future<SalafGem> getRandomGem({String? excludingId}) async {
    final gems = await getAllGems();
    if (gems.isEmpty) return (await getDailyGem());
    if (gems.length == 1) return gems.first;

    SalafGem candidate;
    int tries = 0;
    do {
      candidate = gems[_random.nextInt(gems.length)];
      tries++;
    } while (candidate.id == excludingId && tries < 5);

    return candidate;
  }

  Future<List<SalafGem>> searchGems({
    String? query,
    String? category,
    String? author,
    bool onlyFavorites = false,
  }) async {
    final gems = await getAllGems();
    final favIds = await getFavoriteIds();

    final cleanQuery = query?.trim().toLowerCase();
    final hasQuery = cleanQuery != null && cleanQuery.isNotEmpty;

    return gems.where((gem) {
      if (onlyFavorites && !favIds.contains(gem.id)) {
        return false;
      }

      if (category != null && category != 'الكل' && gem.category != category) {
        return false;
      }

      if (author != null && author != 'الكل' && !gem.author.contains(author)) {
        return false;
      }

      if (hasQuery) {
        final matchesText = gem.text.toLowerCase().contains(cleanQuery);
        final matchesAuthor = gem.author.toLowerCase().contains(cleanQuery);
        final matchesTopic = gem.topic.toLowerCase().contains(cleanQuery);
        final matchesRef = gem.sourceRef.toLowerCase().contains(cleanQuery);
        if (!matchesText && !matchesAuthor && !matchesTopic && !matchesRef) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  static const List<String> canonicalCategoryOrder = [
    'الكل',
    'أقوال الصحابة',
    'درر السلف',
    'وصايا نبوية',
    'فوائد المحققين',
    'في طلب العلم',
    'فضائل الأعمال',
    'أحاديث قدسية',
  ];

  Future<List<String>> getAllCategories() async {
    final gems = await getAllGems();
    final set = <String>{};
    for (final g in gems) {
      if (g.category.isNotEmpty) set.add(g.category);
    }
    final ordered = <String>['الكل'];
    for (final cat in canonicalCategoryOrder) {
      if (cat != 'الكل' && set.contains(cat)) {
        ordered.add(cat);
      }
    }
    for (final cat in set) {
      if (!ordered.contains(cat)) {
        ordered.add(cat);
      }
    }
    return ordered;
  }

  Future<List<String>> getTopAuthors() async {
    return const [
      'الكل',
      'أبو بكر الصديق',
      'عمر بن الخطاب',
      'علي بن أبي طالب',
      'عبد الله بن مسعود',
      'أبو هريرة',
      'أبو الدرداء',
      'معاذ بن جبل',
      'الحسن البصري',
      'عمر بن عبد العزيز',
      'الفضيل بن عياض',
      'عبد الله بن المبارك',
      'مالك بن دينار',
      'يحيى بن معاذ',
      'سفيان الثوري',
      'الإمام الشافعي',
      'الإمام أحمد بن حنبل',
      'الإمام ابن القيم',
      'شيخ الإسلام ابن تيمية',
      'الإمام ابن رجب',
      'الإمام الذهبي',
      'رسول الله ﷺ',
    ];
  }

  Future<Set<String>> getFavoriteIds() async {
    if (_favoriteIds != null) return _favoriteIds!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_favStorageKey) ?? [];
      _favoriteIds = list.toSet();
    } catch (_) {
      _favoriteIds = <String>{};
    }
    return _favoriteIds!;
  }

  Future<bool> isFavorite(String id) async {
    final ids = await getFavoriteIds();
    return ids.contains(id);
  }

  Future<bool> toggleFavorite(String id) async {
    final ids = await getFavoriteIds();
    final willFavorite = !ids.contains(id);
    if (willFavorite) {
      ids.add(id);
    } else {
      ids.remove(id);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favStorageKey, ids.toList(growable: false));
    } catch (_) {}
    return willFavorite;
  }
}
