/// System-wide policy tokens for timeouts, intervals, polling rates, and retention budgets.
///
/// Centralized in theme layer to comply with tokenization rules and decouple
/// non-UI services from widget animation tokens (AppMotion).
class AppPolicy {
  const AppPolicy._();

  // Network & Async Timeouts
  static const Duration networkFast = Duration(seconds: 3);
  static const Duration networkTimeout = Duration(seconds: 15);
  static const Duration networkMedium = Duration(seconds: 20);
  static const Duration networkLong = Duration(seconds: 30);
  static const Duration networkRetry = Duration(seconds: 10);
  static const Duration microPause = Duration(milliseconds: 50);
  static const Duration debounce = Duration(milliseconds: 500);
  static const Duration seekStep = Duration(seconds: 5);

  // Periodic Intervals & Polling
  static const Duration oneSecond = Duration(seconds: 1);
  static const Duration pollingActive = Duration(seconds: 10);
  static const Duration pollingStandard = Duration(seconds: 30);
  static const Duration compassFallback = Duration(milliseconds: 600);
  static const Duration sensorCheck = Duration(milliseconds: 2500);
  static const Duration locationQuick = Duration(seconds: 6);
  static const Duration locationBackground = Duration(seconds: 5);

  // Storage & Cache Retention Budgets
  static const int maxStoredReadingSessions = 500;
  static const int maxReadingSessionAgeDays = 90;
  static const int maxCachedDownloadedBooks = 1000;

  // Backup & Import Budgets (C29)
  static const int maxBackupFileBytes = 512 * 1024; // 512 KB
  static const int maxBackupBookmarks = 200;
  static const int maxBookmarkNoteLength = 2000;

  // Network & Geocode Payload Budgets (C32)
  static const int maxGeocodeBytes = 64 * 1024; // 64 KB

  // Shamela Remote Fetching Budgets (R78)
  static const int maxShamelaPageBytes = 512 * 1024; // 512 KB raw page limit
  static const int maxShamelaTocCoverBytes = 1024 * 1024; // 1 MB raw cover limit
  static const int maxShamelaTocChildBytes = 256 * 1024; // 256 KB raw child limit
  static const int maxShamelaTocNodes = 50; // Maximum expandable child nodes to process
  static const int maxShamelaConcurrentRequests = 4; // Max concurrent HTTP requests

  // Quran Remote Fetching & Cache Budgets (R80)
  static const int maxTafsirResponseBytes = 256 * 1024; // 256 KB raw response ceiling
  static const int maxWordMeaningResponseBytes = 128 * 1024; // 128 KB raw response ceiling
  static const int maxTafsirMemoryEntries = 200; // In-memory Tafsir RAM entries
  static const int maxWordMeaningMemoryEntries = 100; // In-memory WordMeanings RAM entries
}
