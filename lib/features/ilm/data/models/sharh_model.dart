class Sharh {
  final String title;
  final String file;
  final String scholar;

  Sharh({
    required this.title,
    required this.file,
    required this.scholar,
  });

  factory Sharh.fromJson(Map<String, dynamic> json) {
    return Sharh(
      title: json['title'],
      file: json['file'],
      scholar: json['scholar'],
    );
  }
}
