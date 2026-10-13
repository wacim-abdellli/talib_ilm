class ShamelaBook {
  final int id;
  final String title;
  final String author;
  final String? authorDeath;
  final String category;
  final int categoryId;
  final String? muhaqqiq;
  final String? publisher;
  final String? edition;
  final int volumes;
  final int totalPages;
  final String description;
  final bool isDownloaded;

  const ShamelaBook({
    required this.id,
    required this.title,
    required this.author,
    this.authorDeath,
    required this.category,
    required this.categoryId,
    this.muhaqqiq,
    this.publisher,
    this.edition,
    this.volumes = 1,
    required this.totalPages,
    this.description = '',
    this.isDownloaded = false,
  });

  factory ShamelaBook.fromJson(Map<String, dynamic> json) {
    return ShamelaBook(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      authorDeath: json['authorDeath'] as String?,
      category: json['category'] as String? ?? 'عام',
      categoryId: json['categoryId'] as int? ?? 0,
      muhaqqiq: json['muhaqqiq'] as String?,
      publisher: json['publisher'] as String?,
      edition: json['edition'] as String?,
      volumes: json['volumes'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
      description: json['description'] as String? ?? '',
      isDownloaded: json['isDownloaded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'authorDeath': authorDeath,
        'category': category,
        'categoryId': categoryId,
        'muhaqqiq': muhaqqiq,
        'publisher': publisher,
        'edition': edition,
        'volumes': volumes,
        'totalPages': totalPages,
        'description': description,
        'isDownloaded': isDownloaded,
      };

  ShamelaBook copyWith({
    bool? isDownloaded,
    int? totalPages,
    String? description,
  }) {
    return ShamelaBook(
      id: id,
      title: title,
      author: author,
      authorDeath: authorDeath,
      category: category,
      categoryId: categoryId,
      muhaqqiq: muhaqqiq,
      publisher: publisher,
      edition: edition,
      volumes: volumes,
      totalPages: totalPages ?? this.totalPages,
      description: description ?? this.description,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}

class ShamelaChapter {
  final String title;
  final int pageNumber;

  const ShamelaChapter({
    required this.title,
    required this.pageNumber,
  });

  factory ShamelaChapter.fromJson(Map<String, dynamic> json) {
    return ShamelaChapter(
      title: json['title'] as String? ?? '',
      pageNumber: json['pageNumber'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'pageNumber': pageNumber,
      };
}

class ShamelaPage {
  final int bookId;
  final int pageNumber;
  final int? partNumber;
  final String? chapterTitle;
  final String content;
  final String? hamesh;

  const ShamelaPage({
    required this.bookId,
    required this.pageNumber,
    this.partNumber,
    this.chapterTitle,
    required this.content,
    this.hamesh,
  });

  factory ShamelaPage.fromJson(Map<String, dynamic> json) {
    return ShamelaPage(
      bookId: json['bookId'] as int,
      pageNumber: json['pageNumber'] as int,
      partNumber: json['partNumber'] as int?,
      chapterTitle: json['chapterTitle'] as String?,
      content: json['content'] as String? ?? '',
      hamesh: json['hamesh'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'pageNumber': pageNumber,
        'partNumber': partNumber,
        'chapterTitle': chapterTitle,
        'content': content,
        'hamesh': hamesh,
      };
}

class ShamelaCategory {
  final int id;
  final String name;
  final int count;

  const ShamelaCategory({
    required this.id,
    required this.name,
    this.count = 0,
  });
}
