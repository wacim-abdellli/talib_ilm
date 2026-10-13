class QuranRadioStation {
  final int id;
  final String name;
  final String rawName;
  final String url;
  final String category;

  const QuranRadioStation({
    required this.id,
    required this.name,
    required this.rawName,
    required this.url,
    required this.category,
  });

  factory QuranRadioStation.fromJson(Map<String, dynamic> json) {
    return QuranRadioStation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      rawName: json['rawName'] as String? ?? json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      category: json['category'] as String? ?? 'عام',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'rawName': rawName,
    'url': url,
    'category': category,
  };
}
