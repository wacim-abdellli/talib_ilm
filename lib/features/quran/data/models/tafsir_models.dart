/// Tafsir source enum
enum TafsirSource { ibnKathir, saadi, muyassar }

extension TafsirSourceExtension on TafsirSource {
  /// quran.com API v4 resource ID
  String get id {
    switch (this) {
      case TafsirSource.ibnKathir:
        return '14'; // Arabic Ibn Kathir
      case TafsirSource.saadi:
        return '91'; // Arabic Al-Sa'di
      case TafsirSource.muyassar:
        return '16'; // Arabic Muyassar
    }
  }

  String get displayName {
    switch (this) {
      case TafsirSource.ibnKathir:
        return 'ابن كثير';
      case TafsirSource.saadi:
        return 'السعدي';
      case TafsirSource.muyassar:
        return 'الميسر';
    }
  }

  String get shortName {
    switch (this) {
      case TafsirSource.ibnKathir:
        return 'ابن كثير';
      case TafsirSource.saadi:
        return 'السعدي';
      case TafsirSource.muyassar:
        return 'الميسر';
    }
  }
}

/// Tafsir data model
class TafsirData {
  final int ayahId; // Global unique ayah number (1-6236)
  final int surah;
  final int ayah;
  final TafsirSource source;
  final String text;
  final String language;

  const TafsirData({
    required this.ayahId,
    required this.surah,
    required this.ayah,
    required this.source,
    required this.text,
    this.language = 'ar',
  });

  /// Create from database row
  factory TafsirData.fromMap(Map<String, dynamic> map) {
    return TafsirData(
      ayahId: map['ayah_id'] as int,
      surah: map['surah'] as int,
      ayah: map['ayah'] as int,
      source: TafsirSource.values.firstWhere(
        (s) => s.id == map['source'],
        orElse: () => TafsirSource.ibnKathir,
      ),
      text: map['text'] as String,
      language: map['language'] as String? ?? 'ar',
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'ayah_id': ayahId,
      'surah': surah,
      'ayah': ayah,
      'source': source.id,
      'text': text,
      'language': language,
    };
  }

  /// Create empty placeholder
  factory TafsirData.empty({
    required int ayahId,
    required int surah,
    required int ayah,
    required TafsirSource source,
  }) {
    return TafsirData(
      ayahId: ayahId,
      surah: surah,
      ayah: ayah,
      source: source,
      text: '',
    );
  }

  bool get isEmpty => text.isEmpty;
  bool get isNotEmpty => text.isNotEmpty;
}
