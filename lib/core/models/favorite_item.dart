enum FavoriteType { hadith, dhikr, dua, lesson, book, quran, quote }

extension FavoriteTypeX on FavoriteType {
  String get id => name;

  static FavoriteType? fromId(String id) {
    for (final value in FavoriteType.values) {
      if (value.name == id) return value;
    }
    return null;
  }
}

class FavoriteItem {
  final FavoriteType type;
  final String id;
  final String title;
  final String subtitle;

  const FavoriteItem({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
  });

  Map<String, dynamic> toJson() {
    return {'type': type.id, 'id': id, 'title': title, 'subtitle': subtitle};
  }

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    final type =
        FavoriteTypeX.fromId(json['type']?.toString() ?? '') ??
        FavoriteType.hadith;
    return FavoriteItem(
      type: type,
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
    );
  }
}
