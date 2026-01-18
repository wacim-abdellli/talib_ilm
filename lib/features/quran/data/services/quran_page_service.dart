import '../database/quran_database.dart';

/// Quran Page Service - Offline Only (Read from DB)
/// API calls are now handled by QuranSyncService during setup.
class QuranPageService {
  /// Get page from local DB
  static Future<QuranPageData?> getPage(int pageNumber) async {
    return QuranDatabase.instance.getPage(pageNumber);
  }

  /// Optional: Preload neighboring pages into OS/Memory cache
  static Future<void> preloadPage(int pageNumber) async {
    // SQLite is fast, but we can dry-run queries if needed.
    // Ideally we rely on the PageView's builder to trigger getPage.
  }
}

/// Quran Page Data Model
class QuranPageData {
  final int pageNumber;
  final List<PageVerse> verses;
  final int? juzNumber;
  final int? hizbNumber;

  QuranPageData({
    required this.pageNumber,
    required this.verses,
    this.juzNumber,
    this.hizbNumber,
  });

  factory QuranPageData.fromApiResponse(
    int pageNumber,
    Map<String, dynamic> json,
  ) {
    final versesJson = json['verses'] as List<dynamic>? ?? [];
    final verses = versesJson.map((v) => PageVerse.fromJson(v)).toList();

    return QuranPageData(
      pageNumber: pageNumber,
      verses: verses,
      juzNumber: verses.isNotEmpty ? verses.first.juzNumber : null,
      hizbNumber: verses.isNotEmpty ? verses.first.hizbNumber : null,
    );
  }

  factory QuranPageData.fromJson(Map<String, dynamic> json) {
    return QuranPageData(
      pageNumber: json['pageNumber'],
      verses: (json['verses'] as List)
          .map((v) => PageVerse.fromJson(v))
          .toList(),
      juzNumber: json['juzNumber'],
      hizbNumber: json['hizbNumber'],
    );
  }

  Map<String, dynamic> toJson() => {
    'pageNumber': pageNumber,
    'verses': verses.map((v) => v.toJson()).toList(),
    'juzNumber': juzNumber,
    'hizbNumber': hizbNumber,
  };
}

/// Single Verse Model
class PageVerse {
  final int id;
  final int surahNumber;
  final int verseNumber;
  final String textUthmani;
  final int juzNumber;
  final int hizbNumber;
  final int rubElHizbNumber;
  final String? verseKey;

  PageVerse({
    required this.id,
    required this.surahNumber,
    required this.verseNumber,
    required this.textUthmani,
    required this.juzNumber,
    required this.hizbNumber,
    required this.rubElHizbNumber,
    this.verseKey,
  });

  factory PageVerse.fromJson(Map<String, dynamic> json) {
    final verseKey = json['verse_key'] ?? json['verseKey'];
    int surahNum = json['surahNumber'] ?? 1;
    int verseNum = json['verseNumber'] ?? 1;

    if (verseKey != null && verseKey is String) {
      final parts = verseKey.split(':');
      if (parts.length == 2) {
        surahNum = int.tryParse(parts[0]) ?? surahNum;
        verseNum = int.tryParse(parts[1]) ?? verseNum;
      }
    }

    return PageVerse(
      id: json['id'] ?? 0,
      surahNumber: surahNum,
      verseNumber: verseNum,
      textUthmani: json['text_uthmani'] ?? json['textUthmani'] ?? '',
      juzNumber: json['juz_number'] ?? json['juzNumber'] ?? 1,
      hizbNumber: json['hizb_number'] ?? json['hizbNumber'] ?? 1,
      rubElHizbNumber:
          json['rub_el_hizb_number'] ?? json['rubElHizbNumber'] ?? 1,
      verseKey: verseKey,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'surahNumber': surahNumber,
    'verseNumber': verseNumber,
    'textUthmani': textUthmani,
    'juzNumber': juzNumber,
    'hizbNumber': hizbNumber,
    'rubElHizbNumber': rubElHizbNumber,
    'verseKey': verseKey,
  };
}
