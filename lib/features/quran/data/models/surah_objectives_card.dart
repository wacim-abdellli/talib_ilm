/// Data models representing the authentic scholarly objectives, themes,
/// naming reasons, and virtues of Quranic Surahs (مقاصد السور ومحاورها).
library;

/// A thematic division of verses within a Surah.
class SurahThematicSection {
  final String title;
  final int startAyah;
  final int endAyah;
  final String description;

  const SurahThematicSection({
    required this.title,
    required this.startAyah,
    required this.endAyah,
    required this.description,
  });

  factory SurahThematicSection.fromJson(Map<String, dynamic> json) {
    return SurahThematicSection(
      title: json['title'] as String? ?? '',
      startAyah: json['start'] as int? ?? 1,
      endAyah: json['end'] as int? ?? 1,
      description: json['desc'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'start': startAyah,
    'end': endAyah,
    'desc': description,
  };
}

/// Comprehensive card containing all classical and scholarly metadata
/// for a Quranic Surah: objectives, themes, virtues, and naming rationale.
class SurahObjectivesCard {
  final int surahNumber;
  final String name;
  final String vocalizedName;
  final String englishName;
  final String englishMeaning;
  final String revelationPlace; // مكية / مدنية
  final int revelationOrder; // ترتيب النزول
  final int versesCount;
  final int startPage;
  final List<String> otherNames;
  final String mainObjective; // المقصد العام للسورة (مركز تفسير / المختصر)
  final String namingReason; // سبب التسمية
  final List<SurahThematicSection> thematicSections; // محاور السورة الكبرى
  final List<String> virtues; // فضائل السورة وخصائصها
  final String connectionWithPrevious; // مناسبة السورة لما قبلها

  const SurahObjectivesCard({
    required this.surahNumber,
    required this.name,
    required this.vocalizedName,
    required this.englishName,
    required this.englishMeaning,
    required this.revelationPlace,
    required this.revelationOrder,
    required this.versesCount,
    required this.startPage,
    required this.otherNames,
    required this.mainObjective,
    required this.namingReason,
    required this.thematicSections,
    required this.virtues,
    required this.connectionWithPrevious,
  });

  bool get isMakki => revelationPlace.contains('مك');

  factory SurahObjectivesCard.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as List<dynamic>? ?? const [];
    final sections = rawSections
        .map((e) => SurahThematicSection.fromJson(e as Map<String, dynamic>))
        .toList();

    final rawNames = json['otherNames'] as List<dynamic>? ?? const [];
    final otherNames = rawNames.map((e) => e.toString()).toList();

    final rawVirtues = json['virtues'] as List<dynamic>? ?? const [];
    final virtues = rawVirtues.map((e) => e.toString()).toList();

    return SurahObjectivesCard(
      surahNumber: json['number'] as int? ?? 1,
      name: json['name'] as String? ?? '',
      vocalizedName: json['vocalized'] as String? ?? '',
      englishName: json['en'] as String? ?? '',
      englishMeaning: json['enMeaning'] as String? ?? '',
      revelationPlace: json['place'] as String? ?? 'مكية',
      revelationOrder: json['order'] as int? ?? 1,
      versesCount: json['verses'] as int? ?? 7,
      startPage: json['page'] as int? ?? 1,
      otherNames: otherNames,
      mainObjective: json['objective'] as String? ?? '',
      namingReason: json['naming'] as String? ?? '',
      thematicSections: sections,
      virtues: virtues,
      connectionWithPrevious: json['connection'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'number': surahNumber,
    'name': name,
    'vocalized': vocalizedName,
    'en': englishName,
    'enMeaning': englishMeaning,
    'place': revelationPlace,
    'order': revelationOrder,
    'verses': versesCount,
    'page': startPage,
    'otherNames': otherNames,
    'objective': mainObjective,
    'naming': namingReason,
    'sections': thematicSections.map((s) => s.toJson()).toList(),
    'virtues': virtues,
    'connection': connectionWithPrevious,
  };
}

