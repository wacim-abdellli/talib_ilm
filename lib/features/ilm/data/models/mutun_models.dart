import 'sharh_model.dart';

class MutunProgram {
  final List<IlmLevel> levels;

  MutunProgram({required this.levels});

  factory MutunProgram.fromJson(Map<String, dynamic> json) {
  final program = json['program'];
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
  final String description;
  final bool hidden;
  final List<IlmBook> books;

  IlmLevel({
    required this.id,
    required this.order,
    required this.title,
    required this.description,
    required this.hidden,
    required this.books,
  });

  factory IlmLevel.fromJson(Map<String, dynamic> json) {
    return IlmLevel(
      id: json['id'],
      order: json['order'],
      title: json['title'],
      description: json['description'],
      hidden: json['hidden'] ?? false,
      books: (json['books'] as List)
          .map((e) => IlmBook.fromJson(e))
          .toList(),
    );
  }
}
class IlmBook {
  final String id;
  final String title;
  final String author;
  final String? playlistId;
  final List<Sharh> shuruh;

  IlmBook({
    required this.id,
    required this.title,
    required this.author,
    required this.shuruh,
    this.playlistId,
  });

  factory IlmBook.fromJson(Map<String, dynamic> json) {
    final resources = json['resources'] as Map<String, dynamic>?;

    return IlmBook(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      playlistId: resources?['video_playlist'],
      shuruh: (resources?['shuruh'] as List<dynamic>? ?? [])
          .map((e) => Sharh.fromJson(e))
          .toList(),
    );
  }
}
