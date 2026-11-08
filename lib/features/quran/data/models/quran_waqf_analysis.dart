/// Models representing the classical judgments of the 5 Imams of Waqf
/// (أئمة الوقف الخمسة):
/// 1. أبو عمرو الداني (ت 444هـ) - المكتفى في الوقف والابتدا
/// 2. السجاوندي (ت 560هـ) - علل الوقوف
/// 3. زكريا الأنصاري (ت 926هـ) - المقصد لتلخيص ما في المرشد
/// 4. الهبطي (ت 930هـ) - تقييد وقف القرآن
/// 5. الأشموني (ت 1100هـ) - منار الهدى في بيان الوقف والابتدا
library;

/// Represents one of the 5 classical scholars of Quranic stops.
class WaqfScholar {
  final String id;
  final String shortName;
  final String bookTitle;
  final int deathYear;

  const WaqfScholar({
    required this.id,
    required this.shortName,
    required this.bookTitle,
    required this.deathYear,
  });

  factory WaqfScholar.fromJson(Map<String, dynamic> json) {
    return WaqfScholar(
      id: json['id'] as String? ?? '',
      shortName: json['short'] as String? ?? '',
      bookTitle: json['title'] as String? ?? '',
      deathYear: json['death'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'short': shortName,
    'title': bookTitle,
    'death': deathYear,
  };
}

/// A specific judgment on stopping at a word by a classical scholar.
class WaqfJudgment {
  final String scholarId;
  final String type; // e.g. "w"
  final String label; // e.g. "تام", "حسن", "لا يوقف", "صه"
  final String longLabel;
  final String grade; // "tam", "kafi", "hasan", "salih", "jaiz", "lazim", "neg", "habti"
  final String explanation; // علة الوقف النحوية والبلاغية
  final String note;
  final String page; // مرجع الصفحة في الكتاب

  const WaqfJudgment({
    required this.scholarId,
    required this.type,
    required this.label,
    required this.longLabel,
    required this.grade,
    required this.explanation,
    required this.note,
    required this.page,
  });

  bool get isTam => grade == 'tam';
  bool get isKafi => grade == 'kafi';
  bool get isHasan => grade == 'hasan';
  bool get isJaiz => grade == 'jaiz' || grade == 'salih';
  bool get isLazim => grade == 'lazim';
  bool get isNegative => grade == 'neg';
  bool get isHabti => grade == 'habti';

  factory WaqfJudgment.fromWahyList(List<dynamic> list) {
    return WaqfJudgment(
      scholarId: list.isNotEmpty ? list[0]?.toString() ?? '' : '',
      type: list.length > 1 ? list[1]?.toString() ?? '' : '',
      label: list.length > 2 ? list[2]?.toString() ?? '' : '',
      longLabel: list.length > 3 ? list[3]?.toString() ?? '' : '',
      grade: list.length > 4 ? list[4]?.toString() ?? '' : '',
      explanation: list.length > 5 ? list[5]?.toString() ?? '' : '',
      note: list.length > 6 ? list[6]?.toString() ?? '' : '',
      page: list.length > 7 ? list[7]?.toString() ?? '' : '',
    );
  }

  factory WaqfJudgment.fromJson(Map<String, dynamic> json) {
    return WaqfJudgment(
      scholarId: json['s'] as String? ?? '',
      type: json['t'] as String? ?? '',
      label: json['l'] as String? ?? '',
      longLabel: json['ll'] as String? ?? '',
      grade: json['g'] as String? ?? '',
      explanation: json['e'] as String? ?? '',
      note: json['n'] as String? ?? '',
      page: json['p'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    's': scholarId,
    't': type,
    'l': label,
    'll': longLabel,
    'g': grade,
    'e': explanation,
    'n': note,
    'p': page,
  };
}

/// A word within the verse that has associated Waqf judgments.
class WaqfWord {
  final int wordIndex; // 1-based index in the ayah
  final String word;
  final List<WaqfJudgment> judgments;

  const WaqfWord({
    required this.wordIndex,
    required this.word,
    required this.judgments,
  });

  bool hasScholar(String scholarId) =>
      judgments.any((j) => j.scholarId == scholarId);

  WaqfJudgment? getScholarJudgment(String scholarId) {
    for (final j in judgments) {
      if (j.scholarId == scholarId) return j;
    }
    return null;
  }

  factory WaqfWord.fromJson(Map<String, dynamic> json) {
    final judgmentsList = (json['j'] as List<dynamic>? ?? const [])
        .map((e) => WaqfJudgment.fromJson(e as Map<String, dynamic>))
        .toList();

    return WaqfWord(
      wordIndex: json['idx'] as int? ?? 1,
      word: json['w'] as String? ?? '',
      judgments: judgmentsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'idx': wordIndex,
    'w': word,
    'j': judgments.map((j) => j.toJson()).toList(),
  };
}

/// Complete Waqf analysis for an Ayah across all classical scholars.
class AyahWaqfAnalysis {
  final int surah;
  final int ayah;
  final String verseText;
  final int firstGlobalWordId;
  final List<WaqfScholar> scholars;
  final List<WaqfWord> words;

  const AyahWaqfAnalysis({
    required this.surah,
    required this.ayah,
    required this.verseText,
    required this.firstGlobalWordId,
    required this.scholars,
    required this.words,
  });

  bool get isEmpty => words.isEmpty;

  factory AyahWaqfAnalysis.fromJson(Map<String, dynamic> json) {
    final scholarsList = (json['scholars'] as List<dynamic>? ?? const [])
        .map((s) => WaqfScholar.fromJson(s as Map<String, dynamic>))
        .toList();

    final wordsList = (json['words'] as List<dynamic>? ?? const [])
        .map((w) => WaqfWord.fromJson(w as Map<String, dynamic>))
        .toList();

    return AyahWaqfAnalysis(
      surah: json['surah'] as int? ?? 1,
      ayah: json['ayah'] as int? ?? 1,
      verseText: json['text'] as String? ?? '',
      firstGlobalWordId: json['first'] as int? ?? 1,
      scholars: scholarsList,
      words: wordsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'surah': surah,
    'ayah': ayah,
    'text': verseText,
    'first': firstGlobalWordId,
    'scholars': scholars.map((s) => s.toJson()).toList(),
    'words': words.map((w) => w.toJson()).toList(),
  };
}

