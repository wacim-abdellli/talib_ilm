// Quran Data Models
// Models for Surah, Ayah, and metadata

// ═══════════════════════════════════════════════════════════════════════════
// SURAH METADATA (Light version for lists)
// ═══════════════════════════════════════════════════════════════════════════

class SurahMeta {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  const SurahMeta({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory SurahMeta.fromJson(Map<String, dynamic> json) {
    return SurahMeta(
      number: json['number'] as int,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      englishNameTranslation: json['englishNameTranslation'] as String? ?? '',
      numberOfAyahs: json['numberOfAyahs'] as int,
      revelationType: json['revelationType'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'name': name,
    'englishName': englishName,
    'englishNameTranslation': englishNameTranslation,
    'numberOfAyahs': numberOfAyahs,
    'revelationType': revelationType,
  };

  bool get isMakki => revelationType == 'Meccan';
  bool get isMadani => revelationType == 'Medinan';

  String get revelationTypeArabic => isMakki ? 'مكية' : 'مدنية';

  static const Map<int, int> surahStartPage = {
    1: 1,
    2: 2,
    3: 50,
    4: 77,
    5: 106,
    6: 128,
    7: 151,
    8: 177,
    9: 187,
    10: 208,
    11: 221,
    12: 235,
    13: 249,
    14: 255,
    15: 262,
    16: 267,
    17: 282,
    18: 293,
    19: 305,
    20: 312,
    21: 322,
    22: 332,
    23: 342,
    24: 350,
    25: 359,
    26: 367,
    27: 377,
    28: 385,
    29: 396,
    30: 404,
    31: 411,
    32: 415,
    33: 418,
    34: 428,
    35: 434,
    36: 440,
    37: 446,
    38: 453,
    39: 458,
    40: 467,
    41: 477,
    42: 483,
    43: 489,
    44: 496,
    45: 499,
    46: 502,
    47: 507,
    48: 511,
    49: 515,
    50: 518,
    51: 520,
    52: 523,
    53: 526,
    54: 528,
    55: 531,
    56: 534,
    57: 537,
    58: 542,
    59: 545,
    60: 549,
    61: 551,
    62: 553,
    63: 554,
    64: 556,
    65: 558,
    66: 560,
    67: 562,
    68: 564,
    69: 566,
    70: 568,
    71: 570,
    72: 572,
    73: 574,
    74: 575,
    75: 577,
    76: 578,
    77: 580,
    78: 582,
    79: 583,
    80: 585,
    81: 586,
    82: 587,
    83: 587,
    84: 589,
    85: 590,
    86: 591,
    87: 591,
    88: 592,
    89: 593,
    90: 594,
    91: 595,
    92: 595,
    93: 596,
    94: 596,
    95: 597,
    96: 597,
    97: 598,
    98: 598,
    99: 599,
    100: 599,
    101: 600,
    102: 600,
    103: 601,
    104: 601,
    105: 601,
    106: 602,
    107: 602,
    108: 602,
    109: 603,
    110: 603,
    111: 603,
    112: 604,
    113: 604,
    114: 604,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// AYAH (Single Verse)
// ═══════════════════════════════════════════════════════════════════════════

class Ayah {
  final int number; // Global number (1-6236)
  final String text; // Arabic text
  final int numberInSurah; // Verse number in surah
  final int juz; // Juz number (1-30)
  final int page; // Page in Mushaf (1-604)
  final int? hizbQuarter; // Hizb quarter
  final bool sajda; // Has sajda
  final String? translation; // Optional translation
  final String? audioUrl; // Optional audio URL
  final int? surahNumber; // Optional (available in page endpoint)
  final String? surahName; // Optional (available in page endpoint)

  const Ayah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    required this.page,
    this.hizbQuarter,
    this.sajda = false,
    this.translation,
    this.audioUrl,
    this.surahNumber,
    this.surahName,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    int? sNum;
    String? sName;
    if (json['surah'] != null) {
      if (json['surah'] is Map) {
        sNum = json['surah']['number'];
        sName = json['surah']['name'];
      }
    }

    return Ayah(
      number: json['number'] as int,
      text: json['text'] as String,
      numberInSurah: json['numberInSurah'] as int,
      juz: json['juz'] as int,
      page: json['page'] as int,
      hizbQuarter: json['hizbQuarter'] as int?,
      sajda: json['sajda'] == true || (json['sajda'] is Map),
      translation: json['translation'] as String?,
      audioUrl: json['audio'] as String?,
      surahNumber: sNum,
      surahName: sName,
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'text': text,
    'numberInSurah': numberInSurah,
    'juz': juz,
    'page': page,
    'hizbQuarter': hizbQuarter,
    'sajda': sajda,
    'translation': translation,
    'audio': audioUrl,
    'surahNumber': surahNumber,
    'surahName': surahName,
  };

  /// Copy with translation
  Ayah withTranslation(String translation) {
    return Ayah(
      number: number,
      text: text,
      numberInSurah: numberInSurah,
      juz: juz,
      page: page,
      hizbQuarter: hizbQuarter,
      sajda: sajda,
      translation: translation,
      audioUrl: audioUrl,
    );
  }

  /// Copy with audio URL
  Ayah withAudio(String url) {
    return Ayah(
      number: number,
      text: text,
      numberInSurah: numberInSurah,
      juz: juz,
      page: page,
      hizbQuarter: hizbQuarter,
      sajda: sajda,
      translation: translation,
      audioUrl: url,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SURAH (Full with Ayahs)
// ═══════════════════════════════════════════════════════════════════════════

class Surah {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;
  final List<Ayah> ayahs;

  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
    required this.ayahs,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    final List<dynamic> ayahsJson = json['ayahs'] ?? [];
    return Surah(
      number: json['number'] as int,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      englishNameTranslation: json['englishNameTranslation'] as String? ?? '',
      numberOfAyahs: json['numberOfAyahs'] as int,
      revelationType: json['revelationType'] as String,
      ayahs: ayahsJson
          .map((a) => Ayah.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'name': name,
    'englishName': englishName,
    'englishNameTranslation': englishNameTranslation,
    'numberOfAyahs': numberOfAyahs,
    'revelationType': revelationType,
    'ayahs': ayahs.map((a) => a.toJson()).toList(),
  };

  bool get isMakki => revelationType == 'Meccan';
  bool get isMadani => revelationType == 'Medinan';

  /// Get surah metadata only
  SurahMeta get meta => SurahMeta(
    number: number,
    name: name,
    englishName: englishName,
    englishNameTranslation: englishNameTranslation,
    numberOfAyahs: numberOfAyahs,
    revelationType: revelationType,
  );

  /// Merge translations into ayahs
  Surah withTranslations(List<Ayah> translationAyahs) {
    final mergedAyahs = <Ayah>[];
    for (int i = 0; i < ayahs.length; i++) {
      final translation = i < translationAyahs.length
          ? translationAyahs[i].text
          : null;
      mergedAyahs.add(ayahs[i].withTranslation(translation ?? ''));
    }
    return Surah(
      number: number,
      name: name,
      englishName: englishName,
      englishNameTranslation: englishNameTranslation,
      numberOfAyahs: numberOfAyahs,
      revelationType: revelationType,
      ayahs: mergedAyahs,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// JUZ
// ═══════════════════════════════════════════════════════════════════════════

class Juz {
  final int number;
  final List<Ayah> ayahs;

  const Juz({required this.number, required this.ayahs});

  factory Juz.fromJson(Map<String, dynamic> json) {
    final List<dynamic> ayahsJson = json['ayahs'] ?? [];
    return Juz(
      number: json['number'] as int,
      ayahs: ayahsJson
          .map((a) => Ayah.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'ayahs': ayahs.map((a) => a.toJson()).toList(),
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// SEARCH RESULT
// ═══════════════════════════════════════════════════════════════════════════

class QuranSearchResult {
  final int ayahNumber;
  final String text;
  final int numberInSurah;
  final int surahNumber;
  final String surahName;
  final String surahEnglishName;

  const QuranSearchResult({
    required this.ayahNumber,
    required this.text,
    required this.numberInSurah,
    required this.surahNumber,
    required this.surahName,
    required this.surahEnglishName,
  });

  factory QuranSearchResult.fromJson(Map<String, dynamic> json) {
    return QuranSearchResult(
      ayahNumber: json['number'] as int,
      text: json['text'] as String,
      numberInSurah: json['numberInSurah'] as int,
      surahNumber: json['surah']['number'] as int,
      surahName: json['surah']['name'] as String,
      surahEnglishName: json['surah']['englishName'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'number': ayahNumber,
    'text': text,
    'numberInSurah': numberInSurah,
    'surah': {
      'number': surahNumber,
      'name': surahName,
      'englishName': surahEnglishName,
    },
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// BOOKMARK
// ═══════════════════════════════════════════════════════════════════════════

class QuranBookmark {
  final String id;
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final String ayahText;
  final String? note;
  final DateTime createdAt;

  const QuranBookmark({
    required this.id,
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.ayahText,
    this.note,
    required this.createdAt,
  });

  factory QuranBookmark.fromJson(Map<String, dynamic> json) {
    return QuranBookmark(
      id: json['id'] as String,
      surahNumber: json['surahNumber'] as int,
      surahName: json['surahName'] as String,
      ayahNumber: json['ayahNumber'] as int,
      ayahText: json['ayahText'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'surahNumber': surahNumber,
    'surahName': surahName,
    'ayahNumber': ayahNumber,
    'ayahText': ayahText,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  static String generateId(int surahNumber, int ayahNumber) {
    return '${surahNumber}_$ayahNumber';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// READING PROGRESS
// ═══════════════════════════════════════════════════════════════════════════

class ReadingProgress {
  final int lastSurah;
  final int lastAyah;
  final int lastPage;
  final int lastJuz;
  final DateTime timestamp;

  const ReadingProgress({
    required this.lastSurah,
    required this.lastAyah,
    required this.lastPage,
    required this.lastJuz,
    required this.timestamp,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      lastSurah: json['lastSurah'] as int,
      lastAyah: json['lastAyah'] as int,
      lastPage: json['lastPage'] as int,
      lastJuz: json['lastJuz'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'lastSurah': lastSurah,
    'lastAyah': lastAyah,
    'lastPage': lastPage,
    'lastJuz': lastJuz,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ReadingProgress.initial() => ReadingProgress(
    lastSurah: 1,
    lastAyah: 1,
    lastPage: 1,
    lastJuz: 1,
    timestamp: DateTime.now(),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// RECITER
// ═══════════════════════════════════════════════════════════════════════════

class Reciter {
  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String identifier;

  const Reciter({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.identifier,
  });

  static const List<Reciter> availableReciters = [
    Reciter(
      id: '1',
      nameArabic: 'مشاري العفاسي',
      nameEnglish: 'Mishary Alafasy',
      identifier: 'ar.alafasy',
    ),
    Reciter(
      id: '2',
      nameArabic: 'محمد المنشاوي',
      nameEnglish: 'Mohamed El-Minshawi',
      identifier: 'ar.minshawi',
    ),
    Reciter(
      id: '3',
      nameArabic: 'محمود الحصري',
      nameEnglish: 'Mahmoud Al-Husary',
      identifier: 'ar.husary',
    ),
    Reciter(
      id: '4',
      nameArabic: 'عبد الباسط',
      nameEnglish: 'Abdul Basit',
      identifier: 'ar.abdulbasit',
    ),
    Reciter(
      id: '5',
      nameArabic: 'ماهر المعيقلي',
      nameEnglish: 'Maher Al Muaiqly',
      identifier: 'ar.mahermuaiqly',
    ),
    Reciter(
      id: '6',
      nameArabic: 'عبد الرحمن السديس',
      nameEnglish: 'Abdul Rahman Al-Sudais',
      identifier: 'ar.abdurrahmaansudais',
    ),
  ];
}
// ═══════════════════════════════════════════════════════════════════════════
// QURAN EDITION (Riwaya/Type)
// ═══════════════════════════════════════════════════════════════════════════

class QuranEdition {
  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String identifier; // API identifier
  final String format; // text or audio
  final String type; // translation, quran, etc
  final String? fontName; // Required font for this edition

  const QuranEdition({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.identifier,
    required this.format,
    required this.type,
    this.fontName,
  });

  static const List<QuranEdition> availableEditions = [
    QuranEdition(
      id: 'hafs',
      nameArabic: 'حفص عن عاصم',
      nameEnglish: 'Hafs',
      identifier: 'quran-uthmani',
      format: 'text',
      type: 'quran',
      fontName: 'ScheherazadeNew', // Standard font
    ),
    QuranEdition(
      id: 'warsh',
      nameArabic: 'ورش عن نافع',
      nameEnglish: 'Warsh',
      identifier: 'quran-warsh',
      format: 'text',
      type: 'quran',
      fontName: 'Warsh', // Needs custom font bundle
    ),
    QuranEdition(
      id: 'tajweed',
      nameArabic: 'مصحف التجويد',
      nameEnglish: 'Tajweed',
      identifier: 'quran-tajweed',
      format: 'text',
      type: 'quran',
      fontName:
          'ScheherazadeNew', // Usually works with standard but colors matter
    ),
  ];
}
