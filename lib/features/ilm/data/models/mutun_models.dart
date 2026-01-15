import 'sharh_model.dart';

class MutunProgram {
  final List<IlmLevel> levels;

  MutunProgram({required this.levels});

  factory MutunProgram.fromJson(Map<String, dynamic> json) {
    final program = json['program'];

    if (program == null || program['levels'] == null) {
      throw Exception('Invalid mutun_program.json structure');
    }

    return MutunProgram(
      levels: (program['levels'] as List)
          .map((e) => IlmLevel.fromJson(e))
          .toList(),
    );
  }
}

class IlmLevel {
  final String id;
  final int order;
  final String title;
  final String label;
  final String description;
  final String goal;
  final String duration;
  final List<String> focus;
  final bool hidden;
  final List<IlmBook> books;

  IlmLevel({
    required this.id,
    required this.order,
    required this.title,
    required this.label,
    required this.description,
    required this.goal,
    required this.duration,
    required this.focus,
    required this.hidden,
    required this.books,
  });

  factory IlmLevel.fromJson(Map<String, dynamic> json) {
    return IlmLevel(
      id: json['id'],
      order: json['order'],
      title: json['title'],
      label: json['label'] ?? json['title'],
      description: json['description'] ?? '',
      goal: json['goal'] ?? '',
      duration: json['duration'] ?? '',
      focus: (json['focus'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      hidden: json['hidden'] ?? false,
      books: (json['books'] as List<dynamic>? ?? [])
          .map((e) => IlmBook.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class IlmBook {
  final String id;
  final String title;
  final String author;
  final String level;
  final String subject;
  final String description;
  final int totalPages;
  final String? pdfPath;
  final String? playlistId;
  final List<Sharh> shuruh;

  IlmBook({
    required this.id,
    required this.title,
    required this.author,
    required this.level,
    required this.subject,
    required this.description,
    required this.totalPages,
    this.pdfPath,
    required this.shuruh,
    this.playlistId,
  });

  factory IlmBook.fromJson(Map<String, dynamic> json) {
    final resources = json['resources'] as Map<String, dynamic>?;

    return IlmBook(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      level: json['level'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      totalPages: json['totalPages'] ?? json['total_pages'] ?? 0,
      pdfPath: json['pdf_path'] as String?,
      playlistId: resources?['video_playlist'] as String?,
      shuruh: (resources?['shuruh'] as List<dynamic>? ?? [])
          .map((e) => Sharh.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
