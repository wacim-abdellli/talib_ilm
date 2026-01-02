class DailyMotivation {
  final String text;
  final String source;

  const DailyMotivation({
    required this.text,
    required this.source,
  });

  factory DailyMotivation.fromJson(Map<String, dynamic> json) {
    return DailyMotivation(
      text: json['text']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }
}
