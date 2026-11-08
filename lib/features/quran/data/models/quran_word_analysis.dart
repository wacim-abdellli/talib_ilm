/// Detailed 4-tier linguistic and scholarly analysis for a Quranic word.
///
/// Inspired by the Wahy Islamic knowledge platform:
/// 1. [qiraat]: Qira'at variants and classical reciters' differences (وصلاً ووقفاً).
/// 2. [irab]: Classical syntax and syntactic role (الموقع الإعرابي والعلامة).
/// 3. [meaning]: Contextual semantic meaning and Quranic vocabulary explanation.
/// 4. [sarf]: Morphological derivation, measure/wazn, root, and morphophonemic rules.
class QuranWordAnalysis {
  final int globalWordId;
  final int wordIndexInAyah;
  final String word;
  final String qiraat;
  final String irab;
  final String meaning;
  final String sarf;

  const QuranWordAnalysis({
    required this.globalWordId,
    required this.wordIndexInAyah,
    required this.word,
    required this.qiraat,
    required this.irab,
    required this.meaning,
    required this.sarf,
  });

  bool get hasQiraat => qiraat.trim().isNotEmpty && !qiraat.contains('لا خلاف بين القراء في هذا الموضع.\n-عند الوصل-\nلا خلاف');
  bool get hasIrab => irab.trim().isNotEmpty;
  bool get hasMeaning => meaning.trim().isNotEmpty;
  bool get hasSarf => sarf.trim().isNotEmpty;

  factory QuranWordAnalysis.fromWahyList({
    required int globalWordId,
    required int wordIndexInAyah,
    required String word,
    required List<dynamic> list,
  }) {
    return QuranWordAnalysis(
      globalWordId: globalWordId,
      wordIndexInAyah: wordIndexInAyah,
      word: word,
      qiraat: list.isNotEmpty ? list[0]?.toString() ?? '' : '',
      irab: list.length > 1 ? list[1]?.toString() ?? '' : '',
      meaning: list.length > 2 ? list[2]?.toString() ?? '' : '',
      sarf: list.length > 3 ? list[3]?.toString() ?? '' : '',
    );
  }

  factory QuranWordAnalysis.fromJson(Map<String, dynamic> json) {
    return QuranWordAnalysis(
      globalWordId: json['id'] as int? ?? 0,
      wordIndexInAyah: json['idx'] as int? ?? 0,
      word: json['w'] as String? ?? '',
      qiraat: json['q'] as String? ?? '',
      irab: json['i'] as String? ?? '',
      meaning: json['m'] as String? ?? '',
      sarf: json['s'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': globalWordId,
    'idx': wordIndexInAyah,
    'w': word,
    'q': qiraat,
    'i': irab,
    'm': meaning,
    's': sarf,
  };
}

