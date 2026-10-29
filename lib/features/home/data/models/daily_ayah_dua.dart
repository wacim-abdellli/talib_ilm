enum AyahDuaType {
  ayah,
  dua,
}

class DailyAyahDua {
  final String id;
  final AyahDuaType type;
  final String text;
  final String source;
  final String topic;

  const DailyAyahDua({
    required this.id,
    required this.type,
    required this.text,
    required this.source,
    required this.topic,
  });

  bool get isAyah => type == AyahDuaType.ayah;

  String get typeLabel => isAyah ? 'آية كريمة' : 'دعاء مأثور';

  String get formattedText => isAyah ? '﴿ $text ﴾' : '« $text »';

  String get shareableText => '$formattedText\n— $source';
}
