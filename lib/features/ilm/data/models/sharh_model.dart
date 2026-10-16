class Sharh {
  final String title;
  final String file;
  final String scholar;
  final int? shamelaId;
  final int? totalPages;
  final String? description;

  Sharh({
    required this.title,
    required this.file,
    required this.scholar,
    this.shamelaId,
    this.totalPages,
    this.description,
  });

  factory Sharh.fromJson(Map<String, dynamic> json) {
    return Sharh(
      title: json['title'] as String? ?? '',
      file: json['file'] as String? ?? '',
      scholar: json['scholar'] as String? ?? '',
      shamelaId: json['shamela_id'] as int?,
      totalPages: json['total_pages'] as int?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'file': file,
      'scholar': scholar,
      if (shamelaId != null) 'shamela_id': shamelaId,
      if (totalPages != null) 'total_pages': totalPages,
      if (description != null) 'description': description,
    };
  }
}
