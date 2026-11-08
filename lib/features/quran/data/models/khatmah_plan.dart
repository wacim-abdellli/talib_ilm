/// A local Quran completion plan based on a continuous range of Hafs Mushaf pages.
class KhatmahPlan {
  final String id;
  final String title;
  final int startPage;
  final int pagesPerDay;
  final Set<int> completedPageNumbers;
  final DateTime createdAt;
  final DateTime? targetDate;
  final DateTime? pausedAt;
  final DateTime? completedAt;
  final bool isArchived;
  final Map<String, int> dailyProgress;

  const KhatmahPlan({
    required this.id,
    required this.title,
    required this.startPage,
    required this.pagesPerDay,
    this.completedPageNumbers = const {},
    required this.createdAt,
    this.targetDate,
    this.pausedAt,
    this.completedAt,
    this.isArchived = false,
    this.dailyProgress = const {},
  });

  static const int mushafPageCount = 604;

  int get totalPages => mushafPageCount - startPage + 1;

  int get completedPages => completedPageNumbers.length;

  int get remainingPages => (totalPages - completedPages).clamp(0, totalPages);

  double get progress => totalPages == 0 ? 0 : completedPages / totalPages;

  bool get isPaused => pausedAt != null;

  bool get isComplete => remainingPages == 0;

  int pagesPlannedFor(DateTime date) {
    if (isPaused || isArchived || isComplete) return 0;
    if (targetDate == null) return pagesPerDay.clamp(1, remainingPages);

    final today = _dateOnly(date);
    final target = _dateOnly(targetDate!);
    final daysRemaining = target.difference(today).inDays + 1;
    final effectiveDays = daysRemaining < 1 ? 1 : daysRemaining;
    final recalculatedDailyPages =
        (remainingPages + effectiveDays - 1) ~/ effectiveDays;
    return recalculatedDailyPages.clamp(1, remainingPages);
  }

  /// The earliest unread page in this plan's page range.
  int get nextPage {
    for (var page = startPage; page <= mushafPageCount; page++) {
      if (!completedPageNumbers.contains(page)) return page;
    }
    return mushafPageCount;
  }

  /// Returns the next [count] unread pages in reading order.
  List<int> nextUnreadPages(int count) {
    if (count <= 0 || isComplete) return const [];
    final pages = <int>[];
    for (
      var page = nextPage;
      page <= mushafPageCount && pages.length < count;
      page++
    ) {
      if (!completedPageNumbers.contains(page)) pages.add(page);
    }
    return pages;
  }

  bool includesPage(int page) => page >= startPage && page <= mushafPageCount;

  int pagesRecordedOn(DateTime date) => dailyProgress[_dateKey(date)] ?? 0;

  int pagesRemainingToday(DateTime date) =>
      (pagesPlannedFor(date) - pagesRecordedOn(date)).clamp(0, remainingPages);

  DateTime? estimatedFinishDate(DateTime from) {
    if (isComplete) return completedAt;
    if (targetDate != null) return targetDate;
    final days = (remainingPages + pagesPerDay - 1) ~/ pagesPerDay;
    return _dateOnly(from).add(Duration(days: days - 1));
  }

