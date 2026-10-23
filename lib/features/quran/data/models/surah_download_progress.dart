enum SurahDownloadStatus {
  idle,
  downloading,
  paused,
  completed,
  failed,
}

class SurahDownloadProgress {
  final int surah;
  final String reciterId;
  final int downloadedAyahs;
  final int totalAyahs;
  final int downloadedBytes;
  final SurahDownloadStatus status;
  final String? errorMessage;

  const SurahDownloadProgress({
    required this.surah,
    required this.reciterId,
    required this.downloadedAyahs,
    required this.totalAyahs,
    required this.downloadedBytes,
    required this.status,
    this.errorMessage,
  });

  double get progressFraction =>
      totalAyahs > 0 ? (downloadedAyahs / totalAyahs).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => status == SurahDownloadStatus.completed;
  bool get isDownloading => status == SurahDownloadStatus.downloading;
  bool get isPaused => status == SurahDownloadStatus.paused;
}
