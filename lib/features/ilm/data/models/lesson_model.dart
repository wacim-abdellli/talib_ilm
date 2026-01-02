class Lesson {
  final int index;
  final String title;
  final String videoId;
  final int durationMinutes;

  Lesson({
    required this.index,
    required this.title,
    required this.videoId,
    required this.durationMinutes,
  });

  /// TEMP generator until API / real data
  static List<Lesson> generateFromPlaylist(
    String playlistId, {
    required int count,
  }) {
    return List.generate(
      count,
      (i) => Lesson(
        index: i,
        title: 'الدرس ${i + 1}',
        videoId: playlistId, // TEMP (same video)
        durationMinutes: 15 + (i % 5) * 5,
      ),
    );
  }
}
