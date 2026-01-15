class BookProgress {
  final String bookId;
  final String bookTitle;
  final String level;
  final int totalPages;
  final int currentPage;
  final DateTime lastReadDate;
  final List<int> bookmarkedPages;
  final Map<int, String> notes;
  final int totalReadingTimeMinutes;
  final bool isFavorite;
  final DateTime startedDate;
  final DateTime? completedDate;

  const BookProgress({
    required this.bookId,
    required this.bookTitle,
    required this.level,
    required this.totalPages,
    this.currentPage = 1,
    required this.lastReadDate,
    this.bookmarkedPages = const [],
    this.notes = const {},
    this.totalReadingTimeMinutes = 0,
    this.isFavorite = false,
    required this.startedDate,
    this.completedDate,
  });

  double get progressPercentage =>
      totalPages > 0 ? (currentPage / totalPages) * 100 : 0;

  bool get isCompleted => currentPage >= totalPages;

  int get daysSinceLastRead {
    final now = DateTime.now();
    final difference = now.difference(lastReadDate);
    return difference.inDays;
  }

  bool get readToday {
    final now = DateTime.now();
    return lastReadDate.year == now.year &&
        lastReadDate.month == now.month &&
        lastReadDate.day == now.day;
  }

  BookProgress copyWith({
    int? currentPage,
    DateTime? lastReadDate,
    List<int>? bookmarkedPages,
    Map<int, String>? notes,
    int? totalReadingTimeMinutes,
    bool? isFavorite,
    DateTime? completedDate,
  }) {
    return BookProgress(
      bookId: bookId,
      bookTitle: bookTitle,
      level: level,
      totalPages: totalPages,
      currentPage: currentPage ?? this.currentPage,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      bookmarkedPages: bookmarkedPages ?? this.bookmarkedPages,
      notes: notes ?? this.notes,
      totalReadingTimeMinutes:
          totalReadingTimeMinutes ?? this.totalReadingTimeMinutes,
      isFavorite: isFavorite ?? this.isFavorite,
      startedDate: startedDate,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  factory BookProgress.fromJson(Map<String, dynamic> json) {
    final bookmarked = (json['bookmarkedPages'] as List<dynamic>? ?? [])
        .map((page) => page is int ? page : int.tryParse('$page') ?? 0)
        .where((page) => page > 0)
        .toList();
    final notesRaw = json['notes'] as Map<String, dynamic>? ?? {};
    final notes = <int, String>{
      for (final entry in notesRaw.entries)
        int.tryParse(entry.key) ?? 0: entry.value?.toString() ?? '',
    }..removeWhere((key, value) => key == 0 || value.isEmpty);

    return BookProgress(
      bookId: json['bookId'] as String? ?? '',
      bookTitle: json['bookTitle'] as String? ?? '',
      level: json['level'] as String? ?? '',
      totalPages: json['totalPages'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 1,
      lastReadDate:
          DateTime.tryParse(json['lastReadDate'] as String? ?? '') ??
          DateTime.now(),
      bookmarkedPages: bookmarked,
      notes: notes,
      totalReadingTimeMinutes: json['totalReadingTimeMinutes'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      startedDate:
          DateTime.tryParse(json['startedDate'] as String? ?? '') ??
          DateTime.now(),
      completedDate: DateTime.tryParse(json['completedDate'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'bookTitle': bookTitle,
      'level': level,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'lastReadDate': lastReadDate.toIso8601String(),
      'bookmarkedPages': bookmarkedPages,
      'notes': {
        for (final entry in notes.entries) entry.key.toString(): entry.value,
      },
      'totalReadingTimeMinutes': totalReadingTimeMinutes,
      'isFavorite': isFavorite,
      'startedDate': startedDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
    };
  }
}
