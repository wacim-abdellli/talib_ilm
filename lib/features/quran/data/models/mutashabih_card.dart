/// Model representing a single occurrence of a similar verse in the Quran.
class MutashabihPlace {
  final int surah;
  final int ayah;
  final int fromWord;
  final int toWord;
  final String text;

  const MutashabihPlace({
    required this.surah,
    required this.ayah,
    required this.fromWord,
    required this.toWord,
    required this.text,
  });

  factory MutashabihPlace.fromJson(Map<String, dynamic> json) {
    return MutashabihPlace(
      surah: (json['s'] as num?)?.toInt() ?? 1,
      ayah: (json['a'] as num?)?.toInt() ?? 1,
      fromWord: (json['f'] as num?)?.toInt() ?? 0,
      toWord: (json['t'] as num?)?.toInt() ?? 0,
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        's': surah,
        'a': ayah,
        'f': fromWord,
        't': toWord,
        'text': text,
      };
}

/// Model representing a thematic or phrase similarity card across the Quran,
/// with scholarly mnemonics (الضابط الحفظي), rhetorical reasons (التوجيه البلاغي),
/// and classical reference citations (المرجع).
class MutashabihCard {
  final int id;
  final List<MutashabihPlace> places;
  final String? rule; // الضابط الحفظي (d)
  final String? rhetoric; // التوجيه البلاغي لسر اختلاف اللفظ (w)
  final String? source; // المرجع والمصدر العلمي (r)

  const MutashabihCard({
    required this.id,
    required this.places,
    this.rule,
    this.rhetoric,
    this.source,
  });

  factory MutashabihCard.fromJson(Map<String, dynamic> json) {
    final placesList = (json['places'] as List<dynamic>?)
            ?.map((p) => MutashabihPlace.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];
    return MutashabihCard(
      id: (json['id'] as num?)?.toInt() ?? 0,
      places: placesList,
      rule: json['d'] as String?,
      rhetoric: json['w'] as String?,
      source: json['r'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'places': places.map((p) => p.toJson()).toList(),
        if (rule != null) 'd': rule,
        if (rhetoric != null) 'w': rhetoric,
        if (source != null) 'r': source,
      };
}

