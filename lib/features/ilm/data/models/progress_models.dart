enum BookProgressStatus {
  notStarted,
  inProgress,
  completed,
}

class BookProgress {
  final String bookId;
  final BookProgressStatus status;
  final int completedLessons;
  final int totalLessons;

  BookProgress({
    required this.bookId,
    required this.status,
    required this.completedLessons,
    required this.totalLessons,
  });

  double get percent =>
      totalLessons == 0 ? 0 : completedLessons / totalLessons * 100;

  bool get isCompleted => completedLessons >= totalLessons;

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'status': status.name,
        'completedLessons': completedLessons,
        'totalLessons': totalLessons,
      };

  factory BookProgress.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    final status = rawStatus is String
        ? BookProgressStatus.values.firstWhere(
            (value) => value.name == rawStatus,
            orElse: () => BookProgressStatus.notStarted,
          )
        : BookProgressStatus.notStarted;
    final rawCompleted = json['completedLessons'];
    final rawTotal = json['totalLessons'];

    return BookProgress(
      bookId: json['bookId']?.toString() ?? '',
      status: status,
      completedLessons:
          rawCompleted is int ? rawCompleted : int.tryParse('$rawCompleted') ?? 0,
      totalLessons:
          rawTotal is int ? rawTotal : int.tryParse('$rawTotal') ?? 0,
    );
  }
}