  KhatmahPlan copyWith({
    String? title,
    int? pagesPerDay,
    Set<int>? completedPageNumbers,
    DateTime? targetDate,
    bool clearTargetDate = false,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? isArchived,
    Map<String, int>? dailyProgress,
  }) {
    return KhatmahPlan(
      id: id,
      title: title ?? this.title,
      startPage: startPage,
      pagesPerDay: pagesPerDay ?? this.pagesPerDay,
      completedPageNumbers: completedPageNumbers ?? this.completedPageNumbers,
      createdAt: createdAt,
      targetDate: clearTargetDate ? null : targetDate ?? this.targetDate,
      pausedAt: clearPausedAt ? null : pausedAt ?? this.pausedAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      isArchived: isArchived ?? this.isArchived,
      dailyProgress: dailyProgress ?? this.dailyProgress,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'startPage': startPage,
    'pagesPerDay': pagesPerDay,
    'completedPageNumbers': completedPageNumbers.toList()..sort(),
    'createdAt': _dateKey(createdAt),
    'targetDate': targetDate == null ? null : _dateKey(targetDate!),
    'pausedAt': pausedAt == null ? null : _dateKey(pausedAt!),
    'completedAt': completedAt == null ? null : _dateKey(completedAt!),
    'isArchived': isArchived,
    'dailyProgress': dailyProgress,
  };

  factory KhatmahPlan.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final startPage = json['startPage'];
    final pagesPerDay = json['pagesPerDay'];
    final legacyCompletedPages = json['completedPages'];
    final createdAt = _parseDate(json['createdAt'], 'createdAt');

    if (id is! String || id.isEmpty || title is! String) {
      throw const FormatException('Invalid Khatmah identity');
    }
    if (startPage is! int ||
        startPage < 1 ||
        startPage > mushafPageCount ||
        pagesPerDay is! int ||
        pagesPerDay < 1 ||
        pagesPerDay > mushafPageCount ||
        (legacyCompletedPages != null && legacyCompletedPages is! int)) {
      throw const FormatException('Invalid Khatmah page progress');
    }

    final planTotalPages = mushafPageCount - startPage + 1;
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty || cleanTitle.length > 60) {
      throw const FormatException('Invalid Khatmah title');
    }

    final rawCompletedPages = json['completedPageNumbers'];
    final completedPageNumbers = <int>{};
    if (rawCompletedPages is List) {
      for (final rawPage in rawCompletedPages) {
        if (rawPage is! int ||
            rawPage < startPage ||
            rawPage > mushafPageCount) {
          throw const FormatException('Invalid completed Quran page');
        }
        completedPageNumbers.add(rawPage);
      }
    } else if (rawCompletedPages == null) {
      // Migrate the earlier count-only schema without losing saved progress.
      final count = legacyCompletedPages as int? ?? 0;
      if (count < 0 || count > planTotalPages) {
        throw const FormatException('Invalid Khatmah page progress');
      }
      for (var offset = 0; offset < count; offset++) {
        completedPageNumbers.add(startPage + offset);
      }
    } else {
      throw const FormatException('Invalid completed Quran pages');
    }

    final rawProgress = json['dailyProgress'];
    final dailyProgress = <String, int>{};
    if (rawProgress is Map) {
      for (final entry in rawProgress.entries) {
        final key = entry.key;
        final value = entry.value;
        final parsedDate = DateTime.tryParse(key.toString());
        if (parsedDate != null && value is int && value > 0) {
          dailyProgress[_dateKey(parsedDate)] = value;
        }
      }
    }

    final targetDate = _parseOptionalDate(json['targetDate'], 'targetDate');
    if (targetDate != null && targetDate.isBefore(createdAt)) {
      throw const FormatException('Target date precedes plan creation');
    }

    final rawArchived = json['isArchived'];
    if (rawArchived != null && rawArchived is! bool) {
      throw const FormatException('Invalid Khatmah archive state');
    }

    return KhatmahPlan(
      id: id,
      title: cleanTitle,
      startPage: startPage,
      pagesPerDay: pagesPerDay,
      completedPageNumbers: completedPageNumbers,
      createdAt: createdAt,
      targetDate: targetDate,
      pausedAt: _parseOptionalDate(json['pausedAt'], 'pausedAt'),
      completedAt: _parseOptionalDate(json['completedAt'], 'completedAt'),
      isArchived: rawArchived as bool? ?? false,
      dailyProgress: dailyProgress,
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime _parseDate(Object? raw, String field) {
  if (raw is! String) throw FormatException('Missing Khatmah $field');
  final date = DateTime.tryParse(raw);
  if (date == null) throw FormatException('Invalid Khatmah $field');
  return _dateOnly(date);
}

DateTime? _parseOptionalDate(Object? raw, String field) {
  if (raw == null) return null;
  return _parseDate(raw, field);
}
