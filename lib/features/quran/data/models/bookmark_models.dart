import 'package:quran/quran.dart' as quran;

import '../../../../core/constants/app_policy.dart';

class Bookmark {
  final int surah;
  final int ayah;
  final int page;
  final String? note;
  final DateTime timestamp;
  final bool isSurah;

  const Bookmark({
    required this.surah,
    required this.ayah,
    required this.page,
    this.note,
    required this.timestamp,
    this.isSurah = false,
  });

  static bool isValidCoordinates(int surah, int ayah, [int? page, bool strictPage = false]) {
    if (surah < 1 || surah > 114) return false;
    if (ayah < 1 || ayah > quran.getVerseCount(surah)) return false;
    if (page != null) {
      if (page < 1 || page > 604) return false;
      if (strictPage && page != quran.getPageNumber(surah, ayah)) return false;
    }
    return true;
  }

  static bool isPageConsistent(int surah, int ayah, int page) {
    return isValidCoordinates(surah, ayah, page, true);
  }

  factory Bookmark.fromJson(Map<String, dynamic> json, {bool strict = false}) {
    final s = json['surah'];
    final a = json['ayah'];
    if (s is! int || a is! int) {
      throw const FormatException('Invalid or missing surah/ayah number');
    }
    if (!isValidCoordinates(s, a)) {
      throw FormatException('Coordinates out of range: surah $s, ayah $a');
    }

    final rawPage = json['page'];
    final expectedPage = quran.getPageNumber(s, a);
    final int pageNumber;
    if (rawPage != null) {
      if (rawPage is! int || rawPage < 1 || rawPage > 604) {
        throw FormatException('Page out of range: $rawPage');
      }
      if (strict && rawPage != expectedPage) {
        throw FormatException(
          'Page $rawPage does not match Quran coordinate ($s:$a expected $expectedPage)',
        );
      }
      pageNumber = rawPage;
    } else {
      pageNumber = expectedPage;
    }

    final rawNote = json['note'];
    String? note;
    if (rawNote != null) {
      if (rawNote is! String) {
        throw const FormatException('Note must be a string');
      }
      if (rawNote.length > AppPolicy.maxBookmarkNoteLength) {
        throw FormatException(
          'Note length (${rawNote.length}) exceeds maximum allowed (${AppPolicy.maxBookmarkNoteLength})',
        );
      }
      note = rawNote;
    }

    DateTime timestamp = DateTime.now();
    final rawTimestamp = json['timestamp'];
    if (rawTimestamp != null) {
      if (rawTimestamp is! String) {
        throw const FormatException('Timestamp must be an ISO8601 string');
      }
      final parsed = DateTime.tryParse(rawTimestamp);
      if (parsed == null) {
        throw const FormatException('Invalid timestamp format');
      }
      if (strict && parsed.isAfter(DateTime.now().add(const Duration(days: 1)))) {
        throw const FormatException('Timestamp cannot be in the future');
      }
      timestamp = parsed;
    }

    final rawIsSurah = json['isSurah'];
    if (rawIsSurah != null && rawIsSurah is! bool) {
      throw const FormatException('isSurah must be a boolean');
    }
    final isSurah = rawIsSurah as bool? ?? false;

    return Bookmark(
      surah: s,
      ayah: a,
      page: pageNumber,
      note: note,
      timestamp: timestamp,
      isSurah: isSurah,
    );
  }

  Map<String, dynamic> toJson() => {
        'surah': surah,
        'ayah': ayah,
        'page': page,
        'note': note,
        'timestamp': timestamp.toIso8601String(),
        'isSurah': isSurah,
      };
}

class LastRead {
  final int surah;
  final int ayah;
  final int page;
  final DateTime timestamp;

  const LastRead({
    required this.surah,
    required this.ayah,
    required this.page,
    required this.timestamp,
  });

  factory LastRead.fromJson(Map<String, dynamic> json, {bool strict = false}) {
    final s = json['surah'];
    final a = json['ayah'];
    if (s is! int || a is! int) {
      throw const FormatException('Invalid or missing surah/ayah number');
    }
    if (!Bookmark.isValidCoordinates(s, a)) {
      throw FormatException('Coordinates out of range: surah $s, ayah $a');
    }

    final rawPage = json['page'];
    final expectedPage = quran.getPageNumber(s, a);
    final int pageNumber;
    if (rawPage != null) {
      if (rawPage is! int || rawPage < 1 || rawPage > 604) {
        throw FormatException('Page out of range: $rawPage');
      }
      if (strict && rawPage != expectedPage) {
        throw FormatException(
          'Page $rawPage does not match Quran coordinate ($s:$a expected $expectedPage)',
        );
      }
      pageNumber = rawPage;
    } else {
      pageNumber = expectedPage;
    }

    DateTime timestamp = DateTime.now();
    final rawTimestamp = json['timestamp'];
    if (rawTimestamp != null) {
      if (rawTimestamp is! String) {
        throw const FormatException('Timestamp must be an ISO8601 string');
      }
      final parsed = DateTime.tryParse(rawTimestamp);
      if (parsed == null) {
        throw const FormatException('Invalid timestamp format');
      }
      if (strict && parsed.isAfter(DateTime.now().add(const Duration(days: 1)))) {
        throw const FormatException('Timestamp cannot be in the future');
      }
      timestamp = parsed;
    }

    return LastRead(
      surah: s,
      ayah: a,
      page: pageNumber,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'surah': surah,
        'ayah': ayah,
        'page': page,
        'timestamp': timestamp.toIso8601String(),
      };
}

class MergeResult {
  final int addedCount;
  final int updatedCount;
  final int skippedCount;

  const MergeResult({
    required this.addedCount,
    required this.updatedCount,
    required this.skippedCount,
  });
}
