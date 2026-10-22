import 'package:talib_ilm/app/constants/app_strings.dart';

/// Represents a distinct chapter or section topic within a scholarly lecture.
class LessonChapter {
  final String title;
  final int startSeconds;
  final int? endSeconds;

  const LessonChapter({
    required this.title,
    required this.startSeconds,
    this.endSeconds,
  });

  /// Formatted timestamp string like "06:18" or "01:04:45"
  String get timestampFormatted {
    final m = startSeconds ~/ 60;
    final s = startSeconds % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final remM = m % 60;
      return '${h.toString().padLeft(2, '0')}:${remM.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

/// Represents a curriculum video or audio lesson.
class Lesson {
  final int index;
  final String title;
  final String videoId;
  final int durationMinutes;
  final String? scholar;
  final String? playlistId;
  final String? url;
  final int? startSeconds;
  final int? endSeconds;
  final List<LessonChapter>? chapters;

  const Lesson({
    required this.index,
    required this.title,
    required this.videoId,
    required this.durationMinutes,
    this.scholar,
    this.playlistId,
    this.url,
    this.startSeconds,
    this.endSeconds,
    this.chapters,
  });

  /// True if this lesson represents a specific segment of a longer lecture
  bool get isSegment => startSeconds != null;

  /// Duration string for display (e.g. "19 دقيقة")
  String get formattedDuration => '$durationMinutes دقيقة';

  /// Readable time range like "من 00:00 إلى 18:54"
  String? get formattedTimeRange {
    if (startSeconds == null) return null;
    final startStr = _formatSeconds(startSeconds!);
    final endStr = endSeconds != null ? _formatSeconds(endSeconds!) : null;
    if (endStr != null) {
      return 'من $startStr إلى $endStr';
    }
    return 'يبدأ من $startStr';
  }

  static String _formatSeconds(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final remM = m % 60;
      return '${h.toString().padLeft(2, '0')}:${remM.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// TEMP generator until API / real data
  static List<Lesson> generateFromPlaylist(
    String playlistId, {
    required int count,
  }) {
    return List.generate(
      count,
      (i) => Lesson(
        index: i,
        title: AppStrings.lessonTitle(i),
        videoId: playlistId, // TEMP (same video)
        durationMinutes: 15 + (i % 5) * 5,
      ),
    );
  }
}
