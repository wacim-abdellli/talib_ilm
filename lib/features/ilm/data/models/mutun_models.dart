class MutunProgram {
  final String id;
  final String title;
  final String version;
  final List<IlmLevel> levels;

  MutunProgram({
    required this.id,
    required this.title,
    required this.version,
    required this.levels,
  });

  factory MutunProgram.fromJson(Map<String, dynamic> json) {
    // The JSON root has a "program" key, but we might pass the "program" object directly
    // or we might need to handle the root.
    // Based on typical usage, let's assume we pass the object containing "id", "title" etc.
    // But wait, the json file has { "program": { ... } }.
    // If AssetService passes json['program'], then this is fine.

    return MutunProgram(
      id: json['id'] as String,
      title: json['title'] as String,
      version: json['version'] as String,
      levels: (json['levels'] as List<dynamic>)
          .map((e) => IlmLevel.fromJson(e as Map<String, dynamic>))
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
    this.hidden = false,
    required this.books,
  });

  factory IlmLevel.fromJson(Map<String, dynamic> json) {
    return IlmLevel(
      id: json['id'] as String,
      order: json['order'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      hidden: json['hidden'] as bool? ?? false,
      books: (json['books'] as List<dynamic>)
          .map((e) => IlmBook.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class IlmBook {
  final String id;
  final String title;
  final String author;
  final BookResources resources;

  IlmBook({
    required this.id,
    required this.title,
    required this.author,
    required this.resources,
  });

  factory IlmBook.fromJson(Map<String, dynamic> json) {
    return IlmBook(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      resources: BookResources.fromJson(json['resources'] as Map<String, dynamic>),
    );
  }
}

class BookResources {
  final String? textPdf;
  final String? sharhPdf;
  final String? videoPlaylist;

  BookResources({
    this.textPdf,
    this.sharhPdf,
    this.videoPlaylist,
  });

  factory BookResources.fromJson(Map<String, dynamic> json) {
    return BookResources(
      textPdf: json['text_pdf'] as String?,
      sharhPdf: json['sharh_pdf'] as String?,
      videoPlaylist: json['video_playlist'] as String?,
    );
  }
}
